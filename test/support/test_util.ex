defmodule Fluminus.TestUtil do
  @moduledoc false

  alias Plug.Conn

  require Logger

  defp process_conn_member(nil), do: %{}
  defp process_conn_member(%Conn.Unfetched{}), do: %{}
  defp process_conn_member(value), do: value

  defp encode_conn_member(conn = %Conn{}, key) when is_atom(key) do
    conn[key] |> process_conn_member() |> Jason.encode!()
  end

  def log_error(conn = %Conn{}) do
    Logger.error("Please create cassette for this request: #{conn.method} #{conn.request_path}")
    Logger.error("cookies: #{encode_conn_member(conn, :cookies)}")
    Logger.error("body: #{encode_conn_member(conn, :body_params)}")
    Logger.error("query: #{encode_conn_member(conn, :query_params)}")
  end
end
