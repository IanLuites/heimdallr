defmodule Heimdallr.MixProject do
  use Mix.Project

  def project do
    [
      app: :heimdallr,
      version: "0.0.1",
      description: "Hot code reload with code analysis application.",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [ignore_warnings: ".dialyzer", plt_add_deps: true],

      # Docs
      name: "Heimdallr",
      source_url: "https://github.com/IanLuites/heimdallr",
      homepage_url: "https://github.com/IanLuites/heimdallr",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :heimdallr,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/heimdallr",
        "lib/heimdallr.ex",
        ".formatter.exs",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/heimdallr"
      }
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
