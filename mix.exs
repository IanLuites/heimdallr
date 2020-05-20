defmodule Heimdallr.MixProject do
  use Mix.Project

  def project do
    [
      app: :heimdallr,
      version: "0.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Heimdallr.Application, []}
    ]
  end

  defp deps do
    [
      {:analyze, "~> 0.1.12"},
      {:file_system, "~> 0.2.8"}
    ]
  end
end
