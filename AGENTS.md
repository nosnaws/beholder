# Repository Guidelines

## Project Structure & Module Organization
- `lib/beholder` contains runtime modules (`application.ex` supervises processes, `consumer.ex` handles Discord gateway events).
- `lib/beholder.ex` exposes the public application API.
- `config` holds compile/runtime settings; `runtime.exs` expects Discord credentials from the environment.
- `test` mirrors `lib` for ExUnit; create helpers under `test/support` when the suite expands.
- `start.sh` loads `.env` and launches `iex -S mix` for local bot runs—keep it executable.

## Build, Test, and Development Commands
- `mix deps.get` installs dependencies after cloning or when `mix.exs` / `mix.lock` changes.
- `mix compile` checks the project builds and surfaces warnings early.
- `./test.sh` runs the ExUnit suite with stub Discord credentials and `mix test --no-start`; use this whenever network or sandbox policies would block Mix.PubSub's TCP listener. Fall back to `mix test` only when you need to boot the full supervision tree.
- `mix format` enforces style; run before commits to normalize whitespace.
- `./start.sh` boots the bot with exported credentials; use it for manual Discord verification.

## Coding Style & Naming Conventions
- Use snake_case for functions/variables and PascalCase for modules.
- Favor pattern matching and pure functions; reserve comments for non-obvious control flow.
- Stick with two-space indentation and rely on `mix format` to clean up formatting.

## Testing Guidelines
- Write ExUnit cases in `*_test.exs` files with intent-revealing `test "..."` names.
- Cover new event-handling branches by simulating Nostrum payloads or helper factories.
- Keep assertions deterministic; avoid relying on live Discord services.

## Commit & Pull Request Guidelines
- Craft concise, imperative commit subjects (<50 chars, e.g., `Add voice join notifier`).
- Add bodies when behavior or configuration changes, including testing notes (`mix test`, manual steps).
- Pull requests should link issues, summarize impact, and attach evidence (logs, screenshots) for user-visible changes.

## Tidewave MCP Tools
- These tools are available directly to agents; invoke them whenever you need project context without editing files.
- `tidewave__get_docs` surfaces inline docs for modules/functions (e.g., `Beholder.Application`). Use it before diving into source.
- `tidewave__get_source_location` returns file and line numbers so you can jump straight to relevant code.
- `tidewave__project_eval` runs short Elixir snippets in the project environment; keep evaluations deterministic and idempotent.
- `tidewave__get_logs` tails application output—useful when debugging gateway events or supervision restarts.
- `tidewave__search_package_docs` queries dependency guides (e.g., Nostrum) without leaving the terminal.

## Security & Configuration Tips
- Keep `.env` out of version control; update `.env.example` whenever new variables are required.
- Revoke and regenerate Discord tokens immediately if leaked; rotate secrets in the Developer Portal.
