# Security Policy

Oakallow is a security product, so we take reports about it seriously. Thank you for
helping keep agents and the people who approve their actions safe.

## Reporting a vulnerability

Email **security@oakallow.io**. Please do not open a public GitHub issue, discussion, or
pull request for a suspected vulnerability.

Include as much of the following as you can:

1. What you found and why you believe it is a security issue.
2. The affected surface (see Scope below) and the steps to reproduce it.
3. Any request IDs, approval references (`REF-…`), or decision receipt references
   involved, and the time it happened (with time zone).
4. The impact you expect: for example, an agent acting without approval, one org reaching
   another org's data, or a token that outlives its revocation.

Never include live credentials in a report. Redact access tokens, refresh tokens,
`oak_agent_` tokens, and API keys. If we need one to reproduce the issue, we will ask
for a fresh test credential that you can revoke afterwards.

We will acknowledge your report, keep you informed while we investigate, and let you know
when it is resolved. Please give us a reasonable chance to fix the issue before you
disclose it publicly.

## Scope

In scope:

1. The hosted MCP endpoint, `https://api.oakallow.io/mcp`.
2. The OAuth 2.1 authorization server on `api.oakallow.io` (discovery metadata and the
   authorization, token, client registration, and revocation endpoints).
3. `oak_agent_` token authentication and its per-org scoping.
4. Approval flows: anything that lets an action run without the required human approval,
   lets an approval be reused, or lets an agent approve its own request.
5. Signed decision receipts: forging, altering, or replaying a receipt.
6. OakGuard gateway: anything that exposes stored downstream credentials or leaks
   request or response payloads.
7. The oakallow dashboard and mobile apps.

Out of scope:

1. Denial of service, load testing, or volumetric attacks.
2. Social engineering, phishing, or physical attacks against oakallow staff or customers.
3. Vulnerabilities in a customer's own MCP servers or tools, including servers a
   customer has connected through OakGuard. Report those to the server's owner.
4. Reports that only show missing best-practice headers or software version banners,
   with no demonstrated impact.

## Testing guidelines

Use only accounts and orgs you own. Do not access, modify, or delete data that belongs to
anyone else, and stop as soon as you have confirmed an issue. Do not run automated
scanners against the production endpoint at a volume that could affect other users.

## Supported versions

Oakallow is a hosted service, so there is a single supported version: the one running at
`https://api.oakallow.io/mcp`. Fixes are deployed there directly; there is nothing to
upgrade on your side. This repository holds the public listing and documentation, not the
server source.

## Other contacts

1. Privacy requests: privacy@oakallow.io
2. Product support: support@oakallow.io
3. Privacy Policy: https://oakallow.io/privacy
4. Terms of Service: https://oakallow.io/terms
