defmodule Fluminus.MockAPIServer do
  @moduledoc false

  use Plug.Router

  alias Plug.Conn

  require Logger

  @ocm_apim_subscription_key Application.get_env(:fluminus, :ocm_apim_subscription_key)
  @id_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjAzNDU4NCwibm9uY2UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYWtWQV8tMjA2Q1EiLCJjX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"
  @ets_cassettes_table_name Application.get_env(:fluminus, :ets_cassettes_table_name)

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
      if cassette["request"]["allowWithoutAuthorization"] ||
           (Conn.get_req_header(conn, "authorization") == ["Bearer #{@id_token}"] and
              Conn.get_req_header(conn, "ocp-apim-subscription-key") == [@ocm_apim_subscription_key]) do
        response = cassette["response"]

        response["headers"]
        |> Enum.reduce(conn, fn [key, value], acc ->
          Conn.put_resp_header(acc, key, value)
        end)
        |> Conn.resp(response["status_code"], response["body"])
      else
        Conn.send_resp(conn, 401, "")
      end
    else
      error(conn)
      conn
    end
  end

  defp find_casette(conn) do
    [{__MODULE__, cassettes}] = :ets.lookup(@ets_cassettes_table_name, __MODULE__)

    Enum.find(cassettes, fn %{"request" => request} ->
      request["request_path"] == conn.request_path and
        request["method"] == conn.method and
        (request["cookies"] || %{}) == conn.cookies and
        (request["body"] || %{}) == conn.body_params and
        Enum.all?(request["query"] || %{}, fn {key, value} -> Map.get(conn.query_params, key) == value end)
    end)
  end

  defp error(conn) do
    Logger.error("Please create cassette for this request: #{conn.method} #{conn.request_path}")
    Logger.error("cookies: #{Jason.encode!(conn.cookies || %{})}")
    Logger.error("body: #{Jason.encode!(conn.body_params || %{})}")
    Logger.error("query: #{Jason.encode!(conn.query_params || %{})}")
  end
end
