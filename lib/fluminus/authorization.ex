defmodule Fluminus.Authorization do
  @moduledoc """
  Provides an abstraction over the OpenID Connect flow authorization process as
  used by LumiNUS

  Struct fields:
  * `:jwt` - the JWT Bearer token to be used by the API.
  """

  @vafs_uri Fluminus.Constants.vafs_uri(Mix.env())
  @api_base_uri Fluminus.Constants.api_base_url(Mix.env())
  @redirect_uri "https://luminus.nus.edu.sg/auth/callback"

  @ocm_apim_subscription_key Fluminus.Constants.ocm_apim_subscription_key(Mix.env())
  @resource "sg_edu_nus_oauth"
  @vafs_client_id "E10493A3B1024F14BDC7D0D8B9F649E9-234390"

  alias Fluminus.HTTPClient

  @type t :: %__MODULE__{jwt: String.t() | nil}
  defstruct jwt: nil

  @doc """
  Creates a new `#{__MODULE__}` struct containing the given JWT and refresh token.
  """
  @spec new(String.t()) :: __MODULE__.t()
  def new(jwt) when is_binary(jwt) do
    %__MODULE__{jwt: jwt}
  end

  @doc """
  Obtains the JWT from a `#{__MODULE__}` struct. Note that the JWT is valid only for 30 minutes.
  """
  @spec get_jwt(__MODULE__.t()) :: String.t() | nil
  def get_jwt(%__MODULE__{jwt: jwt}), do: jwt

  @doc """
  Obtains a `#{__MODULE__}` struct containing JWT required for authorization and cookies to refresh JWT. It will be valid for 8 hours and is non-renewable (just like fossil fuels).

  `username` is the username of your NUSNET account (in the format of e0123456).
  `password` is the password of your NUSNET account.

  ## Examples

      iex> Fluminus.Authorization.vafs_jwt("nusstu\\e0123456", "hunter2")
        {:ok,
         %Fluminus.Authorization{
           jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwNDQxNjcsIm5iZiI6MTU1MjA0Mzg2Nywibm9uY2UiOiJiNjE4ZjE3NzQwYTJlOWM3YjQ2ZjlmMmZmODJiYWQ1YSIsImlhdCI6MTU1MjA0Mzg2NywiYXRfaGFzaCIaIlA5TTF4dU9fNVVrdklXNDdKUHhYYn9iLCJjX2hhc2giOiJzTVZMRVM42Us0VjFIaFlPZmUtenRnIiwic2lkIjoiOTVlNTJjZjI4OTMyNzMyZjRjZjIxMzAxZjQ3NTE3ODQiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWVi2GYiLCJhdXRoX3RpbWUiOjE1NTIwNDM4NjcsImlkcCI6Ikakc3J2IiwiYWRkcmVzayI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.ElRgTpfGJc3np4N37JZZFr_8ZXkuBYjw_vxFxt_GV311gGJlDnh9YDepzWnIsNgtgnuLlkHdb73q9mt2XIcn6YHL0r2kI-CbdKx57aaDfE3-tudRgEv8vXIh53q0Tt61OR5_86qB2qr3QQn0WFvC5VJMYfQ-MJevGrcKFe80vFQPihSHtpznD3G7SyczY3m1yRWsiHNgymvUc4LM5QETOHYv72jDfo7VcxFpscwr4o3os_9fYM_62WuRo7OOL3WdD2XAQB6NGaeakIOQwqMbDSMSvpc0McpGW4uljlmBTiRfzCn7i9bnbfkWLJ5C6mK2o2CWgp1rr2f-HZsIIe-w2Q"
        }}
  """
  def vafs_jwt(username, password) when is_binary(username) and is_binary(password) do
    query =
      URI.encode_query(%{
        "response_type" => "code",
        "client_id" => @vafs_client_id,
        "redirect_uri" => @redirect_uri,
        "resource" => @resource
      })

    body = URI.encode_query(%{"UserName" => username, "Password" => password, "AuthMethod" => "FormsAuthentication"})

    uri = @vafs_uri |> URI.parse() |> Map.put(:query, query) |> URI.to_string()

    with {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.post(%HTTPClient{}, uri, body),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location),
         %{query: query} <- URI.parse(location),
         %{"code" => code} <- URI.decode_query(query),
         adfs_body <-
           URI.encode_query(%{
             "grant_type" => "authorization_code",
             "client_id" => @vafs_client_id,
             "resource" => @resource,
             "redirect_uri" => @redirect_uri,
             "code" => code
           }),
         {:ok, _, _, %{status_code: 200, body: adfs_token_result}} <-
           HTTPClient.post(client, Path.join(@api_base_uri, "/login/adfstoken"), adfs_body, [
             {"Ocp-Apim-Subscription-Key", @ocm_apim_subscription_key},
             {"Content-Type", "application/x-www-form-urlencoded"}
           ]),
         {:ok, %{"access_token" => access_token}} <- Jason.decode(adfs_token_result) do
      {:ok, %__MODULE__{jwt: access_token}}
    else
      {:ok, _, _, %{status_code: 200}} -> {:error, :invalid_credentials}
      {:error, error} -> {:error, error}
      x when is_map(x) -> {:error, :no_code_in_query}
    end
  end
end
