# Quran Academy

Quran Academy (أكاديمية القرآن) is a production-oriented management platform for Quran academies. The application is Arabic-first, right-to-left, responsive, and designed to give academy teams a clear operational workspace.

## Notification providers

Provider-backed notifications use Resend for email and the official Meta WhatsApp Cloud API over HTTPS. Configure
`RESEND_API_KEY`, `MAILER_SENDER`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, and
`WHATSAPP_BUSINESS_ACCOUNT_ID` in the deployment environment and never commit their values. The academy Email and
WhatsApp notification switches must also be enabled. No job is enqueued and no external schedule is installed
automatically. Meta may require an approved WhatsApp template when a
business-initiated message is outside the customer-service conversation window.

### Future reminder scheduling

The application exposes thin ActiveJob adapters and does not install or execute an external scheduler. Configure cron,
a Render Cron Job, or a future Solid Queue recurring schedule to enqueue both sweep jobs once per minute. Set
`NOTIFICATION_ACTOR_ID` to an active administrator used as the audit actor, then invoke:

```bash
bin/rails runner 'actor = User.find(ENV.fetch("NOTIFICATION_ACTOR_ID")); ReminderSweepJob.perform_later(actor:); LateReminderSweepJob.perform_later(actor:)'
```

The jobs contain no reminder business logic. They call the idempotent reminder services, so overlapping scheduler
invocations cannot create duplicate notifications for the same lesson, recipient, and reminder stage.

## Planned capabilities

- Student self-registration and guardian records
- Teacher and staff management
- Quran programs and lesson scheduling
- Attendance tracking
- WhatsApp reminder buttons
- Lesson reports
- Teacher payroll
- Academy reporting

## Current status

**Project foundation.** This branch establishes the Rails application, PostgreSQL configuration, development tooling, authentication foundation, localization, automated tests, and the placeholder dashboard. Business models and workflows are intentionally deferred.

## Architecture Vision

Quran Academy is being built as a modular academy management platform. Planned modules include Students, Guardians, Teachers, Scheduling, Attendance, WhatsApp reminders, Lesson reports, Payroll, and Reports.

The current stage focuses exclusively on establishing a solid, secure, and maintainable technical foundation before any business modules are implemented.

## Design system

Reusable interface partials live in `app/views/shared/components`, with shared class and icon APIs in `app/helpers/application_helper.rb`. Render components through their locals-based APIs, for example:

```erb
<%= render "shared/components/button",
           label: t("actions.save"),
           variant: :primary,
           icon: :check %>
```

Semantic colors, typography, spacing, radius, shadow, control height, and page-width tokens are defined as CSS variables in `app/assets/tailwind/application.css`. Components consume those tokens through Tailwind utilities instead of embedding product colors repeatedly.

The application layout derives `lang` and `dir` from `I18n.locale`. Components use logical positioning and spacing utilities so Arabic renders RTL and English renders LTR without separate templates.

In development and test, the live component showcase is available at:

```text
http://localhost:3000/ui
```

Use `/ui?locale=en` to inspect the English LTR version. The route is intentionally absent in production. Business modules remain intentionally unimplemented at this stage.

## Authentication and accounts

Authentication uses Devise with `database_authenticatable`, `recoverable`, `rememberable`, `validatable`, `trackable`, and `timeoutable`. Sessions expire after 45 minutes of inactivity. Public registration, profile editing, account cancellation, third-party authentication, and email confirmation are not enabled.

The initial roles are `admin`, `staff`, `teacher`, and `student`. Account statuses are `pending`, `active`, `suspended`, and `disabled`; only active accounts may sign in. These roles currently control navigation presentation only. Resource permissions and authorization policies are intentionally deferred.

Each account stores a preferred locale and ActiveSupport-compatible time zone. Student accounts default to English, other roles default to Arabic, and all accounts default to Cairo time unless explicitly configured. Locale and time zone are safely scoped to each authenticated request.

Create the first administrator using environment variables:

```bash
ADMIN_EMAIL=admin@example.test \
ADMIN_PASSWORD='use-a-secure-value' \
ADMIN_FIRST_NAME=Foundation \
ADMIN_LAST_NAME=Administrator \
bin/rails users:create_admin
```

The task creates an active Arabic administrator in the Cairo time zone, refuses to modify an existing email, and never prints the password. Do not store bootstrap credentials in source control.

Password-reset delivery is provider-neutral. Reset URLs use `APP_HOST`, optional `APP_PORT`, and `DEFAULT_URL_OPTIONS_PROTOCOL`; production must supply the correct public host and protocol before email delivery is enabled. `MAILER_SENDER` controls the sender address.

### Production email with Resend on Render

Production invitation email uses the official Resend Ruby SDK over its HTTPS REST API. ActionMailer
continues to render the existing localized HTML and text templates; Resend supplies only the
transport. Add these variables to the Render web service and never commit their real values:

```text
APP_HOST=quran-academy-igl2.onrender.com
DEFAULT_URL_OPTIONS_PROTOCOL=https
MAILER_SENDER=your-verified-sender@example.com
RESEND_API_KEY=your-resend-api-key
```

`APP_HOST` is a hostname only: do not include `https://` or a path. `RESEND_API_KEY`,
`MAILER_SENDER`, and `APP_HOST` are required at production boot. During development and tests,
the sender defaults to `onboarding@resend.dev` when `MAILER_SENDER` is absent. For production,
use `onboarding@resend.dev` only while operating within Resend's testing restrictions; use an
address on a verified domain for normal recipient delivery.

After Render restarts successfully with those variables, open Render Shell and send a real
invitation-template delivery test to an address you control:

```bash
EMAIL=test@example.com bin/rails mailers:test_invitation
```

Optionally set `LOCALE=ar` for an Arabic message. The task creates no permanent user or invitation,
does not print the API key, and reports only that Resend accepted the message. Replace the example
recipient on the command line; never store it in source control.

For authentication errors, verify that `RESEND_API_KEY` is current and belongs to the intended
Resend account. For sender or validation errors, verify `MAILER_SENDER` against Resend's domain and
testing-mode rules. For timeouts, confirm that the Render service can make outbound HTTPS requests
to Resend. Invitation creation remains committed if delivery fails; the invitation stays pending
and can be resent after configuration is corrected.

Academy business modules remain intentionally out of scope.

## User administration

Active administrators manage controlled accounts at `/admin/users`. The area supports search,
allowlisted sorting, role/status/language filters, pagination, account creation, identity and
preference editing, pending-account approval, explicit status transitions, role assignment,
and administrative password resets. Public registration remains disabled.

Status changes use explicit transitions: pending accounts may be approved or disabled; active
accounts may be suspended or disabled; suspended accounts may be reactivated or disabled; and
disabled accounts may be enabled. Normal editing cannot bypass these transitions.

Server-side protections prevent administrators from demoting or blocking themselves and
prevent removal of the last active administrator. Sensitive operations lock administrator
rows within a transaction. Application-level row locking is strong practical protection but
does not replace operational database controls in every distributed failure scenario.

Accounts are never hard-deleted. Disabling preserves authentication and administrative
history. Administrative password resets never record the password and increment the target
account's session version. Suspension and disabling also increment that version, so only that
user's existing sessions are rejected on their next authenticated request.

`UserAccountEvent` records creation, meaningful updates, approval, status changes, role
changes, and password resets with safe JSON metadata. It is intentionally account-specific,
not a general auditing or granular permissions framework. Teacher, student, staff, and
guardian profile models remain intentionally unimplemented.

## Academy settings

The application uses one fixed-key `AcademySetting` record for the current academy. The
database enforces the `current` singleton key and a unique index; `AcademySetting.current`
creates valid defaults idempotently and safely retries a concurrent unique-key race. The
same operation is available explicitly through:

```bash
bin/rails academy_settings:ensure
```

Active administrators manage the singular record at `/admin/settings`. It contains academy
identity and optional contact details, interface and teaching languages, default time zone,
working days and operating hours, lesson-duration boundaries, booking and cancellation
defaults, attendance thresholds, and future communication, payroll, and billing preferences.

User locale and time-zone preferences remain the first authenticated fallback. Academy
defaults are used when no user preference is available, followed by the Rails Arabic/Cairo
defaults. Time-only operating hours are stored without time-zone conversion.

Communication channel flags indicate readiness preferences only. No email, WhatsApp, or SMS
provider is configured and no messages or jobs are created. Payroll rates and lesson prices
are decimal defaults only; no payroll, invoice, subscription, charge, or payment calculation
exists.

Meaningful updates atomically record the acting administrator and an `AcademySettingEvent`
containing only changed safe fields. No-op and failed updates create no event. Multi-tenancy,
academy switching, provider secrets, and all academy business modules remain intentionally
out of scope.

## Teacher profiles

Teacher-specific professional information lives in `TeacherProfile`, a one-to-one extension
of a teacher-role `User`. Authentication identity therefore remains separate from teaching
qualifications, capabilities, contact information, and operational defaults. Administrators
initialize profiles explicitly; assigning the teacher role alone does not create one.

Each profile receives an immutable, server-generated public identifier such as
`TCH-7H3PK9M2QX`, protected by a unique database index. Account status, employment status (`candidate`, `active`, `on_leave`,
`inactive`, `departed`), and profile status (`draft`, `complete`, `verified`, `archived`) are
distinct. Archived profiles and their audit history are retained and can be restored; the UI
provides no hard-delete action. A teacher with a profile cannot be moved to another user role
until the profile lifecycle is deliberately resolved.

Teaching languages use stable codes constrained by the academy configuration. Student age
groups and teaching specializations use controlled, extensible catalogs. Compensation rate,
currency, and unit are future defaults only—no payroll calculation, payment, invoice, or
financial transaction is implemented. New profiles copy the current academy defaults;
existing stored profile values do not change when academy defaults later change.

Active administrators manage profiles, lifecycle actions, compensation, internal notes, and
audit history under `/admin/teachers`. Active teachers can view their own profile and edit a
restricted set of personal and professional fields under `/teacher/profile`. Compensation,
internal notes, employment, verification, ownership, and public IDs are excluded from that
self-service boundary. Teachers without a profile receive a safe onboarding state.

`TeacherProfileEvent` records transactional creation, meaningful updates, self-service
changes, verification, archival, and restoration with recursively validated safe
before/after metadata. Schedules, recurring availability, lessons, attendance, student
assignments, payroll entries, payments, public directories, uploads, and performance reports
remain out of scope.

## Student and guardian profiles

Authentication identities remain in `User`; student demographic, contact, learning, and
safeguarding data lives in a one-to-one `StudentProfile`. Administrators explicitly create
profiles for existing student-role accounts. Profiles use immutable public IDs and protect
their owning user from an invalid role change.

Guardians are deliberately non-authenticated domain records: there is no guardian role,
login, invitation, or portal. `StudentGuardianship` provides many-to-many relationships with
relationship type, one transactional active primary contact per student, emergency/legal/
academic authority flags, communication-readiness flags, and effective dates. Adults may
have no guardian; verified minors require a usable active guardian, exactly one primary
contact, emergency coverage, and legal or academic authority.

Account status, profile status, learning status, guardian status, and relationship status
remain separate. Completeness and age are derived. Sensitive medical, safeguarding,
learning-needs, emergency, and internal fields are administrator-only; audit history stores
masked change markers instead of duplicating their contents. Students can edit only their
own safe contact and learning-preference fields. Profiles, guardians, and relationships are
archived or ended rather than hard-deleted.

Programs, courses, enrollment, teacher assignment, scheduling, lessons, attendance, billing,
payments, communications, uploads, background jobs, and guardian authentication remain out
of scope.

## Technology stack

- Ruby 3.4.6
- Ruby on Rails 8.1.3
- PostgreSQL 16
- Hotwire: Turbo 2.0 and Stimulus 1.3
- Importmap
- Tailwind CSS 4
- Devise 5
- Pagy 43
- RSpec 8, FactoryBot, and Faker
- RuboCop and Brakeman

## Requirements

- Ruby 3.4.6 (see `.ruby-version`)
- Bundler 4.0 or a compatible version
- PostgreSQL 16 or a compatible supported version
- Node.js is not required for the Importmap/Tailwind runtime. Node.js 20 and Yarn 1 were available during initial setup but are not used by the asset build.

## Local setup

1. Clone the repository and switch to a feature branch created from `dev`.
2. Copy the environment template and adjust credentials for your local PostgreSQL installation:

   ```bash
   cp .env.example .env
   ```

3. Prepare the application without starting the server:

   ```bash
   bin/setup --skip-server
   ```

The setup script installs missing gems, prepares the database without resetting existing data, and clears temporary files.

To run database commands individually:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:test:prepare
```

## Environment variables

Safe placeholders are documented in [`.env.example`](.env.example). Local `.env` files and secrets are ignored by Git. Database credentials must not be committed.

## Running the application

```bash
bin/dev
```

Open <http://localhost:3000>. The default locale is Arabic and the application time zone is Cairo; database timestamps remain UTC.

## Local demo data

Load a complete, fictional development dataset with:

```bash
DEMO_DATA=true bin/rails db:prepare
DEMO_DATA=true bin/rails db:seed
```

The dataset includes administrator, staff, teacher, and student accounts plus profiles,
guardians, programs, offerings, enrollments, schedules, attendance, lesson reports,
assessments, progress, an exam, a certificate, payrolls, invitations, and notification
history. Running the seed again is safe and does not duplicate the dataset. External email
and WhatsApp delivery is disabled while it loads, and the seed refuses to run in production.

All demo accounts use the password `DemoPass123!`. Useful accounts are:

- `admin@demo.quran-academy.test`
- `staff@demo.quran-academy.test`
- `teacher1@demo.quran-academy.test` through `teacher3@demo.quran-academy.test`
- `student1@demo.quran-academy.test` through `student10@demo.quran-academy.test`

## Running tests

```bash
bundle exec rspec
```

## Code quality and security

```bash
bundle exec rubocop
bin/brakeman
```

## Branch workflow

```text
feature branches → dev → main
```

- `main` is the stable production branch.
- `dev` is the integration branch.
- Feature branches are created from `dev` and merged back through review.

## Programs, course offerings, and enrollment

The academic catalog separates reusable academic definitions (`Program`) from operational
enrollment containers (`CourseOffering`). An `Enrollment` connects one `StudentProfile` to
one offering and stores its own placement and starting-level snapshot. Program defaults
initialize new offerings; later program changes never silently rewrite existing offerings.

Programs use draft, active, inactive, and archived lifecycle states. Offerings use explicit
draft, open, closed, in-progress, completed, cancelled, and archived transitions. Records are
archived rather than hard-deleted so offering and enrollment history remains intact.

Enrollment status is independent of the student profile, user account, and offering status.
Lifecycle changes use transactional services and audit events. Approved, active, and paused
enrollments consume configured offering capacity; pending and waitlisted records do not.
Approval locks the offering and recalculates capacity from persisted records.

Adult students can be approved without guardians. Minor approval requires the existing
student-profile guardian-readiness rules. Placement-required offerings require completed or
explicitly waived placement before activation. Placement data and student goals are snapshots,
not assessment or progress-tracking systems.

Administrators manage the catalog and enrollments under `/admin`. Students can view only their
own enrollment summaries and cannot self-enroll. Internal administrative notes and audit
metadata are never exposed on student pages. Teachers and staff receive no catalog-management
access in this foundation.

This stage intentionally does not implement teacher assignment, availability, scheduling,
lessons, attendance, assessments, progress tracking, payroll, billing, invoices, payments,
communications, providers, or background jobs. A transfer action currently records the
terminal transferred state; creating and linking a target enrollment is deliberately deferred.

## Teacher availability and scheduling

Task 09 adds recurring teacher availability, date-specific exceptions, scheduled lessons, and
soft lesson participation records. Recurring windows and exceptions retain local wall-clock
times with explicit time zones; scheduled lesson timestamps are stored as UTC-capable Rails
timestamps and snapshot the academy time zone used during scheduling.

Scheduling uses explicit services for availability calculation, overlap detection, lifecycle
transitions, rescheduling, cancellation, and participant changes. Teacher and student conflicts
are checked transactionally before a draft becomes scheduled. Lesson history is preserved through
immutable audit events and optimistic locking. Staff have read-only schedule access, administrators
manage scheduling, teachers manage only their own availability and view their schedule, and
students view only their own linked lessons.

Attendance, reminders, payroll, billing, providers, calendar synchronization, recurring lesson
generation, room inventory, and leave approval workflows remain intentionally out of scope.
