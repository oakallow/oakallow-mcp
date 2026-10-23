# Changelog

All notable changes to the Oakallow MCP server listing are documented here. Versions
match the `version` field in `server.json`.

## 1.1.0

- **OakGuard gateway.** Orgs can register their own MCP servers with oakallow.
  Registration requires OAuth 2.1 downstream (S256 PKCE, RFC 9728/8414 discovery, no
  password grant). Their tools appear in `tools/list` under their real names and
  schemas. oakallow forwards a call only after it is allowed or approved, once per
  approval, and does not store or log payloads.
- **Signed decision receipts.** Every permission decision on an approved tool returns
  an HMAC-SHA256 signed receipt reference for any verdict, and fails closed if the
  decision cannot be signed or recorded.
- **`agent` argument** on customer-defined tools, so the governance report can show
  which agent submitted each call. Ignored for `oak_agent_` tokens, whose own identity
  is used.
- **Autonomous agents.** `oak_agent_` bearer tokens authenticate to the same endpoint
  without OAuth, scoped to one org, and can never approve. Added
  `examples/agent-token.sh`.
- **`org` argument** on `check_permission` and `list_my_tools` for multi-org
  accounts, with per-org skills downloaded from the dashboard.
- **Resources:** `oakallow://status` and `oakallow://credits` (read-only, unbilled).
- **Conformance:** `resources/templates/list` now returns an empty list instead of an
  error, which fixes health checks in strict MCP clients.
- **Docs:** clarified that `check_permission` is a dry-run that creates no approval or
  reference; the gated tool call creates the `REF-…`. Fixed `PROMPT.md` and the
  `SKILL.md` example, which still described the old behavior. Standardized verdict names
  (`allowed` / `requires_approval` / `disabled`). Added `PROMPT.md` trigger prompts and
  `SKILL.md`.
- Added `tools.json`, a snapshot of the standard tools as `tools/list` returns them.
- Added `glama.json` maintainer file.

## 1.0.0

- Initial publication to the MCP Registry (`io.github.oakallow/oakallow`).
- Hosted remote server at `https://api.oakallow.io/mcp` over Streamable HTTP.
- OAuth 2.1 (PKCE, dynamic client registration) authorization.
- Standard tools: `list_my_tools`, `check_permission`, `list_pending_approvals`,
  `check_approval_status`.
