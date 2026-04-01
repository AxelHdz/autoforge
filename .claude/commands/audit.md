# Audit a Web App for Automation Opportunities

Analyze a web application to identify manual workflows that can be automated, then generate importable n8n workflow JSON files.

**Input:** $ARGUMENTS is a URL to audit (e.g., `http://localhost:8080`)

---

## Step 1: Prepare workspace

```bash
mkdir -p output/screenshots output/workflows
```

Clear any previous audit results:
```bash
rm -f output/page_map.json output/opportunities.json output/workflows/*.json
```

---

## Step 2: Launch the Agent Team

Dispatch all three agents. The Navigator starts immediately. The Analyst and Builder wait for their inputs to be ready.

### Navigator Agent
Launch the Navigator agent to crawl the target URL using Playwright browser tools. It will:
- Visit every page reachable from the main navigation
- Catalog forms, tables, buttons, links, inputs on each page
- Identify multi-step workflows and cross-page data patterns
- Take screenshots of each page
- Write `output/page_map.json`

### Analyst Agent
Once `output/page_map.json` exists, launch the Analyst agent to:
- Identify manual, repetitive patterns
- Score each automation opportunity (1-10)
- Write `output/opportunities.json`

### Builder Agent
Once `output/opportunities.json` exists, launch the Builder agent to:
- Generate valid n8n workflow JSON for each opportunity scored 7+
- Write workflows to `output/workflows/`
- Write `output/workflows/README.md`

---

## Step 3: Compile the Audit Report

After all agents complete, read the outputs and produce a summary:

```
============================================================
  WORKFLOW SPY — AUDIT COMPLETE
============================================================

  Target:          $ARGUMENTS
  Pages crawled:   [count from page_map.json]
  Elements found:  [count from page_map.json]

  AUTOMATION OPPORTUNITIES:
  ─────────────────────────────────────────────────────────
  [score] [name]
          [1-line description]
          → Workflow: output/workflows/[filename].json

  ─────────────────────────────────────────────────────────
  Total opportunities: [count]
  Workflows generated: [count]
  Time elapsed:        [duration]
============================================================
```

---

## Step 4: Verify outputs

Check that all expected files exist:
- `output/page_map.json` — the crawl map
- `output/opportunities.json` — scored opportunities
- `output/workflows/*.json` — n8n workflow files
- `output/workflows/README.md` — workflow documentation
- `output/screenshots/` — page screenshots

Report any missing outputs.
