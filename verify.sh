#!/bin/bash
# verify.sh — Validate autoforge outputs
# Usage: ./verify.sh [output_dir]
#   If no dir specified, checks the most recent output directory.

set -e

if [ -n "$1" ]; then
  DIR="$1"
else
  DIR=$(ls -dt output/*/ 2>/dev/null | head -1)
fi

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "FAIL: No output directory found"
  exit 1
fi

echo "Checking: $DIR"
PASS=0
FAIL=0

check() {
  if [ "$1" = "true" ]; then
    echo "  PASS: $2"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $2"
    FAIL=$((FAIL + 1))
  fi
}

# Check spec.md exists
check "$([ -f "$DIR/spec.md" ] && echo true || echo false)" "spec.md exists"

# Check workflow.json exists
check "$([ -f "$DIR/workflow.json" ] && echo true || echo false)" "workflow.json exists"

if [ ! -f "$DIR/workflow.json" ]; then
  echo ""
  echo "Result: $PASS passed, $FAIL failed (workflow.json missing, skipping JSON checks)"
  exit 1
fi

# Validate JSON
check "$(python3 -c "import json; json.load(open('$DIR/workflow.json')); print('true')" 2>/dev/null || echo false)" "workflow.json is valid JSON"

# Check required fields
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
print('true' if all(k in w for k in ['name','nodes','connections','settings']) else 'false')
" 2>/dev/null || echo false)" "Has required fields (name, nodes, connections, settings)"

# Check nodes have required keys
check "$(python3 << PYEOF
import json
w = json.load(open("$DIR/workflow.json"))
required = {"parameters","id","name","type","typeVersion","position"}
ok = all(required.issubset(set(n.keys())) for n in w.get("nodes",[]))
print(str(ok).lower())
PYEOF
)" "All nodes have required keys"

# Check node types start with n8n-nodes-base.
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
ok = all(n['type'].startswith('n8n-nodes-base.') for n in w['nodes'])
print('true' if ok else 'false')
" 2>/dev/null || echo false)" "All node types use n8n-nodes-base. prefix"

# Check first node is a trigger
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
first = w['nodes'][0]['type']
ok = 'webhook' in first or 'manualTrigger' in first or 'trigger' in first.lower()
print('true' if ok else 'false')
" 2>/dev/null || echo false)" "First node is a trigger"

# Check connections reference valid node names
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
node_names = {n['name'] for n in w['nodes']}
conn_sources = set(w['connections'].keys())
conn_targets = set()
for src, data in w['connections'].items():
    for branch in data.get('main', []):
        for conn in branch:
            conn_targets.add(conn['node'])
all_refs = conn_sources | conn_targets
ok = all_refs.issubset(node_names)
print('true' if ok else 'false')
" 2>/dev/null || echo false)" "All connection references match node names"

# Check IF nodes have exactly 2 branch arrays
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
if_nodes = [n for n in w['nodes'] if n['type'] == 'n8n-nodes-base.if']
if not if_nodes:
    print('true')
else:
    ok = all(len(w['connections'].get(n['name'], {}).get('main', [])) == 2 for n in if_nodes)
    print('true' if ok else 'false')
" 2>/dev/null || echo false)" "IF nodes have exactly 2 branch arrays"

# Check executionOrder
check "$(python3 -c "
import json
w = json.load(open('$DIR/workflow.json'))
print('true' if w.get('settings',{}).get('executionOrder') == 'v1' else 'false')
" 2>/dev/null || echo false)" "settings.executionOrder is v1"

echo ""
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
