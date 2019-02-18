defmodule Fluminus.MixProject do
  use Mix.Project

  def project do
    [
      app: :fluminus,
      version: "0.1.2",
      elixir: "~> 1.6",
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
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.20.0"},
      {:html_entities, "~> 0.4"},
      {:html_sanitize_ex, "~> 1.3.0"},
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.1"},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A client for the reverse-engineered LumiNUS API (https://luminus.nus.edu.sg)"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/indocomsoft/fluminus"}
    ]
  end
end
