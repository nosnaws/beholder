# Beholder

## Project description
A Discord bot that watches voice channel activity and posts join events into a text channel.
It is built with [Nostrum](https://github.com/Kraigie/nostrum) and is set up for future Phoenix-based web extensions.

## Requirements
- Elixir 1.18.4 and Erlang/OTP 27.3.4 (see `.tool-versions` for exact versions).
- Discord application credentials with a bot user and gateway intents for guilds, guild messages, and message content.
- A text channel ID to receive notifications.

## Installation
1. Install the required Erlang and Elixir toolchain (e.g. with [`asdf`](https://asdf-vm.com/)).
2. Fetch Elixir dependencies: `mix deps.get`.
3. Create a `.env` file using the provided template and fill in:
   - `DISCORD_APP_ID`
   - `DISCORD_PUBLIC_KEY`
   - `DISCORD_BOT_TOKEN`
   - `NOTIFICATION_CHANNEL_ID`

## Development
- Compile as you work with `mix compile` (or let `iex -S mix` compile on start).
- Run the test suite with `./test.sh`, which seeds stub Discord credentials and calls `mix test --no-start` so Mix.PubSub does not attempt to open a TCP socket. Use `mix test` directly if you specifically need the supervision tree running.
- Format code before committing with `mix format`.
- Launch an interactive session with all applications running via `iex -S mix`.

## Starting the bot
1. Ensure `start.sh` is executable: `chmod +x start.sh`.
2. Confirm your `.env` file contains the required Discord credentials.
3. Start the bot with `./start.sh`; the script loads `.env`, exports the variables, and runs `iex -S mix`.
   - Alternatively, export the same variables in your shell and run `mix run --no-halt`.
