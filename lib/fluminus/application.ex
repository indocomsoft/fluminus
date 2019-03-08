defmodule Fluminus.Application do
  use Application

  def start(_type, args) do
    children =
      case args do
        [env: :test] ->
          [
            {Plug.Cowboy, scheme: :http, plug: Fluminus.MockAuthorizationServer, options: [port: 8081]},
            {Plug.Cowboy, scheme: :http, plug: Fluminus.MockAPIServer, options: [port: 8082]}
          ]

        [_] ->
          []
      end

    opts = [strategy: :one_for_one, name: Fluminus.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
