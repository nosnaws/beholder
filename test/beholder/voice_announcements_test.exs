defmodule Beholder.VoiceAnnouncementsTest do
  use ExUnit.Case, async: true

  alias Beholder.VoiceAnnouncements
  alias Nostrum.Struct.Event.VoiceState

  test "formats message with mentions when ids are present" do
    voice_state =
      struct!(VoiceState,
        guild_id: 1,
        user_id: 42,
        channel_id: 7,
        member: %{nick: "Watcher"}
      )

    channel = %{id: 99, name: "General"}

    assert VoiceAnnouncements.format_join_message(voice_state, channel) ==
             "<@42> joined <#99>"
  end

  test "falls back to nick when no user id is available" do
    voice_state = struct!(VoiceState, guild_id: 1, user_id: nil, member: %{nick: "Scout"})

    assert VoiceAnnouncements.format_join_message(voice_state, %{name: "War Room"}) ==
             "@Scout joined #!War Room"
  end

  test "uses generic fallback when nothing else is available" do
    assert VoiceAnnouncements.format_join_message(%VoiceState{}, %{}) ==
             "Someone joined a voice channel"
  end
end
