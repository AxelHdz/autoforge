# Workflow Spy

A team of AI agents that audits a web app via Playwright and generates n8n workflow automations.

## Architecture

Zero Python. Claude Code native. The "code" is agent prompts + a skill.

- `.claude/agents/navigator.md` — crawls via Playwright MCP, writes `output/page_map.json`
- `.claude/agents/analyst.md` — identifies automation opportunities, writes `output/opportunities.json`
- `.claude/agents/builder.md` — generates n8n workflow JSON, writes `output/workflows/*.json`
- `.claude/commands/audit.md` — orchestrator skill: `/audit <url>`

## How to Run

```
claude
> /audit http://localhost:8080
```

Agents coordinate via shared task list and filesystem. Uses Agent Teams (experimental) with Playwright MCP.

## Key Decisions

- Real web apps as targets (not mock CRMs). For the demo: Pipedrive, HubSpot free tier, or Notion.
- Agent Teams for parallel execution. Fallback: sequential via subagents.
- n8n workflow JSON output must be directly importable.

## Plan

See `PLAN.md` for the full reviewed plan (CEO + Eng + Design reviews cleared).
