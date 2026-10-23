# Oakallow MCP Server

[![MCP Badge](https://lobehub.com/badge/mcp/oakallow-oakallow-mcp)](https://lobehub.com/mcp/oakallow-oakallow-mcp)
[![MCP Badge](https://lobehub.com/badge/mcp-full/oakallow-oakallow-mcp)](https://lobehub.com/mcp/oakallow-oakallow-mcp)
[![CI](https://github.com/oakallow/oakallow-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/oakallow/oakallow-mcp/actions/workflows/ci.yml)

Runtime permission, approval, and audit governance for AI agent tool execution.

Oakallow is a hosted remote MCP server. It sits between an agent and the actions it
wants to take, so that a specific action can be checked, gated behind human approval when
it is risky, authorized with a single-use signed token, and recorded in an immutable audit
log, at the moment of execution.

- **Website:** https://oakallow.com
- **MCP endpoint:** `https://api.oakallow.io/mcp` (Streamable HTTP)
- **OAuth 2.1 compliance:** https://oakallow.com/docs/oauth
- **MCP protocol details:** https://oakallow.com/docs/mcp

## What this connector is for

Oakallow injects a governance checkpoint into a workflow that may also use other
connectors. An agent does its investigative work (for example, looking up an account
through another connector), forms a recommendation, and calls Oakallow to **request**
approval for the action. A human approver then decides in the Oakallow dashboard or mobile
app, under enforced multi-factor authentication.

The connector is a **requester and pass-through**, not a decider:

- It can list your tools, check permissions, request approvals, return a signed receipt for
  every decision, and, for servers connected through the OakGuard gateway, forward a call
  once it is approved.
- It cannot approve or deny on a human's behalf. Decisions happen on a separate,
  MFA-bound surface (the dashboard), never over the connector.

## Standard tools

| Tool | Purpose | Reads only |
|------|---------|:---:|
| `list_my_tools` | Enumerate the tools available to the signed-in user in the named org (`org` arg; see below) | yes |
| `check_permission` | Ask whether a given tool call would be allowed, require approval, or be blocked (takes an `org` arg; see below) | yes* |
| `list_pending_approvals` | List approval requests still awaiting a human decision | yes |
| `check_approval_status` | Poll a pending approval request by reference number | yes |

\* `check_permission` returns a read-only verdict only. It does NOT create an approval or
a reference. (The approval and its `REF-…` are created when you call the gated tool itself
through oakallow.) It does have one side effect by design: checking an unregistered tool
makes Oakallow auto-create a gated draft entry for it (with conservative, fail-closed
defaults) so the eventual call is governed and the owner can triage it from the dashboard.
This is intentional: an unknown tool is never silently trusted.

## Choosing an organization

An Oakallow account can have more than one organization, and each org sets its own tools,
permission rules, approvers, and alert paths. So an action must be checked against the
**right** org, because that is what determines who gets asked to approve and under which rules.

`check_permission` and `list_my_tools` accept an optional **`org`** argument: the org's
external id (e.g. `org_oak_…`). The rule:

- **One org on your account:** omit `org`. The connector uses your only org.
- **More than one org:** pass `org` naming the org the action targets. If you omit it, the
  call is refused with guidance rather than guessing the wrong org.

You don't ask the connector to list your orgs; there is no org-enumeration tool. Instead,
**download the org-specific skill from that org's dashboard.** Each org's skill carries its
own org id and tells the agent to pass it. Install one skill per org you operate in; the
agent reads the matching skill and passes the right `org` on every call.

The connector authorizes the `org` you pass against your signed-in identity: you can only
target an org you can actually act in (you are its team owner/admin, or you are in that
org's approver group). Passing an org you don't have access to is refused. The skill is a
convenience, not a grant of access.

## Calling a governed tool

Alongside the four standard tools, `tools/list` returns the customer-defined tools your
org has approved. Calling one of those through oakallow is how an approval gets created:
there is no separate "request approval" tool. A direct tool accepts two optional
arguments, plus `org` as above:

| Argument | Purpose |
|----------|---------|
| `reason` | Short, non-sensitive summary of why the call is being made. This is what the human approver reads. Oakallow redacts SSN, card, email, phone, and address patterns before storing it. |
| `agent` | An identifier for the calling agent (a name, code, or number). The org's governance report uses it to show which agent submitted each call instead of attributing everything to the signed-in account. Send the same value consistently. Ignored when the caller authenticates with an `oak_agent_` token, whose own identity is used. |

The response is one of `allowed` (run the action on its own connector), `requires_approval`
(an approval request was created and a `REF-…` is returned for polling with
`check_approval_status`), or `disabled` (stop; the action is blocked by policy).

## Signed decision receipts

Every permission decision on an approved tool returns a **signed decision receipt**,
whatever the verdict: `allowed`, `requires_approval`, and `disabled` are all signed the
same way. The receipt is an HMAC-SHA256 signature over the decision, the tool, a hash of
the call's parameters, the tenant, resource, method, and org, and it is stored so the
decision can be re-verified later. A `disabled` receipt is the proof that oakallow blocked
the action.

If a decision cannot be signed or recorded, the check fails closed: oakallow returns no
verdict rather than one it cannot prove.

## OakGuard gateway

By default oakallow is a checkpoint beside your tools: it decides, and you execute.
**OakGuard** lets an org register its own MCP servers with oakallow so that oakallow
becomes the transport to them instead:

- **OAuth 2.1 is mandatory downstream.** Registration is refused unless the server
  advertises the OAuth 2.1 essentials (authorization code with S256 PKCE, RFC 9728 and
  RFC 8414 discovery, no password grant). oakallow registers itself as the server's OAuth
  client and keeps the downstream tokens encrypted.
- **Tools appear under their real names and schemas** in `tools/list`. Newly discovered
  tools land as drafts that require approval until an admin enables them.
- **A call is forwarded only after it is allowed** by the permission rules or approved by
  a human. Each approval rides downstream exactly once.
- **Payloads pass through but are not kept.** oakallow carries the request and response
  over TLS on both legs and does not store or log them. Receipts and the audit log
  record the decision, not the data.

Servers are registered, paused, and revoked from the OakGuard tab in the dashboard.

## Resources

oakallow exposes two read-only MCP resources. They are preflight signals an agent (or a
client UI) can read before committing to route an action through oakallow. Both require
the `mcp:read` scope, neither is a tool call, and neither is billed.

| Resource | Returns | Reads only |
|----------|---------|:---:|
| `oakallow://status` | Liveness of the connector for the signed-in session: status, endpoint, server version, protocol version, and the granted scopes. A successful read is itself the proof the session is valid. No account identity or PII is returned. | yes |
| `oakallow://credits` | Whether a governed call would currently be funded for the org this session resolves to, so an agent can fail fast before requesting an approval that could not be paid for. | yes |

`oakallow://credits` is scoped to the caller's own billing org and resolves it the same
way a real tool call does, so a `can_fund: true` result genuinely means the eventual
approval will be funded (including team-pool fallback). It returns only a `can_fund`
boolean and the org's name and external id. It deliberately discloses no balance figures:
dollar amounts are surfaced only to the team owner in the dashboard, never over the
connector. If the session resolves to no org, or to more than one, it returns
`can_fund: false` with a reason rather than guessing which org would be billed.

## Connecting

**There is no anonymous access.** An oakallow account is the prerequisite for connecting,
and the endpoint accepts two credential types: interactive OAuth 2.1 (PKCE) for a
human-driven client, or an `oak_agent_` bearer token for an autonomous agent (see
[Autonomous agents](#autonomous-agents-oak_agent_-token) below).

For the human-driven OAuth path, add `https://api.oakallow.io/mcp` as a custom connector
in your MCP client (Claude, Claude Desktop, Cowork, ChatGPT, or any Streamable HTTP MCP
host). You will be redirected to sign in to Oakallow and approve the requested scopes:

- `mcp:read`: list tools, view pending approvals, check permissions, read activity.
- `mcp:write`: create approval requests and mint run tokens.

You don't configure any of this by hand: an unauthenticated request returns `401` with a
`WWW-Authenticate` header pointing to the endpoint's RFC 9728 protected-resource metadata
(`/.well-known/oauth-protected-resource`), so a spec-compliant MCP client discovers the
authorization server and runs the OAuth flow automatically.

See `examples/` for a Claude Desktop config, an OAuth flow walkthrough, and an
`oak_agent_` token walkthrough. [`tools.json`](./tools.json) has the exact schemas of the
standard tools.

### Autonomous agents (`oak_agent_` token)

OAuth assumes a human can complete the interactive sign-in. An autonomous agent that runs
on its own authenticates to the same `https://api.oakallow.io/mcp` endpoint with a
pre-issued bearer token instead: `Authorization: Bearer oak_agent_...`. The endpoint
checks for an `oak_agent_` bearer before the OAuth provider, so no consent screen or
interactive login is involved.

An agent identity is scoped to one organization, can submit and check permission requests
but never approve, is rate-limited per identity, and is stored only as a SHA-256 hash (the
raw token is shown once at creation). Provision one from the dashboard's Account &rarr;
Agents page (owner/admin only). See [oakallow.io/info/agents](https://oakallow.io/info/agents)
for the full model.

## Skill

[`SKILL.md`](./SKILL.md) is an agent skill that documents when and how to use the
oakallow tools: the request, approve, poll, and act workflow, how to phrase
approval reasons, and what to do on `allowed`, `requires_approval`, or `disabled`
verdicts. Point your agent at it to govern tool actions correctly.

## Trigger prompts

[`PROMPT.md`](./PROMPT.md) has short, copy-paste one-liners to drop into your
agent's system prompt so it actually consults the skill. The skill is the
procedure; a trigger prompt is what makes the agent look. Three options, from
"gate every tool call" to "gate a customer-named set," plus an inline example
pattern for a real request.

## How a governed call works

1. The agent calls the tool through Oakallow with its credential, a `reason`, and its
   `agent` id.
2. Oakallow resolves the permission rule for the specific tool, tenant, and resource, and
   signs a decision receipt for the verdict.
3. If the action is allowed, the agent performs it: on its own connector for a direct
   tool, or Oakallow forwards it for an OakGuard gateway tool.
4. If approval is required, an approval request is created, a human is notified, and the
   agent receives a `REF-…` to poll. Once a human approves under MFA, the action runs
   exactly once.
5. Oakallow writes an immutable audit row capturing the outcome.

For direct tools, Oakallow lives outside the execution path: it governs and records what
was reported, and it does not run your tools or receive your tool parameters beyond a
PII-scrubbed reason. For OakGuard gateway tools, it is the transport for approved calls
but still keeps none of the payloads.

Outside MCP, the REST API (`POST /v1/tokens/mint`) can also mint a single-use,
HMAC-signed run token that binds the tool and its parameters, for your backend to verify
before executing.

## License

See [LICENSE](./LICENSE).

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

---

© Islemonics Studios LLC. Patent pending.
