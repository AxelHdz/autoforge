# Automation Spec: GitHub Bug Label to Slack Notification

## Trigger
A webhook receives GitHub's `issues` event with `action: "labeled"`. The payload includes:
- `action` — the event action (we care about `"labeled"`)
- `label.name` — the label that was just applied
- `issue.title` — the issue title
- `issue.user.login` — the GitHub username who opened the issue
- `issue.html_url` — direct link to the issue on GitHub

## Steps
1. **Receive GitHub Webhook** — Accept the incoming POST from GitHub's issue label event.
2. **Check Label is Bug** — IF `label.name` equals `"bug"`, continue to notification. Otherwise, ignore the event.
3. **Post to Slack #engineering** (true branch) — Format and send a message containing issue title, reporter username, label name, and issue URL.
4. **Ignore Event** (false branch) — Return a status indicating the event was skipped because the label was not "bug".

## Data Flow
```
GitHub webhook payload
  -> body.label.name checked against "bug"
  -> (true)  -> Slack message: "Bug Report: {title} | Reported by: {user} | Label: {label} | {url}"
  -> (false) -> { status: "ignored", reason: "Label is not bug" }
```

## Edge Cases
- If the label is anything other than "bug", the event is silently ignored (no Slack post).
- The workflow returns a response to the webhook caller in all cases (lastNode response mode).

## Production Notes
- The "Send Slack Notification" node is a **Set node simulation**. In production, replace it with an `n8n-nodes-base.slack` node configured with real Slack OAuth credentials, targeting channel `#engineering`.
- The "Ignore Event" node is also a Set node that returns a skip status for observability.
