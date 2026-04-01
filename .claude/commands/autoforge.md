# /autoforge — Build an automation from natural language

You are the entry point for Autoforge, a conversational automation builder. When the user runs `/autoforge <description>`, you orchestrate a two-agent pipeline that turns their natural language description into a deployed n8n workflow.

## How It Works

1. You create a timestamped output directory
2. You dispatch the **Orchestrator agent** to have a conversation with the user, research APIs, and generate the workflow
3. Once the orchestrator produces `workflow.json`, you dispatch the **Deployer agent** to deploy and test it
4. If deployment fails with a recoverable error, you pass the error back to the orchestrator for a fix, then re-deploy (max 3 attempts)
5. You report the final result

## Step 1: Set Up Output Directory

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="output/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"
```

Tell the user: "Starting Autoforge. Output will be saved to `output/<timestamp>/`."

## Step 2: Run Orchestrator

Dispatch the orchestrator agent using the Agent tool. The orchestrator will:
- Have a conversation with the user (2-4 clarifying questions)
- Research relevant APIs
- Generate `spec.md` and `workflow.json` in the output directory

**Agent prompt:**
```
You are the Autoforge orchestrator agent. Read your full instructions at .claude/agents/orchestrator.md.

Read all 3 reference workflows before generating:
- references/example-workflow-linear.json
- references/example-workflow-branching.json
- references/example-workflow-transform.json

The user wants to build this automation:
"<USER_DESCRIPTION>"

Write your outputs to: <OUTPUT_DIR>/
- spec.md (human-readable automation spec)
- workflow.json (valid n8n workflow JSON)

Have a conversation with the user to clarify requirements before generating.
```

Wait for the orchestrator to complete. Verify that `workflow.json` exists in the output directory.

## Step 3: Run Deployer

Once `workflow.json` exists, dispatch the deployer agent:

**Agent prompt:**
```
You are the Autoforge deployer agent. Read your full instructions at .claude/agents/deployer.md.

Deploy and test the workflow at: <OUTPUT_DIR>/workflow.json

Run pre-flight checks, import to n8n, activate, and test with a realistic payload.
Report the result.
```

## Step 4: Handle Self-Correction

If the deployer returns a RECOVERABLE failure:

1. Read the deployer's error feedback
2. Re-dispatch the orchestrator with the error context:

```
The deployer found an error in the generated workflow.

ERROR_TYPE: <recoverable>
FAILING_NODE: <node name>
ERROR_MESSAGE: <what went wrong>
SUGGESTION: <deployer's suggestion>

Read the current workflow at <OUTPUT_DIR>/workflow.json, fix the issue, and write the corrected version back to the same path.
Also read your instructions at .claude/agents/orchestrator.md and the reference workflows for correct JSON structure.
```

3. Re-dispatch the deployer to test the fixed version
4. Repeat up to 3 total attempts

## Step 5: Report Result

**On success:**
```
Autoforge complete!

Automation: <name>
Spec: output/<timestamp>/spec.md
Workflow: output/<timestamp>/workflow.json
Webhook URL: http://localhost:5678/webhook/<path>

The workflow has been deployed and tested successfully.
Test payload: <what was sent>
Test response: <what came back>
```

**On failure after 3 attempts:**
```
Autoforge could not deploy this workflow after 3 attempts.

Spec: output/<timestamp>/spec.md
Workflow: output/<timestamp>/workflow.json (last version)
Failure report: output/<timestamp>/failure-report.md

The workflow JSON is still valid and can be imported manually into n8n.
```

## Notes

- The orchestrator and deployer run as separate agents using the Agent tool
- If Agent Teams is available (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1), the deployer can run as a teammate. Otherwise, use sequential Agent tool dispatch.
- The orchestrator handles the conversation and generation. The deployer handles infrastructure. They communicate through the filesystem and error messages.
- All outputs go to `output/<timestamp>/` to keep runs isolated
