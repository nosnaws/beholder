defmodule Beholder.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Beholder.VoiceTracker,
        Beholder.Consumer
      ]
      |> maybe_add_tidewave()

    Supervisor.start_link(children, strategy: :one_for_one, name: Beholder.Supervisor)
  end

  defp maybe_add_tidewave(children) do
    if Application.get_env(:beholder, :start_tidewave, false) do
      bandit_module = Module.concat([:"Elixir", :Bandit])
      tidewave_module = Module.concat([:"Elixir", :Tidewave])

      if Code.ensure_loaded?(bandit_module) do
        _ = Application.ensure_all_started(:bandit)

        tidewave_child = %{
          id: :tidewave_bandit,
          start: {bandit_module, :start_link, [[plug: tidewave_module, port: 4000]]},
          restart: :permanent,
          shutdown: 500,
          type: :worker
        }

        [tidewave_child | children]
      else
        children
      end
    else
      children
    end
  end
end
