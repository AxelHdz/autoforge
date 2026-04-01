# Autoforge

An AI agent that builds automations through conversation, not configuration.

Describe what you want automated in plain English. Autoforge asks clarifying questions, researches the relevant APIs, generates a working n8n workflow, deploys it to a local instance, tests it, and self-corrects if something breaks.

Built with Claude Code Agent Teams. No web UI. The entire system is agent prompts, a Claude Code skill, and a small validation script.

## How It Works

```
you:  /autoforge "When a form comes in, route enterprise leads to Slack
       and add small companies to a nurture list"

agent: I'll build that. A few questions:
       1. What fields does the form include?
       2. What threshold defines "enterprise"?
       3. What should the Slack message contain?

you:   company_name, email, company_size. Enterprise = 100+.
       Include company name, contact, and size in Slack.

agent: ✓ Spec written to output/20260401-144013/spec.md
       ✓ Workflow generated: 5 nodes (Webhook → Extract → IF → Slack/Nurture)
       ✓ Deployed to n8n and tested
       ✓ Enterprise lead (size=500) → routed to #enterprise-leads
       ✓ Small company (size=25) → status: nurture, follow-up in 14 days
```

## Architecture

```
/autoforge "describe your automation"
    │
    ▼
┌─────────────────────────────────────┐
│  Orchestrator Agent                 │
│  • Parses intent (trigger + actions)│
│  • Asks 2-4 clarifying questions    │
│  • Researches APIs (chub/web/model) │
│  • Generates spec.md + workflow.json│
│  • Validates JSON before handoff    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Deployer Agent                     │
│  • Pre-flight checks (Docker, n8n)  │
│  • Imports workflow via n8n REST API│
│  • Activates and triggers test      │
│  • Classifies errors (fix vs stop)  │
│  • Feeds errors back to orchestrator│
└─────────────────────────────────────┘
               │
          ┌────┴────┐
          ▼         ▼
      SUCCESS    FAILURE
    (report)   (retry up to 3x)
```

Two agents, zero Python. The orchestrator handles the thinking (conversation, API research, workflow generation). The deployer handles the infrastructure (n8n API, testing, error feedback). They coordinate through the filesystem and inter-agent messaging.

## Quick Start

```bash
# 1. Start n8n
docker compose up -d

# 2. Create API key
#    Open http://localhost:5678
#    Create owner account → Settings → API → Create API Key

# 3. Save API key
echo "N8N_API_KEY=<your-key>" > .env

# 4. Run autoforge (inside Claude Code)
/autoforge "When a GitHub issue gets labeled 'bug', post to Slack #engineering"
```

## What Gets Generated

Each run creates a timestamped directory in `output/`:

```
output/20260401-144013/
├── spec.md          # Human-readable automation spec
└── workflow.json    # Valid, importable n8n workflow JSON
```

The `spec.md` documents what the automation does, the data flow, and edge cases. The `workflow.json` can be imported directly into any n8n instance.

## Supported Nodes

| Node | n8n Type | What It Does |
|------|----------|-------------|
| Webhook | `n8n-nodes-base.webhook` | Receives HTTP requests |
| Set | `n8n-nodes-base.set` | Transform and set data fields |
| IF | `n8n-nodes-base.if` | Conditional branching |
| HTTP Request | `n8n-nodes-base.httpRequest` | Call external APIs |
| Code | `n8n-nodes-base.code` | Custom JavaScript |
| Slack | `n8n-nodes-base.slack` | Send Slack messages (simulated via Set when no credentials) |
| GitHub | `n8n-nodes-base.github` | GitHub API operations (simulated via Set when no credentials) |

The orchestrator knows its boundaries. If you ask for something outside this set, it'll tell you and suggest an alternative.

## Reference Workflows

Three hand-built, validated n8n workflows serve as few-shot examples for the orchestrator:

| Workflow | Pattern | Nodes | What It Demonstrates |
|----------|---------|-------|---------------------|
| `example-workflow-linear.json` | Linear | 2 | Webhook → Set with expressions |
| `example-workflow-branching.json` | Branching | 4 | IF conditions, true/false routing |
| `example-workflow-transform.json` | Transform | 5 | Field extraction, email domain parsing, lead scoring |

All three have been imported into n8n 1.85.4, activated, triggered via webhook, and verified to produce correct output.

## Validation

```bash
./verify.sh output/<timestamp>/
```

Runs 9 structural checks on generated workflow JSON:
- spec.md and workflow.json exist
- Valid JSON with required top-level fields
- All nodes have required keys (parameters, id, name, type, typeVersion, position)
- Node types use `n8n-nodes-base.` prefix
- First node is a trigger
- Connection references match node names
- `executionOrder` is `v1`

## n8n API Integration

Autoforge uses the n8n REST API for deployment and testing:

| Operation | Endpoint | Method |
|-----------|----------|--------|
| Create workflow | `/api/v1/workflows` | POST |
| Activate | `/api/v1/workflows/{id}/activate` | POST |
| Deactivate | `/api/v1/workflows/{id}/deactivate` | POST |
| Delete | `/api/v1/workflows/{id}` | DELETE |
| Test execution | `/webhook/{path}` | POST |
| List executions | `/api/v1/executions` | GET |

Auth: `X-N8N-API-KEY` header. Key generated in n8n Settings → API.

## Self-Correction Loop

When a deployed workflow fails:

1. Deployer classifies the error (recoverable vs terminal)
2. For recoverable errors: sends structured feedback to the orchestrator (failing node, error message, suggestion)
3. Orchestrator fixes the workflow JSON
4. Deployer re-deploys and re-tests
5. Up to 3 attempts before writing a failure report

Terminal errors (missing credentials, unsupported node types) stop immediately.

## Project Structure

```
autoforge/
├── .claude/
│   ├── settings.json               # Agent Teams config + permissions
│   ├── agents/
│   │   ├── orchestrator.md          # Conversation + generation agent
│   │   └── deployer.md              # Deploy + test + error feedback agent
│   └── commands/
│       └── autoforge.md             # /autoforge entry point skill
├── references/
│   ├── example-workflow-linear.json
│   ├── example-workflow-branching.json
│   └── example-workflow-transform.json
├── output/                          # Generated outputs (gitignored)
├── docker-compose.yml               # n8n 1.85.4
├── .env.example                     # API key template
├── verify.sh                        # Structural validation
├── CLAUDE.md                        # Project context for Claude Code
└── README.md
```

## Built With

- [Claude Code](https://claude.ai/code) — Agent orchestration, conversation, and code generation
- [Claude Code Agent Teams](https://docs.anthropic.com/en/docs/claude-code/agent-teams) — Multi-agent coordination (experimental)
- [n8n](https://n8n.io/) — Open-source workflow automation platform
- [Context Hub](https://github.com/andrewyng/context-hub) — API documentation for agents (optional)
