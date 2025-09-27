defmodule Beholder.VoiceTrackerTest do
  use ExUnit.Case, async: true

  alias Beholder.VoiceTracker
  alias Nostrum.Struct.Event.VoiceState

  setup do
    tracker = start_supervised!({VoiceTracker, seeder: fn -> %{} end})

    {:ok, tracker: tracker}
  end

  test "registers a join when there is no previous channel", %{tracker: tracker} do
    voice_state = voice_state(channel_id: 123)

    assert {:join, 123, true} =
             VoiceTracker.record_transition(voice_state, tracker, now: 0)
  end

  test "returns noop when the user stays in the same channel", %{tracker: tracker} do
    voice_state = voice_state(channel_id: 123)
    VoiceTracker.record_transition(voice_state, tracker, now: 0)

    assert :noop = VoiceTracker.record_transition(voice_state, tracker, now: 1)
  end

  test "tracks leaves after a join", %{tracker: tracker} do
    voice_state = voice_state(channel_id: 123)
    VoiceTracker.record_transition(voice_state, tracker, now: 0)

    leaving_state = voice_state(channel_id: nil)

    assert {:leave, 123} =
             VoiceTracker.record_transition(leaving_state, tracker, now: 1)
  end

  test "tracks moves between channels", %{tracker: tracker} do
    initial_state = voice_state(channel_id: 123)
    moved_state = voice_state(channel_id: 456)

    VoiceTracker.record_transition(initial_state, tracker, now: 0)

    assert {:move, 123, 456} =
             VoiceTracker.record_transition(moved_state, tracker, now: 1)
  end

  test "ignores events without guild or user ids", %{tracker: tracker} do
    assert :ignore =
             VoiceTracker.record_transition(
               %VoiceState{guild_id: nil, user_id: 1, channel_id: 2},
               tracker
             )

    assert :ignore =
             VoiceTracker.record_transition(
               %VoiceState{guild_id: 1, user_id: nil, channel_id: 2},
               tracker
             )
  end

  test "suppresses joins within the cooldown window", %{tracker: tracker} do
    join = voice_state(channel_id: 123)
    leave = voice_state(channel_id: nil)

    assert {:join, 123, true} = VoiceTracker.record_transition(join, tracker, now: 0)
    assert {:leave, 123} = VoiceTracker.record_transition(leave, tracker, now: 60)
    assert {:join, 123, false} = VoiceTracker.record_transition(join, tracker, now: 120)
  end

  test "resumes notifications once the cooldown expires", %{tracker: tracker} do
    join = voice_state(channel_id: 123)
    leave = voice_state(channel_id: nil)

    assert {:join, 123, true} = VoiceTracker.record_transition(join, tracker, now: 0)
    assert {:leave, 123} = VoiceTracker.record_transition(leave, tracker, now: 60)
    assert {:join, 123, false} = VoiceTracker.record_transition(join, tracker, now: 120)
    assert {:leave, 123} = VoiceTracker.record_transition(leave, tracker, now: 150)
    assert {:join, 123, true} = VoiceTracker.record_transition(join, tracker, now: 400)
  end

  defp voice_state(opts) do
    defaults = [guild_id: 1, user_id: 2]

    struct!(VoiceState, Keyword.merge(defaults, opts))
  end
end
