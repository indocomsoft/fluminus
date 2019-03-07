defmodule Fluminus.HTTPClient do
  @moduledoc """
  A HTTP client backed by HTTPoison that manages cookies.

  Struct fields:
  * `:cookies` - cookies stored by this HTTP client.
  """

  @supported_methods ~w(get post)a
  @type methods() :: :get | :post

  @type flattened_headers() :: %{required(String.t()) => String.t()}
  @type headers() :: [{String.t(), String.t()}]

  @type t :: %__MODULE__{cookies: %{required(String.t()) => String.t()}}
  defstruct cookies: %{}

  @spec get(__MODULE__.t(), String.t(), headers()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def get(client = %__MODULE__{}, url, headers \\ []) when is_binary(url) do
    request(client, :get, url, "", headers)
  end

  @spec post(__MODULE__.t(), String.t(), String.t(), headers()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def post(client = %__MODULE__{}, url, body, headers \\ [{"Content-Type", "application/x-www-form-urlencoded"}])
      when is_binary(url) and is_binary(body) do
    request(client, :post, url, body, headers)
  end

  @spec request(__MODULE__.t(), methods(), String.t(), String.t()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def request(client = %__MODULE__{}, method, url, body \\ "", headers \\ [])
      when method in @supported_methods and is_binary(url) and is_binary(body) do
    headers = generate_headers(client, headers)

    case HTTPoison.request(method, url, body, headers, recv_timeout: 10_000) do
      {:ok, response = %HTTPoison.Response{headers: headers}} ->
        updated_client = update_cookies(client, response)
        flattened_headers = Map.new(headers)
        {:ok, updated_client, flattened_headers, response}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec generate_headers(__MODULE__.t(), headers()) :: headers()
  defp generate_headers(%__MODULE__{cookies: cookies}, headers) do
    cookies_string = Cookie.serialize(cookies)

    headers ++
      if(cookies_string != "", do: [{"Cookie", cookies_string}], else: [])
  end

  @spec update_cookies(__MODULE__.t(), HTTPoison.Response.t()) :: __MODULE__.t()
  defp update_cookies(client = %__MODULE__{cookies: cookies}, %HTTPoison.Response{headers: headers}) do
    updated_cookies =
      headers
      |> Enum.filter(fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
      |> Enum.map(fn {_, value} -> value |> SetCookie.parse() |> Map.take([:key, :value]) end)
      |> Enum.reduce(cookies, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

    %__MODULE__{client | cookies: updated_cookies}
  end
end
