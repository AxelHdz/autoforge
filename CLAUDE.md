# Autoforge

A conversational automation builder that lives inside Claude Code. Describe an automation in natural language, and autoforge will refine your idea through conversation, research the relevant APIs, generate a valid n8n workflow, deploy it to a local n8n instance, and self-correct if it fails.

## Architecture

Two-agent system orchestrated by a Claude Code skill:

- `.claude/agents/orchestrator.md` — Conversation + API research + n8n JSON generation
- `.claude/agents/deployer.md` — n8n Docker deploy + test execution + error feedback loop
- `.claude/commands/autoforge.md` — Entry point: `/autoforge <description>`

## How to Run

```
# Start n8n
docker compose up -d

# Create API key in n8n UI (http://localhost:5678 → Settings → API)
# Save it to .env as N8N_API_KEY=<key>

# Run autoforge
/autoforge "When a form submission comes in, check if company size > 100, notify Slack for enterprise leads, add others to nurture list"
```

## Key Files

- `references/example-workflow-*.json` — 3 validated reference workflows (few-shot examples)
- `docker-compose.yml` — n8n 1.85.4 local instance
- `verify.sh` — Validate generated workflow JSON structure
- `output/<timestamp>/` — Per-run outputs (spec.md, workflow.json)

## n8n API Notes

- Auth: `X-N8N-API-KEY` header
- Create: `POST /api/v1/workflows`
- Activate: `POST /api/v1/workflows/{id}/activate`
- Test: `POST /webhook/{path}` (webhook trigger required, manualTrigger can't be activated)
- Credential-dependent nodes (Slack, GitHub) require real n8n credentials or must be simulated with Set nodes
- Parse API responses with `grep` or `python3 strict=False` (responses contain raw newlines)

## Supported Node Types

webhook, manualTrigger, set, if, httpRequest, code, slack, github

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.

Key routing rules:
- Build an automation, describe a workflow → invoke autoforge
- Bugs, errors, "why is this broken" → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- Code review, check my diff → invoke review
