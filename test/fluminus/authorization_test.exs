defmodule Fluminus.AuthorizationTest do
  use ExUnit.Case, async: true

  @port Application.get_env(:fluminus, :port)
  @fixtures_path Application.get_env(:fluminus, :fixtures_path) |> Path.join("authorization")
  @cassettes @fixtures_path
             |> File.ls!()
             |> Enum.filter(&String.ends_with?(&1, ".json"))
             |> Enum.map(&Path.join(@fixtures_path, &1))
             |> Enum.map(&File.read!/1)
             |> Enum.map(&Jason.decode!/1)
  @idsrv "Ywnb0vX7NMtrerdyfJsdSQmn5b0U44QTOxaQTazUU2plr9z3mZr_tXbxKQqwzHUEv14qZCkOu349j8JsTi8A7ePLpBi2l7CiVBvoV5lB6ufTBgamnp9_1dqxxZwg30VPC2sGvmlndzXo9Iz-LQK3FQi2sKNnW_MnokhKfmRI5rQszRIyxJl0fzr-sT9vTTH5FE8GK7mJ5oFTYpcsukHkEuZlfCmzA8SQ1wwOMzg3gr_KOpakzDgUsQrjubhedDWbkdIm0LpCSp4nWJdwO270mSZjrdf3MNSscIpCRRVvqb4MnaMvcBSgZTOjgm4YfDSgCyPVh4AKFaofuPYSwab2qq-ZqkbS7dRiGiCHBA62PiYoR8xm-QJor7XkqkQM_nxiGLBpvQeqF0J3z77H2Sgiwg"

  alias Fluminus.{Authorization, HTTPClient}
  alias Plug.Conn

  require Logger

  setup do
    bypass = Bypass.open(port: @port)
    Bypass.expect(bypass, &handle_conn/1)
    {:ok, bypass: bypass}
  end

  test "jwt happy path" do
    {:ok, auth} = Authorization.jwt("e0123456", "hunter2")

    assert auth.jwt ==
             "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjAzNDU4NCwibm9uY2UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYWtWQV8tMjA2Q1EiLCJjX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"

    assert auth.client.cookies["idsrv"] == @idsrv
  end

  test "jwt invalid credentials" do
    {:error, :invalid_credentials} = Authorization.jwt("e1234567", "wrongpassword")
  end

  test "renew_jwt happy path" do
    auth = %Authorization{jwt: @id_token, client: %HTTPClient{cookies: %{"idsrv" => @idsrv}}}
    {:ok, auth} = Authorization.renew_jwt(auth)

    assert auth.jwt ==
             "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjA5NDU4NCwibm9uY5UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYW5WQV8tMjA2Q1EiLC5jX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"
  end

  defp handle_conn(conn) do
    conn = conn |> Conn.fetch_cookies() |> Conn.fetch_query_params()

    {:ok, body, conn} = Conn.read_body(conn)
    body = if body != "", do: URI.decode_query(body), else: %{}

    cassette =
      Enum.find(@cassettes, fn %{"request" => request} ->
        request["request_path"] == conn.request_path and
          request["method"] == conn.method and
          (request["cookies"] || %{}) == conn.cookies and
          (request["body"] || %{}) == body and
          Enum.all?(request["query"] || %{}, fn {key, value} -> Map.get(conn.query_params, key) == value end)
      end)

    if cassette do
      response = cassette["response"]

      response["headers"]
      |> Enum.reduce(conn, fn [key, value], acc ->
        Conn.put_resp_header(acc, key, value)
      end)
      |> Conn.resp(response["status_code"], response["body"])
    else
      Logger.error("Please create cassette for this request: #{conn.method} #{conn.request_path}")
      Logger.error("cookies: #{Jason.encode!(conn.cookies)}")
      Logger.error("body: #{Jason.encode!(body)}")
      Logger.error("query: #{Jason.encode!(conn.query_params || %{})}")
      conn
    end
  end
end
