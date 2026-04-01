# Automation Spec: Lead Scoring & Routing

## Trigger
Webhook (POST) receives new lead data with fields:
- `company_name` (string) — name of the lead's company
- `contact_name` (string) — name of the contact
- `contact_email` (string) — contact's email address
- `company_size` (number) — number of employees
- `industry` (string) — industry vertical (e.g., "tech", "finance", "healthcare")

## Steps
1. **Webhook** — Receives incoming lead via HTTP POST
2. **Score Lead** (Code node) — Calculates a lead score using JavaScript:
   - Base score: 30
   - Industry is "tech": +20 points
   - Company size > 500: +30 points
   - Company size > 100 (but <= 500): +20 points
   - Maximum possible score: 80 (tech + large company)
3. **Is Enterprise?** (IF node) — Routes based on lead score:
   - Score >= 70 goes to the enterprise branch
   - Score < 70 goes to the SMB branch
4. **Notify Enterprise** (Set node, simulates Slack #sales-enterprise) — Builds a notification payload for the enterprise sales channel
5. **Notify SMB** (Set node, simulates Slack #sales-smb) — Builds a notification payload for the SMB sales channel

## Data Flow
```
Webhook body (company_name, contact_name, contact_email, company_size, industry)
  --> Code node calculates lead_score, passes all fields through
  --> IF node checks lead_score >= 70
  --> [true]  Set node: slack_channel="#sales-enterprise", formatted message, status="sent"
  --> [false] Set node: slack_channel="#sales-smb", formatted message, status="sent"
```

## Edge Cases
- If `company_size` is missing or not a number, the Code node defaults it to 0 (base score only)
- If `industry` is missing, no industry bonus is applied
- Leads exactly at score 70 are routed to enterprise

## Production Notes
- The "Notify Enterprise" and "Notify SMB" Set nodes simulate Slack notifications. In production, replace these with `n8n-nodes-base.slack` nodes configured with real Slack OAuth credentials and the appropriate channel IDs.
