# Quran Academy

Quran Academy (أكاديمية القرآن) is a production-oriented management platform for Quran academies. The application is Arabic-first, right-to-left, responsive, and designed to give academy teams a clear operational workspace.

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
