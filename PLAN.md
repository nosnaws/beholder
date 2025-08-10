# Summary

Create a Discord bot that sends notifications to a specific text channel when a user joins a voice channel.

## Requirements
- Should be stateless (in memory is fine).
- It only needs to support one server.
- It should be configurable:
    - The channel to send notifications to.
    - The voice channels to monitor. (all by default).
- It should have commands to configure the bot via discord.
- It should use the Nostrum library for Discord interactions.
- It should handle being added to a server and removed from a server.
- It should environment variables for token configuration.

## Code Requirements
- Use the Nostrum library for Discord interactions.
- Follow Elixir conventions.
- Use base Elixir libraries and avoid external dependencies.
- Use modern Elixir typing.
- Include logging of important interactions, but don't over do it (don't log on every event).

