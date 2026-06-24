---
name: oakallow-governance
description: >-
  Use this skill when an AI agent needs to act safely through oakallow, the
  runtime permission, approval, and audit layer for AI agent tool execution.
  Trigger it whenever you are about to take a tool action that could be risky,
  irreversible, or that touches another system, and you need to know whether it
  is allowed, request human approval, or check the status of a pending approval.
  oakallow is a hosted remote MCP server using OAuth 2.1; an oakallow account is
  required to sign in, and the tools an agent can use, the rules that govern
  them, and the approvals themselves are all defined and decided by a human in
  the oakallow dashboard. Covers the oakallow MCP tools: list_my_tools,
  check_permission, list_pending_approvals, and check_approval_status. Use it
  for phrases like "is this allowed", "request approval", "needs a human to
  approve", "check the approval", "what can I do here", or "audit this action".
license: MIT
---

# oakallow governance skill

oakallow is a hosted remote MCP server that sits between an agent and the
actions it wants to take. It does not run your tools or receive your tool
parameters. It governs the moment of execution: it checks whether a specific
action is permitted, gates risky or irreversible actions behind human approval,
and records an immutable audit row.

This skill tells you, the agent, when and how to call oakallow's tools so a
governed workflow behaves correctly.

- **Endpoint:** `https://api.oakallow.io/mcp` (Streamable HTTP)
- **Authorization:** self-hosted OAuth 2.1 (PKCE, S256) for human-driven clients, or an `oak_agent_` bearer token for autonomous agents (both on the same endpoint)
- **Website:** https://oakallow.com
- **Scopes:** `mcp:read` (list, check, read activity), `mcp:write` (create approval requests)

## Account and authorization (read this first)

oakallow is **hosted** and requires an **oakallow account**. You cannot use this
connector anonymously.

- Connecting runs an **OAuth 2.1** flow. The host opens oakallow's hosted consent
  screen, the human signs in to their oakallow account, and approves the scopes
  (`mcp:read`, `mcp:write`). Authorization is bound to that signed-in account.
- **Humans define and decide everything that governs you.** In the oakallow
  dashboard, a person registers the tools an agent may use, sets the permission
  rules for each tool, decides which actions require approval, and approves or
  denies requests. The connector does not configure tools or set rules, and it
  can never approve on a human's behalf.
- If there is no valid oakallow session, the connector cannot be used until the
  human signs in. Surface that to the user rather than trying to work around it.
- **Autonomous agents** that run with no human to sign in use a pre-issued
  `oak_agent_` bearer token instead of the OAuth flow (`Authorization: Bearer
  oak_agent_...`). The token is scoped to one org and the agent can submit and
  check requests but never approve, the same governance still applies. A person
  provisions it from the dashboard; see https://oakallow.io/info/agents.

## The mental model

oakallow is a **requester and pass-through, not a decider**. The connector can
ask whether something is allowed and can request approval, but it can never
approve or deny on a human's behalf. Decisions happen on a separate, MFA-bound
surface (the oakallow dashboard or mobile app). So the agent's job is:

1. Before a sensitive action, **ask** oakallow if it is allowed.
2. If it requires approval, **request** it, then wait for a human to decide.
3. Once a human approves, perform the action.
4. Every outcome is recorded in an immutable audit row.

Never assume an action is allowed. Never try to self-approve. Never route a
decision through the connector.

## Tools

| Tool | Purpose | Reads only |
|------|---------|:---:|
| `list_my_tools` | Enumerate the tools available to the signed-in user in the named org | yes |
| `check_permission` | Ask whether a given tool call would be allowed, require approval, or be blocked | yes (see note) |
| `list_pending_approvals` | List approval requests still awaiting a human decision | yes |
| `check_approval_status` | Poll a pending approval request by its reference | yes |

### Targeting the right organization

An oakallow account can have more than one organization, and **each org has its own
tools, rules, approvers, and alerting**. So a check must go to the org the action
actually belongs to.

`check_permission` and `list_my_tools` take an optional **`org`** argument — the org's
external id (`org_oak_…`):

- If the account has exactly one org, omit it.
- If the account has more than one org, **pass `org`**. This skill is downloaded
  per-org from the oakallow dashboard, so the org id for the org this skill governs is
  stated below — pass that id on every `check_permission` call. If you omit it on a
  multi-org account, the call is refused rather than sent to the wrong org.

You cannot list orgs through the connector and you cannot reach an org you do not have
access to — passing an org id you lack access to is refused. The org id comes from this
skill (downloaded for that specific org), not from probing.

> **`check_permission` is a dry-run.** It returns a read-only verdict
> (`allowed` / `requires_approval` / `disabled`) and nothing else — it does NOT
> create an approval request and does NOT return a reference (`REF-…`). The
> approval and its `REF-…` are created later, when you call the gated tool itself
> through oakallow (see the workflow below). One side effect to know: checking a
> tool oakallow has never seen is intentionally not a no-op — oakallow
> auto-creates a gated *draft* entry for that tool with conservative, fail-closed
> defaults so the eventual call is governed and the owner can triage it. An
> unknown tool is never silently trusted, so do not call `check_permission`
> speculatively on tools you have no intention of using.

## Core workflow: a governed action

Follow this sequence whenever you are about to take an action that affects
another system or could be risky or irreversible.

1. **(Optional) `check_permission`** for the action, passing the **`org`** id
   this skill names (see "Targeting the right organization"). This is a dry-run:
   it returns a verdict only and creates nothing.
   - `allowed` then the action is permitted without approval — perform it
     (step 5).
   - `requires_approval` then it is gated — go to step 2 to create the approval.
   - `disabled` / `blocked` then do not perform the action; surface the reason and
     stop. Do not look for a workaround.

2. **Create the approval: call the gated tool itself through oakallow**, passing
   the **`org`** id, the tool's parameters, and a clear **`reason`**. oakallow
   does NOT execute the tool — when it is gated, oakallow creates the approval
   request, notifies a human, and returns a `requires_approval` response carrying
   a **reference (`REF-…`)**. This call is what mints the reference; there is no
   separate "request approval" tool. (If it returns `allowed`, the action was
   permitted — perform it. If `disabled`/`blocked`, stop.)

3. **Wait for the human.** Tell the user an approval was requested and that a
   human approver must decide in the oakallow dashboard or app under enforced
   MFA. Note the **`REF-…`** returned in step 2.

4. **`check_approval_status`** using that reference to poll. Poll politely and do
   not hammer it. When the status resolves:
   - `approved` then perform the action.
   - `denied` then do not perform the action. Report the denial, and the reason
     if one was given, to the user.
   - `expired` then the request timed out without a decision. Do not perform the
     action; offer to re-request if the user still wants it.

5. **Perform the action** on the customer's own system/connector (oakallow does
   not execute customer tools). Each approval authorizes exactly one execution.
   oakallow records an immutable audit row for the outcome.

## Writing the approval reason

When an action requires approval, the human approver sees a **reason**. Make it
genuinely useful, because it is what a person uses to decide in seconds:

- State **what** action you want to take and **on what** (the target or resource).
- State **why**, meaning the user request or investigation that led here.
- Keep it concise and factual. No secrets, no raw credentials, no full tool
  parameters. oakallow only carries a PII-scrubbed reason by design, so do not
  try to smuggle sensitive payloads into the reason text.

Good: "Restart the production payments-api service on host db-3 to clear a stuck
worker queue the user reported at 14:02."

Bad: "Do the thing", or pasting an API key or full request body into the reason.

## Checking on outstanding work

- Use **`list_pending_approvals`** to show the user everything currently awaiting
  a human decision, which is useful when resuming a session or when the user asks
  "what is waiting on me?".
- Use **`check_approval_status`** with a specific reference to poll one request.

## Rules of thumb

- **Ask before acting** on anything risky, irreversible, or cross-system.
- **Respect `blocked` and `denied`.** Never seek a workaround and never retry to
  get a different answer.
- **Never self-approve** or treat the connector as a decision surface. Humans
  decide in the dashboard.
- **Do not speculatively `check_permission`** tools you will not use, because it
  creates gated draft entries that the org owner then has to triage.
- **Be transparent with the user** about what was checked, requested, approved,
  denied, or blocked, and surface the reference.

## Example: end to end

> User: "Delete the abandoned staging-old database."
>
> 1. Agent calls `check_permission` describing: delete database staging-old.
> 2. Verdict is `requires_approval`; oakallow creates a request and notifies a
>    human, returning a reference.
> 3. Agent tells the user: "That is a destructive action, so I have requested
>    approval. A human needs to approve it in oakallow."
> 4. Agent polls `check_approval_status` with the reference until it resolves.
> 5. On `approved`, the agent performs the delete once and reports completion.
>    oakallow writes the audit row.
