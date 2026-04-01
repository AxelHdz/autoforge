# Automation Spec: Customer Onboarding Pipeline

## Trigger
Webhook receives a POST request when a new customer signs up, with these fields:
- `customer_name` (string) — full name of the new customer
- `customer_email` (string) — customer's email address
- `plan_type` (string) — one of "starter", "pro", or "enterprise"
- `company_name` (string) — customer's company name

## Steps
1. **Send Welcome Email** — Compose a welcome email with the customer's name, a subject line, and a body message. Outputs: `email_to`, `email_subject`, `email_body`, `status`.
2. **Create Onboarding Task** — Create a task in the project management tool with a title, assignee, due date (7 days from now), and description. Outputs: `task_title`, `task_assignee`, `task_due_date`, `task_description`.
3. **Schedule Check-In Reminder** — Schedule a 14-day follow-up reminder for the customer. Outputs: `reminder_date` (14 days from now), `reminder_type`, `reminder_for`.
4. **Is Enterprise?** — Check if `plan_type` equals "enterprise".
5. **Notify Account Team** (enterprise only) — Post a message to `#account-management` in Slack with the customer's details. Outputs: `slack_channel`, `slack_message`.
6. **Complete Without Notification** (non-enterprise) — Mark the onboarding as complete with no additional notification. Outputs: `status`, `message`.

## Data Flow
```
Webhook (customer_name, customer_email, plan_type, company_name)
  -> Send Welcome Email (email fields + passthrough of customer fields)
  -> Create Onboarding Task (task fields + passthrough of customer fields)
  -> Schedule Check-In Reminder (reminder fields + passthrough of customer fields)
  -> IF plan_type == "enterprise"
       TRUE  -> Notify Account Team (slack_channel, slack_message)
       FALSE -> Complete Without Notification (status, message)
```

## Edge Cases
- If `plan_type` is missing or not "enterprise", the flow takes the false branch (no Slack notification).
- All service integrations are simulated with Set nodes for demo purposes. No real credentials are required.

## Production Notes
In a production deployment, the following Set nodes would be replaced with real service nodes:
- **Send Welcome Email** -> Email service node (SendGrid, Mailgun, or SMTP)
- **Create Onboarding Task** -> Project management node (Asana, Jira, or Linear)
- **Schedule Check-In Reminder** -> Scheduling node (Google Calendar, or a delayed trigger)
- **Notify Account Team** -> Slack node (`n8n-nodes-base.slack`) with real OAuth credentials
