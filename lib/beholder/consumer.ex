defmodule Beholder.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api.Message, as: MessageApi
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.Event.VoiceState

  alias Beholder.VoiceAnnouncements
  alias Beholder.VoiceTracker

  require Logger

  @impl true
  def handle_event({:MESSAGE_CREATE, %Message{author: %{bot: true}}, _ws_state}), do: :ignore

  def handle_event({:MESSAGE_CREATE, %Message{} = msg, _ws_state}) do
    case String.trim(msg.content) do
      "!ping" ->
        respond_with_pong(msg)

      _ ->
        :ignore
    end
  end

  def handle_event({:VOICE_STATE_UPDATE, %VoiceState{} = voice_state, _ws_state}) do
    maybe_notify_voice_join(voice_state)
    :ok
  end

  def handle_event(_event), do: :ignore

  defp respond_with_pong(%Message{channel_id: channel_id}) do
    case MessageApi.create(channel_id, "Pong!") do
      {:ok, _message} ->
        :ok

      {:error, reason} ->
        Logger.warning("Unable to send pong response: #{inspect(reason)}")
    end
  end

  defp maybe_notify_voice_join(%VoiceState{channel_id: nil} = voice_state) do
    _ = VoiceTracker.record_transition(voice_state)
    :ignore
  end

  defp maybe_notify_voice_join(%VoiceState{} = voice_state) do
    case VoiceTracker.record_transition(voice_state) do
      {:join, channel_id, true} ->
        notify_join(voice_state, channel_id)

      {:join, _channel_id, false} ->
        :ignore

      _ ->
        :ignore
    end
  end

  defp notify_join(%VoiceState{} = voice_state, channel_id) do
    notification_channel_id = notification_channel_id()

    channel =
      case channel_for(voice_state.guild_id, channel_id) do
        {:ok, chan} -> chan
        {:error, _reason} -> %{id: channel_id}
      end

    message = VoiceAnnouncements.format_join_message(voice_state, channel)

    case MessageApi.create(notification_channel_id, message) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.warning("Unable to send voice join notification: #{inspect(reason)}")
    end
  end

  defp channel_for(nil, _channel_id), do: {:error, :unknown_guild}

  defp channel_for(guild_id, channel_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        case Map.get(guild.channels, channel_id) do
          nil ->
            Logger.warning("Channel #{channel_id} missing from cache for guild #{guild_id}")
            {:ok, %{id: channel_id}}

          channel ->
            {:ok, channel}
        end

      {:error, reason} ->
        Logger.warning("Unable to load guild #{guild_id} from cache: #{inspect(reason)}")
        {:ok, %{id: channel_id}}
    end
  end

  defp notification_channel_id do
    Application.fetch_env!(:beholder, :notification_channel_id)
  end
end
