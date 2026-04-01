# Build "Workflow Spy" — Multi-Agent Workflow Auditor

## Context

Strategy: Build 1 polished showcase tool using cutting-edge Claude features (Agent Teams + Playwright MCP) that demonstrates the exact AI/automation skills every target company is hiring for. The tool analyzes a real web app, identifies automation opportunities, and generates n8n workflow JSON. The demo video shows agents working in parallel in split-pane terminal mode.

**Why this over alternatives:** The outside voice in the CEO review correctly identified that building generic frameworks (eval tools, lead scorers) produces commodity plumbing that existing tools already do better. Workflow Spy can't be compared to anything because it combines experimental multi-agent orchestration with live browser automation to solve a universal GTM/ops problem.

**Target companies:** ALL — Toast, Doss, Monarch, HumanSignal, Acquisition, Postscript, Attentive, Retool, Figma, ClickUp, Cognition
**Goal:** Public GitHub repo + demo video + LinkedIn post + targeted DMs
**Cutting-edge features:** Agent Teams (experimental, Mar 2026) + Playwright MCP

---

## Final Scope (post eng review — scope reduced to Claude Code native)

### Architecture Decision (Eng Review)
**Zero Python.** The plan originally proposed Python modules (crawler.py, patterns.py, n8n_generator.py) that reimplemented capabilities Claude Code already has natively. The eng review identified this as redundant plumbing. The entire tool is agent prompt files + a Claude Code skill.

### Core
- **Agent Team** with 3 specialized agents (defined as `.claude/agents/*.md`):
  1. **Navigator** — Uses Playwright MCP to crawl, map pages/elements/flows, writes `output/page_map.json`
  2. **Analyst** — Reads page map, identifies manual/repetitive patterns, scores opportunities, writes `output/opportunities.json`
  3. **Builder** — Reads opportunities, generates n8n workflow JSON, writes `output/workflows/*.json`
- **Orchestrator skill** (`.claude/commands/audit.md`) — kicks off the team, coordinates handoff
- Agents coordinate via shared task list, inter-agent messaging, and filesystem
- Split-pane terminal visualization showing all 3 working simultaneously

### Demo CRM (the test fixture)
Realistic 5-page mock CRM:
- `index.html` — Dashboard with navigation
- `deals.html` — Table of 15 deals with stages
- `deal-new.html` — Multi-step form (company, contact, amount, stage, notes)
- `contacts.html` — Contact table with 20 entries + search
- `settings.html` — Pipeline configuration

Seeded with realistic data and manual copy-paste workflows between pages, so agents find non-obvious automation opportunities.

### Accepted Expansions (from CEO cherry-picks)
- **Rich terminal output** — colored progress, agent status indicators
- **Demo recording** — Loom or asciinema showing the full run
- **Case study write-up** — Run against own Notion workspace, document findings
- **GitHub Actions CI** — simplified check that agents produce output against demo CRM

### Fallback Strategy
Agent Teams is experimental. If unreliable:
- **Fallback A:** Sequential agents using Claude Code subagents (Agent tool dispatch)
- **Fallback B:** Single agent with phased execution (navigate → analyze → build)
- Core value survives regardless of orchestration method

### Design Specs (from design review)

**Demo CRM (5/10 → targeting 8/10):**
- Tailwind CSS, modeled after Pipedrive/HubSpot-lite visual style
- Sidebar nav: logo placeholder, Dashboard, Deals, Contacts, Settings
- Data tables: alternating rows, sortable headers, status badges (Won/In Progress/Lost)
- Forms: labeled inputs, dropdowns, textarea, submit button
- Realistic data: real-sounding companies ("Meridian Health Systems"), $45K-$250K amounts, pipeline stages
- Key: VISIBLE manual patterns agents will spot (copy-paste between pages, multi-step forms, manual stage updates)

**Terminal Output (4/10 → targeting 9/10):**
- Box-drawing frame for screenshot-friendliness
- Agent status panel: name, progress bar, percentage, elapsed time
- Real-time findings as agents discover them (green checkmarks, spinners)
- Final summary: total opportunities, workflows generated, time elapsed
- Use `rich` Panel, Progress, Table, and Live components

**README (3/10 → targeting 9/10):**
- Lead with one-liner hook, NOT installation
- Demo GIF or Loom embed immediately after hook (above the fold)
- Architecture diagram as second element
- Terminal screenshot showing rich output
- 2-line Quick Start
- Case study link for depth
- "Built with" at bottom, minimal

### NOT in scope
- Python packages/modules (not needed — Claude Code native)
- pytest or unit tests (integration tests via demo CRM)
- pip/PyPI packaging
- Web dashboard
- LangChain/CrewAI integration
- Production monitoring
- Computer Use (macOS only)
- Eval framework (original plan, cut)
- Lead scoring agent (cut)

---

## Architecture

```
workflow-spy/
├── .claude/
│   ├── settings.json            # Agent Teams env + config
│   └── agents/
│       ├── navigator.md         # Crawl via Playwright MCP
│       ├── analyst.md           # Identify patterns + score
│       └── builder.md           # Generate n8n workflow JSON
├── .claude/commands/
│   └── audit.md                 # Orchestrator skill: /audit <url>
├── examples/
│   └── demo_crm/               # Realistic 5-page mock CRM
│       ├── index.html
│       ├── deals.html
│       ├── deal-new.html
│       ├── contacts.html
│       └── settings.html
├── output/                      # Generated reports + workflows
│   ├── page_map.json
│   ├── opportunities.json
│   └── workflows/
│       └── *.json               # n8n workflow files
├── docs/
│   └── case-study.md            # Real audit of own Notion workspace
├── verify.sh                    # Check outputs exist + n8n JSON valid
└── README.md                    # Architecture, video, case study link
```

### Data Flow

```
/audit <url>
    │
    ▼
Navigator (Playwright MCP)
    │ browser_navigate, browser_snapshot,
    │ browser_click, browser_screenshot
    │
    ├──▶ output/page_map.json
    │    (pages, elements, forms, flows)
    │
    ▼
Analyst (Claude analysis)
    │ reads page_map.json
    │ identifies patterns, scores 1-10
    │
    ├──▶ output/opportunities.json
    │    (what to automate, why, score)
    │
    ▼
Builder (Claude generation)
    │ reads opportunities.json
    │ generates n8n workflow JSON
    │
    └──▶ output/workflows/*.json
         (valid, importable n8n files)
```

### Agent Communication

```
Navigator completes page crawl
    ├──▶ Shared task: "Page map ready: 5 pages, 47 elements"
    ├──▶ Messages Analyst: "Key finding: 3 forms with manual data entry"
    │
Analyst starts (Navigator continues deeper crawl)
    ├──▶ Shared task: "Found 5 automation opportunities, scoring..."
    ├──▶ Messages Builder: "Top: deal creation has 4 manual steps"
    │
Builder starts (Analyst continues scoring)
    ├──▶ Shared task: "Generated n8n workflow for deal automation"
    │
All complete → Final report in output/
```

---

## Error Handling

| Codepath | Failure | Handled? | User Sees |
|----------|---------|----------|-----------|
| Agent Teams init | Feature flag not set | Y | "Enable: set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" |
| Agent Teams init | Feature unavailable | Y | "Running in sequential fallback mode" |
| Playwright navigate | URL unreachable | Y | "Cannot reach {url}" |
| Playwright navigate | Auth wall | Y | "Target requires authentication" |
| Playwright snapshot | Too complex | Y | "Large page. Analyzing top 200 elements." |
| Analyst | No patterns found | Y | "No automation opportunities detected" |
| Builder | Can't generate n8n | Y | "Could not generate workflow. Manual setup needed." |
| Agent crash | Mid-run failure | Y | "Partial report generated" |

---

## LinkedIn Strategy

### The Post
```
I built a team of AI agents that audits your web app
and generates automations for you.

Here's how it works:
- You give it a URL
- Agent 1 (Navigator) crawls the app via headless browser
- Agent 2 (Analyst) identifies manual, repetitive workflows
- Agent 3 (Builder) generates importable n8n workflow JSON

All three work in parallel. You can watch them coordinate
in real-time in a split-pane terminal.

I pointed it at my own Notion job tracking workspace.
It found 5 automation opportunities I'd missed and
generated 3 working n8n workflows in under 4 minutes.

[Demo video]
Code: [GitHub link]

Built with Claude Code Agent Teams (experimental) +
Playwright browser automation.

#AI #Automation #AgentTeams #WorkflowAutomation
```

### Distribution
- Post Tues/Wed 10-11am PT
- DM 2-3 team members at each target company
- The split-pane video is the key visual
- Tag #ClaudeCode and #Anthropic for community reach

---

## Build Sequence

```
Day 1 (~3-4h with CC):
  - Project scaffolding (directory structure, settings.json)
  - Navigator agent prompt (Playwright crawling, page mapping)
  - Demo CRM (5 realistic pages with forms, tables, workflows)
  - Test Navigator against demo CRM

Day 2 (~2-3h with CC):
  - Analyst agent prompt (pattern detection, opportunity scoring)
  - Builder agent prompt (n8n workflow JSON generation)
  - Orchestrator skill (audit.md — kicks off the team)
  - Agent team config and inter-agent messaging
  - Test full team run against demo CRM

Day 3 (~2-3h):
  - Fallback mode (sequential) if agent teams is flaky
  - verify.sh (check outputs exist, n8n JSON valid)
  - Case study: run against own Notion workspace
  - README with architecture diagrams
  - Demo video recording (split-pane terminal)

Total: ~8-10h with CC
```

---

## Pipeline Integration

After the tool ships, update the job-app-bot pipeline:

1. New file: `config/portfolio-tools.yaml` — maps Workflow Spy to all companies/archetypes
2. New file: `cli/portfolio_match.py` — matches scrape.json against portfolio tools
3. Update `.claude/commands/apply.md` — add portfolio match step before document generation
4. Update `config/agent-prompt.md` Phase 3 — instruction to reference portfolio when relevant

---

## Verification

1. `/audit http://localhost:8080` against demo CRM produces all output files
2. `output/page_map.json` contains all 5 pages and their elements
3. `output/opportunities.json` contains at least 3 scored automation opportunities
4. `output/workflows/*.json` are valid n8n workflow JSON (verify.sh checks)
5. Fallback sequential mode produces same outputs when agent teams disabled
6. Case study documents real findings from own Notion workspace
7. Demo video shows split-pane agents working in parallel
8. README renders on GitHub with architecture diagram and embedded video
9. Full team run completes in under 5 minutes

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEAR | 5 proposals, 4 accepted, 1 deferred. Pivoted from eval framework to Workflow Spy. |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 2 issues (both resolved). Scope reduced: Python project → Claude Code native. Zero Python. |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | score: 4/10 → 8/10, 3 decisions (demo CRM style, terminal format, README hierarchy) |

**VERDICT:** CEO + ENG + DESIGN CLEARED — ready to implement.
