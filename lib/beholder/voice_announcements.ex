defmodule Beholder.VoiceAnnouncements do
  @moduledoc """
  Builds human-friendly messages for voice channel events.
  """

  alias Nostrum.Struct.Event.VoiceState

  @doc """
  Format the message announcing a user joining a voice channel.
  """
  @spec format_join_message(VoiceState.t(), map() | nil) :: String.t()
  def format_join_message(%VoiceState{} = voice_state, channel) do
    "#{member_reference(voice_state)} joined #{channel_reference(channel)}"
  end

  defp member_reference(%VoiceState{user_id: user_id}) when not is_nil(user_id),
    do: "<@#{user_id}>"

  defp member_reference(%VoiceState{member: %{nick: nick}}) when is_binary(nick) and nick != "",
    do: "@#{nick}"

  defp member_reference(_), do: "Someone"

  defp channel_reference(%{id: id}) when not is_nil(id), do: "<##{id}>"

  defp channel_reference(%{name: name}) when is_binary(name) and name != "",
    do: "#!#{name}"

  defp channel_reference(_), do: "a voice channel"
end
