#!/usr/bin/env bash
#
# Oakallow MCP with an autonomous-agent token (illustrative)
#
# An agent that runs with no human to complete an OAuth sign-in authenticates to the
# same endpoint with a pre-issued `oak_agent_` bearer token. An org owner or admin
# provisions it from the dashboard (Account -> Agents); the raw token is shown once.
#
# The token is scoped to one org, can submit and check requests but never approve,
# and is rate-limited per agent identity.
#
# Usage: OAKALLOW_AGENT_TOKEN=oak_agent_... ./agent-token.sh
#
set -euo pipefail

MCP="https://api.oakallow.io/mcp"
: "${OAKALLOW_AGENT_TOKEN:?set OAKALLOW_AGENT_TOKEN to your oak_agent_ token}"

call() {
  curl -s -X POST "$MCP" \
    -H "Authorization: Bearer ${OAKALLOW_AGENT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$1" | jq .
}

echo "== 1. Initialize =="
call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"example-agent","version":"1.0.0"}}}'

echo
echo "== 2. List the tools this agent's org has approved =="
call '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

echo
echo "== 3. Dry-run a permission check (creates nothing) =="
call '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"check_permission","arguments":{"tool_name":"issue_refund"}}}'

echo
echo "== 4. Call the gated tool itself (creates the approval and returns a REF if gated) =="
# The org is implied by the agent token, so no `org` argument is needed.
call '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"issue_refund","arguments":{"reason":"Refund duplicate charge on order 1234 per support ticket"}}}'

echo
echo "== 5. Poll the approval by its reference =="
echo "Replace REF-XXXX with the reference returned in step 4."
cat <<'EOF'
call '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"check_approval_status","arguments":{"reference":"REF-XXXX"}}}'
EOF
