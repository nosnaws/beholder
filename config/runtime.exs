import Config

alias Nostrum.Snowflake

token =
  System.get_env("DISCORD_BOT_TOKEN") ||
    raise "environment variable DISCORD_BOT_TOKEN is missing. Check your .env file or export it before starting Beholder."

notification_channel_id =
  System.fetch_env!("NOTIFICATION_CHANNEL_ID")
  |> Snowflake.cast!()

config :nostrum,
  token: token,
  gateway_intents: [
    :guilds,
    :guild_voice_states,
    :guild_messages,
    :message_content
  ],
  num_shards: :auto

config :beholder,
  discord_app_id: System.fetch_env!("DISCORD_APP_ID"),
  discord_public_key: System.fetch_env!("DISCORD_PUBLIC_KEY"),
  notification_channel_id: notification_channel_id
