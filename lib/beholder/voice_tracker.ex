defmodule Beholder.VoiceTracker do
  @moduledoc """
  Tracks per-user voice state transitions so we can detect first joins.
  """

  use Agent

  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Event.VoiceState

  @typedoc """
  Return value describing how the user's voice state changed.
  """
  @type transition ::
          {:join, Nostrum.Struct.Channel.id(), boolean()}
          | {:move, Nostrum.Struct.Channel.id(), Nostrum.Struct.Channel.id()}
          | {:leave, Nostrum.Struct.Channel.id() | nil}
          | :noop
          | :ignore

  @cooldown_seconds 300

  @typep user_entry :: %{
           channel_id: Nostrum.Struct.Channel.id() | nil,
           last_notified_at: non_neg_integer() | nil
         }

  @doc """
  Starts the tracker, optionally with a custom seeder and name for testing.
  """
  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    seeder = Keyword.get(opts, :seeder, &seed_from_cache/0)

    Agent.start_link(fn -> seeder.() end, name: name)
  end

  @doc """
  Record the latest voice state and return how it changed relative to the cache.

  Accepts an optional tracker name, useful for isolated tests.
  """
  @spec record_transition(VoiceState.t(), GenServer.name()) :: transition
  @spec record_transition(VoiceState.t(), GenServer.name(), keyword()) :: transition
  def record_transition(%VoiceState{} = voice_state, tracker_name \\ __MODULE__) do
    record_transition(voice_state, tracker_name, [])
  end

  def record_transition(%VoiceState{} = voice_state, tracker_name, opts) when is_list(opts) do
    now = Keyword.get(opts, :now, current_time())

    with {:ok, key} <- tracker_key(voice_state) do
      Agent.get_and_update(tracker_name, fn state ->
        {previous_entry, state_after_prune} = pop_if_expired(state, key, now)

        previous_channel_id = entry_channel(previous_entry)
        current_channel_id = voice_state.channel_id

        base_transition = classify_transition(previous_channel_id, current_channel_id)

        {transition, updated_entry} =
          apply_transition(base_transition, previous_entry, current_channel_id, now)

        next_state = persist_entry(state_after_prune, key, updated_entry, now)

        {transition, next_state}
      end)
    else
      :error -> :ignore
    end
  end

  defp tracker_key(%VoiceState{guild_id: nil}), do: :error
  defp tracker_key(%VoiceState{user_id: nil}), do: :error

  defp tracker_key(%VoiceState{guild_id: guild_id, user_id: user_id}),
    do: {:ok, {guild_id, user_id}}

  defp entry_channel(nil), do: nil
  defp entry_channel(%{channel_id: channel_id}), do: channel_id

  defp pop_if_expired(state, key, now) do
    case Map.get(state, key) do
      nil ->
        {nil, state}

      entry ->
        if stale_entry?(entry, now) do
          {nil, Map.delete(state, key)}
        else
          {entry, state}
        end
    end
  end

  defp persist_entry(state, key, nil, _now), do: Map.delete(state, key)

  defp persist_entry(state, key, entry, now) do
    if drop_after_transition?(entry, now) do
      Map.delete(state, key)
    else
      Map.put(state, key, entry)
    end
  end

  defp classify_transition(nil, nil), do: :noop

  defp classify_transition(nil, channel_id) when not is_nil(channel_id) do
    {:join, channel_id}
  end

  defp classify_transition(previous, nil), do: {:leave, previous}
  defp classify_transition(previous, previous), do: :noop
  defp classify_transition(previous, channel_id), do: {:move, previous, channel_id}

  defp apply_transition(:noop, previous_entry, _channel_id, _now), do: {:noop, previous_entry}

  defp apply_transition({:leave, channel_id}, previous_entry, _channel_id, _now) do
    entry = update_entry(previous_entry, nil, previous_entry_last_notified(previous_entry))

    {{:leave, channel_id}, entry}
  end

  defp apply_transition({:move, from_channel, to_channel}, previous_entry, _channel_id, _now) do
    entry = update_entry(previous_entry, to_channel, previous_entry_last_notified(previous_entry))

    {{:move, from_channel, to_channel}, entry}
  end

  defp apply_transition({:join, channel_id}, previous_entry, channel_id, now) do
    should_notify? = should_notify_join?(previous_entry, now)

    last_notified_at =
      if should_notify? do
        now
      else
        previous_entry_last_notified(previous_entry)
      end

    entry = update_entry(previous_entry, channel_id, last_notified_at)

    {{:join, channel_id, should_notify?}, entry}
  end

  defp should_notify_join?(nil, _now), do: true
  defp should_notify_join?(%{last_notified_at: nil}, _now), do: true

  defp should_notify_join?(%{last_notified_at: last_notified_at}, now) do
    now - last_notified_at >= @cooldown_seconds
  end

  defp update_entry(nil, channel_id, last_notified_at) do
    %{channel_id: channel_id, last_notified_at: last_notified_at}
  end

  defp update_entry(entry, channel_id, last_notified_at) do
    Map.merge(entry, %{channel_id: channel_id, last_notified_at: last_notified_at})
  end

  defp previous_entry_last_notified(nil), do: nil

  defp previous_entry_last_notified(%{last_notified_at: last_notified_at}), do: last_notified_at

  defp stale_entry?(%{channel_id: nil, last_notified_at: nil}, _now), do: true

  defp stale_entry?(%{channel_id: nil, last_notified_at: last_notified_at}, now) do
    now - last_notified_at >= @cooldown_seconds
  end

  defp stale_entry?(_entry, _now), do: false

  defp drop_after_transition?(%{channel_id: nil, last_notified_at: nil}, _now), do: true

  defp drop_after_transition?(%{channel_id: nil, last_notified_at: last_notified_at}, now) do
    now - last_notified_at >= @cooldown_seconds
  end

  defp drop_after_transition?(_entry, _now), do: false

  defp current_time do
    System.system_time(:second)
  end

  defp seed_from_cache do
    GuildCache.wrap_query(fn ->
      GuildCache.all()
      |> Enum.reduce(%{}, fn guild, acc ->
        voice_states = Map.get(guild, :voice_states) || []

        Enum.reduce(voice_states, acc, fn state, inner_acc ->
          user_id = Map.get(state, :user_id)
          channel_id = Map.get(state, :channel_id)

          if is_nil(user_id) or is_nil(channel_id) do
            inner_acc
          else
            Map.put(inner_acc, {guild.id, user_id}, %{
              channel_id: channel_id,
              last_notified_at: nil
            })
          end
        end)
      end)
    end)
  end
end
