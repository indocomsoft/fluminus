defmodule Fluminus.Application do
  @moduledoc false

  @fixtures_path Fluminus.Constants.fixtures_path(Mix.env())
  @ets_cassettes_table_name Fluminus.Constants.ets_cassettes_table_name(Mix.env())

  use Application

  def start(_type, args) do
    load_ets()

    children =
      case args do
        [env: :test] ->
          [
            Plug.Cowboy.child_spec(scheme: :http, plug: Fluminus.MockAuthorizationServer, options: [port: 8081]),
            Plug.Cowboy.child_spec(scheme: :http, plug: Fluminus.MockAPIServer, options: [port: 8082])
          ]

        [_] ->
          []
      end

    opts = [strategy: :one_for_one, name: Fluminus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp load_ets do
    :ets.new(@ets_cassettes_table_name, [:named_table])
    :ets.insert(@ets_cassettes_table_name, {Fluminus.MockAPIServer, load_cassettes("api")})
    :ets.insert(@ets_cassettes_table_name, {Fluminus.MockAuthorizationServer, load_cassettes("authorization")})
  end

  defp load_cassettes(directory) do
    "#{@fixtures_path}/#{directory}/**/*.json"
    |> Path.wildcard()
    |> Enum.map(&File.read!/1)
    |> Enum.map(&Jason.decode!/1)
  end
end
