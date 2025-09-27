defmodule Beholder.MixProject do
  use Mix.Project

  def project do
    [
      app: :beholder,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        tidewave:
          "run --no-start --no-halt -e 'Application.ensure_all_started(:bandit); Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Beholder.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:tidewave, "~> 0.5", only: :dev},
      {:bandit, "~> 1.0", only: :dev},
      {:nostrum, "~> 0.10"}
    ]
  end
end
