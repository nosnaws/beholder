# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Beholder is an Elixir-based Discord bot designed to send notifications when someone enters a voice chat. It uses the Nostrum library for Discord API interactions.

## Development Commands

### Build and Dependencies
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project

### Testing
- `mix test` - Run all tests
- `mix test test/beholder_test.exs` - Run a specific test file
- `mix test test/beholder_test.exs:5` - Run test at specific line

### Code Quality
- `mix format` - Format code according to .formatter.exs configuration
- `mix format --check-formatted` - Check if code is properly formatted

### Running the Application
- `iex -S mix` - Start interactive Elixir shell with project loaded
- `mix run --no-halt` - Run the application

## Architecture

### Application Structure
- **OTP Application**: Uses standard Elixir/OTP application structure
- **Entry Point**: `Beholder.Application` starts the supervision tree
- **Main Module**: `Beholder` contains the core functionality
- **Supervisor**: Currently empty, ready for Discord bot workers

### Key Dependencies
- **Nostrum (~> 0.10)**: Discord API library for Elixir
- **Elixir**: ~> 1.18
- **Erlang**: 27.3.4

### Discord Bot Implementation Notes
- The application is set up for Discord integration but core bot functionality needs implementation
- Workers for Discord events should be added to the supervision tree in `lib/beholder/application.ex`
- Nostrum documentation: https://kraigie.github.io/nostrum

## Development Environment
- Uses `.tool-versions` for version management (asdf compatible)
- Formatter configuration in `.formatter.exs`
- Standard ExUnit for testing