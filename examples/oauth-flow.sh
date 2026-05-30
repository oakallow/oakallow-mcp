#!/usr/bin/env bash
#
# Oakallow MCP OAuth 2.1 flow walkthrough (illustrative)
#
# This shows the discovery + authorization-code-with-PKCE shape that an MCP client
# performs for you automatically. You normally never run this by hand; your MCP host
# (Claude, Cowork, ChatGPT) does it. It is here so you can see what happens under the hood
# and verify the endpoints.
#
# Endpoint base: https://api.oakallow.io
# MCP resource:  https://api.oakallow.io/mcp
#
set -euo pipefail

BASE="https://api.oakallow.io"

echo "== 1. Discover the protected resource metadata (RFC 9728) =="
curl -s "${BASE}/.well-known/oauth-protected-resource" | jq .

echo
echo "== 2. Discover the authorization server metadata (RFC 8414) =="
curl -s "${BASE}/.well-known/oauth-authorization-server" | jq .
# Note: code_challenge_methods_supported should include "S256".

echo
echo "== 3. PKCE: generate a verifier + challenge =="
VERIFIER="$(openssl rand -base64 60 | tr -d '\n=+/' | cut -c1-64)"
CHALLENGE="$(printf '%s' "$VERIFIER" \
  | openssl dgst -binary -sha256 \
  | openssl base64 \
  | tr '+/' '-_' | tr -d '=\n')"
echo "verifier:  ${VERIFIER}"
echo "challenge: ${CHALLENGE}"

echo
echo "== 4. Authorize (open in a browser) =="
echo "Open the URL below, sign in to Oakallow, and approve the scopes."
echo "After approval you are redirected to your client's redirect_uri with ?code=..."
cat <<EOF
${BASE}/authorize?response_type=code\\
&client_id=<your_client_id>\\
&redirect_uri=<your_redirect_uri>\\
&scope=mcp:read%20mcp:write\\
&code_challenge=${CHALLENGE}\\
&code_challenge_method=S256\\
&state=<random_state>
EOF

echo
echo "== 5. Exchange the authorization code for tokens =="
cat <<'EOF'
curl -s -X POST "https://api.oakallow.io/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=<code_from_redirect>" \
  -d "redirect_uri=<your_redirect_uri>" \
  -d "client_id=<your_client_id>" \
  -d "code_verifier=<the_verifier_from_step_3>" | jq .
# Returns an opaque access_token (bound to https://api.oakallow.io/mcp) and a refresh_token.
EOF

echo
echo "== 6. Call the MCP endpoint with the bearer token =="
cat <<'EOF'
curl -s -X POST "https://api.oakallow.io/mcp" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | jq .
EOF

echo
echo "== 7. Revoke when done (RFC 7009) =="
cat <<'EOF'
curl -s -X POST "https://api.oakallow.io/revoke" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=<access_or_refresh_token>"
# The token is invalidated immediately.
EOF
