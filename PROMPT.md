# oakallow trigger prompts

`SKILL.md` is the **procedure**: it tells an agent how to route a governed
action through oakallow (check, wait for approval, then act). But a skill only
engages when the model decides it is relevant. To make that reliable, give the
agent a short standing instruction in its system prompt that points it at the
skill. That instruction is the **trigger**; the skill is what it consults.

> Prompt = the trigger that makes the agent look. Skill = the source of truth
> for which tools need the gate. Use both together.

Paste one of the one-liners below into your agent's system prompt (Claude Cowork
project instructions, ChatGPT custom instructions, or any host's standing
instructions). The skill itself decides which specific tools require a check, so
the prompt stays short and does not need a tool list.

## Pick one trigger prompt

### 1. Gate everything (strictest)

The agent checks before every tool call. Highest assurance; read-only lookups
also route through a check.

```
Before every tool call, consult the oakallow gate skill and run the action through an oakallow permission check first.
```

### 2. Let the skill decide (recommended default)

The skill says which tools are governed; read-only work runs normally.

```
Use the oakallow gate skill where it applies: check each tool against the skill, and route any governed action through an oakallow permission check before executing.
```

### 3. Gate a named set

You name the action categories. Caught even before those tools are registered in
oakallow. Edit the bracketed list to match your risk surface, and refresh the
skill after registering new tools so it stays accurate.

```
For any [refund, cancellation, payment, or deletion] action, use the oakallow gate skill and run an oakallow permission check before executing, even if the tool is not listed yet. Refresh the skill after adding tools.
```

## Using it in a real request

You do not have to restate the rule on every message once the trigger prompt is
in the system prompt. But you can also name oakallow inline in a task when you
want to be explicit. The pattern is **[the task] + [the oakallow routing
instruction]**:

> Check the refund requests in our Shopify queue and decide which are valid.
> Before acting on any of them, follow the oakallow gate skill and run each
> through a permission check first.

> Cancel order #1234. Use the oakallow gate skill before executing.

> Clean up the inactive users. Route every deletion through oakallow for
> approval per the oakallow gate skill.

## How the flow runs

With a trigger prompt in place, a governed request flows like this:

1. The agent reads the trigger prompt and consults the oakallow gate skill.
2. For a governed action it calls `check_permission` with the tool name, a short
   reason, and a reference id.
3. On `requires_approval` it stops and waits; a human decides on an MFA-bound
   surface (the oakallow dashboard or mobile app).
4. On `approved` (or an immediate `allowed`) it performs the action once.
5. oakallow records an immutable audit row.

See `SKILL.md` for the full procedure, the tool reference, and how to write a
good approval reason. Humans define the tools, the rules, and the approvals in
the oakallow dashboard; the prompt and skill only tell the agent how to behave
inside that governance.

- **Endpoint:** `https://api.oakallow.io/mcp`
- **Website:** https://oakallow.com
