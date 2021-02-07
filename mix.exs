defmodule Fluminus.MixProject do
  use Mix.Project

  def project do
    [
      app: :fluminus,
      version: "2.2.9",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/indocomsoft/fluminus",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        dialyzer: :test,
        credo: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [:error_handling, :race_conditions, :underspecs, :unmatched_returns]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Fluminus.Application, [env: Mix.env()]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cookie, "~> 0.1.1"},
      {:ffmpex, "~> 0.7.0"},
      {:floki, "~> 0.30.0"},
      {:html_entities, "~> 0.4"},
      {:html_sanitize_ex, "~> 1.4.0"},
      {:httpoison, "~> 1.4"},
      {:certifi, "~> 2.5"},
      {:jason, "~> 1.1"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:credo, "~> 1.5.0", only: :test, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A library for the reverse-engineered LumiNUS API (https://luminus.nus.edu.sg)"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/indocomsoft/fluminus"}
    ]
  end
end
