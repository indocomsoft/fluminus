defmodule Fluminus.MockAuthorizationServer do
  use Plug.Router

  alias Plug.Conn

  require Logger

  @fixtures_path Application.get_env(:fluminus, :fixtures_path) |> Path.join("authorization")
  @cassettes Path.wildcard("#{@fixtures_path}/**/*.json") |> Enum.map(&File.read!/1) |> Enum.map(&Jason.decode!/1)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  match _ do
    conn = conn |> Conn.fetch_cookies() |> Conn.fetch_query_params()

    cassette = find_casette(conn)

    if cassette do
      response = cassette["response"]

      response["headers"]
      |> Enum.reduce(conn, fn [key, value], acc ->
        Conn.put_resp_header(acc, key, value)
      end)
      |> Conn.resp(response["status_code"], response["body"])
    else
      error(conn)
      conn
    end
  end

  defp find_casette(conn) do
    Enum.find(@cassettes, fn %{"request" => request} ->
      request["request_path"] == conn.request_path and
        request["method"] == conn.method and
        (request["cookies"] || %{}) == conn.cookies and
        (request["body"] || %{}) == conn.body_params and
        Enum.all?(request["query"] || %{}, fn {key, value} -> Map.get(conn.query_params, key) == value end)
    end)
  end

  defp error(conn) do
    Logger.error("Please create cassette for this request: #{conn.method} #{conn.request_path}")
    Logger.error("cookies: #{Jason.encode!(conn.cookies)}")
    Logger.error("body: #{Jason.encode!(conn.body_params)}")
    Logger.error("query: #{Jason.encode!(conn.query_params || %{})}")
  end
end
