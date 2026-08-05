# Student and teacher one-step onboarding

This patch changes only the **new student** and **new teacher** workflows. Existing edit/show workflows and all existing fields remain available.

## Student workflow

The administrator can create, in one submission:

- the student's login user and invitation;
- the student profile and automatic public student code;
- status, country, level, wallet balance, discount and study language;
- responsible teacher, course offering and fee-plan label;
- lesson count, duration, weekly frequency, individual/group type and trial date;
- up to three weekly day/time slots, stored as structured JSON and summarized on enrollment;
- weekly price and currency;
- a new guardian or an existing guardian link;
- an optional existing sibling link;
- email/phone/WhatsApp and account-delivery preferences.

The service runs the account/profile/guardian/enrollment creation in one database transaction. Notification delivery keeps using the existing invitation/notification architecture.

## Teacher workflow

The administrator can create, in one submission:

- the teacher login user and invitation;
- contact and message preferences;
- status, utilization percentage and leave flag;
- working days and start/end hours;
- teacher availability records for all selected days;
- compensation method, lesson rate, monthly salary, currency and previous-dues flag.

## Deployment

Run:

```bash
bin/rails db:migrate
```

No new environment variables are introduced by these onboarding forms. WhatsApp variables remain those required by the existing notification integration.
