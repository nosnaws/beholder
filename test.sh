#!/usr/bin/env bash

set -euo pipefail

# Shell script to run the test suite with minimal required environment.

export DISCORD_BOT_TOKEN="MTIzNDU2Nzg5MDEyMzQ1Njc4.ABCDEF.ABCDEF"
export DISCORD_APP_ID="0"
export DISCORD_PUBLIC_KEY="0"
export NOTIFICATION_CHANNEL_ID="0"

mix test --no-start "$@"
