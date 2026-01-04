# ~/.codex/AGENTS.md

## Working agreements
- Prefer the simplest solution that works. Avoid clever abstractions.
- Make minimal changes. Don’t refactor unrelated code.
- If there’s a choice: clarity > generality > performance.

## Python tooling
- Use uv for running tools (prefer `uv run ...`).
- If a pre-commit hook is installed, use it.
- Tests use pytest. Keep tests small and readable.

## Testing style
- Tests must be interpretable: Arrange / Act / Assert, clear names, no magic.
- Use parametrization when it improves clarity.
