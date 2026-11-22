# Changelog

All notable changes to the Oakallow MCP server listing are documented here. Versions
match the `version` field in `server.json`.

## 1.3.0

- **Resource, method and tenant on governed tools.** Customer-defined and gateway tools
  accept optional `oakallow_resource`, `oakallow_method` and `oakallow_tenant`
  arguments, so resource, method and tenant rules apply to MCP calls. They are prefixed
  so they never clash with a tool's own arguments, and are removed before a gateway
  call is forwarded.
  - A value that is not set up in oakallow is refused. It never defaults to allowed.
  - If one is left out and a rule for the tool names one, the strictest of those rules
    applies.
  - `check_permission` resolves exactly like the call it previews and also accepts the
    prefixed names.
- **Agents locked to targets.** An org can lock an agent to a list of resources and/or
  methods. A locked agent must send one from its list on every call; anything else is
  refused.
- **One pending request per caller and target.** Enforced by the database, so
  simultaneous identical calls create one approval request. Calling again returns the
  same `REF-…`.
- **Approval limits.** New approval requests are refused with a clear message when a
  caller has created 30 in the last minute, or when the org's pending limits are
  reached (default 25 per caller, 250 per org).
- **Request binding.** The approval request fingerprint now covers the resource and
  method when present. Requests without them verify exactly as before.
- `SKILL.md` and `README.md` document the new arguments; `server.json` and `tools.json`
  version 1.3.0.

## 1.2.0

- **Tool titles.** Every tool in `tools/list` can now carry a human-readable
  `annotations.title`, so clients and directories show a display name instead of the
  raw tool name.
  - The four standard tools: `List my tools`, `Check permission`,
    `List pending approvals`, `Check approval status`.
  - Customer-defined tools: an optional `title` (up to 128 characters) on
    `POST /v1/tools/seed`, the tool create, update and bulk endpoints, and the
    dashboard and mobile tool editors.
  - OakGuard gateway tools: the downstream server's own title (`annotations.title`,
    else the top-level `title`) is stored on sync. A title set in oakallow is never
    overwritten.
  - A tool with a title but no declared safety hints returns `annotations: { title }`
    only. oakallow never fills in hints the customer has not declared.
- `tools.json` snapshot updated with the standard tool titles.

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
