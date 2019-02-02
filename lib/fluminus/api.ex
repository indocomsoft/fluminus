defmodule Fluminus.API do
  @moduledoc """
  Provides an abstraction over the LumiNUS API.

  This module is dependent on `Fluminus.Authorization` to authorize to the LumiNUS servers.
  """

  @api_base_url "https://luminus.azure-api.net"
  @ocm_apim_subscription_key "6963c200ca9440de8fa1eede730d8f7e"

  alias Fluminus.API.Module
  alias Fluminus.Authorization

  @doc """
  Returns the name of the user with the given authorization.

  The LumiNUS API returns the name of the user all capitalised, but this function normalises the
  capitalisation to Title Case.

  ## Example

    iex> Fluminus.API.name(authentication)
    "John Smith"
  """
  @spec name(%Authorization{}) :: String.t()
  def name(auth = %Authorization{}) do
    {:ok, result} = api(auth, "/user/Profile")

    result
    |> Map.get("userNameOriginal")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Returns the modules that the user with the given authorization is taking.
  """
  @spec modules(%Authorization{}) :: [%Module{}]
  def modules(auth = %Authorization{}) do
    {:ok, %{"data" => data}} = api(auth, "/module")

    Enum.map(data, &Module.from_api/1)
  end

  @doc """
  Makes a LumiNUS API call with a given authorization, and then parses the JSON response.

  ## Example

      iex> Fluminus.API.api(authorization, "/user/Profile")
      {:ok,
       %{
         "displayPhoto" => true,
         "email" => "e0123456@u.nus.edu",
         "expireDate" => "2018-03-10T01:23:45.67+08:00",
         "id" => "01234567-1c23-5abc-def1-2345ad7efcd2",
         "nickName" => "",
         "officialEmail" => "",
         "userID" => "e0123456",
         "userNameOriginal" => "JOHN SMITH"
       }}
  """
  def api(auth = %Authorization{}, path, method \\ :get, body \\ "", headers \\ %{}) when method in [:get, :post] do
    headers =
      headers
      |> Map.merge(%{
        "Authorization" => "Bearer #{auth.jwt}",
        "Ocp-Apim-Subscription-Key" => @ocm_apim_subscription_key,
        "Content-Type" => "application/json"
      })

    uri = full_api_uri(path)

    case HTTPoison.request(method, uri, body, headers) do
      {:ok, %{status_code: 200, body: body}} -> Jason.decode(body)
      {:ok, response} -> {:error, {:unexpected_content, response}}
      {:error, error} -> {:error, error}
    end
  end

  @spec full_api_uri(String.t()) :: String.t()
  defp full_api_uri(path) do
    @api_base_url |> URI.merge(path) |> URI.to_string()
  end
end
