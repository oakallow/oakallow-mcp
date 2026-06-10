# Oakallow MCP Server

[![MCP Badge](https://lobehub.com/badge/mcp/oakallow-oakallow-mcp)](https://lobehub.com/mcp/oakallow-oakallow-mcp)
[![MCP Badge](https://lobehub.com/badge/mcp-full/oakallow-oakallow-mcp)](https://lobehub.com/mcp/oakallow-oakallow-mcp)

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

- It can list your tools, check permissions, request approvals, and mint run tokens once an
  action is approved.
- It cannot approve or deny on a human's behalf. Decisions happen on a separate,
  MFA-bound surface (the dashboard), never over the connector.

## Standard tools

| Tool | Purpose | Reads only |
|------|---------|:---:|
| `list_my_tools` | Enumerate the tools available to the signed-in user in the named org (`org` arg; see below) | yes |
| `check_permission` | Ask whether a given tool call would be allowed, require approval, or be blocked (takes an `org` arg; see below) | yes* |
| `list_pending_approvals` | List approval requests still awaiting a human decision | yes |
| `check_approval_status` | Poll a pending approval request by reference number | yes |

\* `check_permission` returns a read-only verdict only — it does NOT create an approval or
a reference. (The approval and its `REF-…` are created when you call the gated tool itself
through oakallow.) It does have one side effect by design: checking an unregistered tool
makes Oakallow auto-create a gated draft entry for it (with conservative, fail-closed
defaults) so the eventual call is governed and the owner can triage it from the dashboard.
This is intentional: an unknown tool is never silently trusted.

## Choosing an organization

An Oakallow account can have more than one organization, and each org sets its own tools,
permission rules, approvers, and alert paths. So an action must be checked against the
**right** org — that is what determines who gets asked to approve and under which rules.

`check_permission` and `list_my_tools` accept an optional **`org`** argument: the org's
external id (e.g. `org_oak_…`). The rule:

- **One org on your account:** omit `org`. The connector uses your only org.
- **More than one org:** pass `org` naming the org the action targets. If you omit it, the
  call is refused with guidance rather than guessing the wrong org.

You don't ask the connector to list your orgs — there is no org-enumeration tool. Instead,
**download the org-specific skill from that org's dashboard.** Each org's skill carries its
own org id and tells the agent to pass it. Install one skill per org you operate in; the
agent reads the matching skill and passes the right `org` on every call.

The connector authorizes the `org` you pass against your signed-in identity: you can only
target an org you can actually act in (you are its team owner/admin, or you are in that
org's approver group). Passing an org you don't have access to is refused — the skill is a
convenience, not a grant of access.

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

**The remote endpoint requires OAuth 2.1 (PKCE) — there is no anonymous access.** An
oakallow account is the prerequisite for connecting.

Add `https://api.oakallow.io/mcp` as a custom connector in your MCP client (Claude,
Claude Desktop, Cowork, ChatGPT, or any Streamable HTTP MCP host). You will be redirected
to sign in to Oakallow and approve the requested scopes:

- `mcp:read`: list tools, view pending approvals, check permissions, read activity.
- `mcp:write`: create approval requests and mint run tokens.

You don't configure any of this by hand: an unauthenticated request returns `401` with a
`WWW-Authenticate` header pointing to the endpoint's RFC 9728 protected-resource metadata
(`/.well-known/oauth-protected-resource`), so a spec-compliant MCP client discovers the
authorization server and runs the OAuth flow automatically.

See `examples/` for a Claude Desktop config and an OAuth flow walkthrough.

## Skill

[`SKILL.md`](./SKILL.md) is an agent skill that documents when and how to use the
oakallow tools: the request, approve, poll, and act workflow, how to phrase
approval reasons, and what to do on `allowed`, `requires_approval`, or `blocked`
verdicts. Point your agent at it to govern tool actions correctly.

## Trigger prompts

[`PROMPT.md`](./PROMPT.md) has short, copy-paste one-liners to drop into your
agent's system prompt so it actually consults the skill. The skill is the
procedure; a trigger prompt is what makes the agent look. Three options, from
"gate every tool call" to "gate a customer-named set," plus an inline example
pattern for a real request.

## How a governed call works

1. The agent calls Oakallow with its credential.
2. Oakallow resolves the permission rule for the specific tool, tenant, and resource.
3. If the action is allowed, Oakallow mints a single-use, HMAC-signed run token.
4. If approval is required, an approval request is created and a human is notified. The
   agent's call is held until the request is decided or expires.
5. The agent uses the run token to perform the action; Oakallow writes an immutable audit
   row capturing the outcome.

Oakallow lives outside the execution path. It governs and records what was reported; it
does not run your tools or receive your tool parameters beyond a PII-scrubbed reason.

## License

See [LICENSE](./LICENSE).

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

---

© Islemonics Studios LLC. Patent pending.
