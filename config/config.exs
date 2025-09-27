import Config

config :beholder, start_tidewave: false

if config_env() == :dev do
  config :beholder, start_tidewave: true
end
