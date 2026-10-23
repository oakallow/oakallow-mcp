# Contributing

Thanks for your interest in Oakallow.

## What this repository is

This repository is the public listing for the Oakallow MCP server. It holds the files that
describe and connect to the hosted server:

1. `server.json`, the MCP Registry entry for `io.github.oakallow/oakallow`.
2. `README.md`, `SKILL.md`, and `PROMPT.md`, which document the connector, the agent
   skill, and trigger prompts.
3. `tools.json`, a snapshot of the standard tools as `tools/list` returns them.
4. `examples/`, which has client configuration and walkthroughs of the OAuth and
   `oak_agent_` token flows.

The server itself is hosted at `https://api.oakallow.io/mcp`. Its source is not in this
repository, so pull requests cannot change server behavior.

## Ways to help

1. **Report a documentation problem.** If something here does not match what the live
   server does, or an example fails, open an issue using the "Documentation or example
   problem" template. Include the client you used and what you expected to happen.
2. **Report a connector problem.** If connecting or calling a tool fails, open an issue
   using the "Connector problem" template. Include the MCP client, the time it happened,
   and any `REF-…` or decision receipt reference you received.
3. **Suggest an improvement.** Clearer wording, a missing example, or a client
   configuration we do not cover yet are all welcome as issues or pull requests.

For account, billing, or org setup questions, email support@oakallow.io instead of opening
an issue. For anything security related, follow [SECURITY.md](./SECURITY.md) and do not
open a public issue.

## Pull requests

Pull requests that improve the documentation and examples are welcome.

1. Keep changes focused. One topic per pull request is easiest to review.
2. Check behavior against the live endpoint before documenting it. If you are unsure how
   the server behaves, open an issue first and ask.
3. Never commit credentials. Use placeholders such as `<access_token>` or
   `oak_agent_...` in examples, and do not paste real tokens, client secrets, org ids, or
   approval references from a real account.
4. Do not change `version` in `server.json`. Releases are cut by the maintainers when a
   new version is published to the MCP Registry.

By submitting a pull request, you agree that your contribution is licensed under the
[MIT License](./LICENSE) that covers this repository.

## Code of conduct

Everyone taking part in this project is expected to follow the
[Code of Conduct](./CODE_OF_CONDUCT.md).
