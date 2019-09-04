defmodule Fluminus.Authorization do
  @moduledoc """
  Provides an abstraction over the OpenID Connect flow authorization process as
  used by LumiNUS

  Struct fields:
  * `:client` - the `HTTPClient` containing the cookies to be used to refresh the JWT.
  * `:jwt` - the JWT Bearer token to be used by the API.
  """

  @auth_base_uri Fluminus.Constants.auth_base_uri(Mix.env())
  @vafs_uri Fluminus.Constants.vafs_uri(Mix.env())
  @api_base_uri Fluminus.Constants.api_base_url(Mix.env())
  @discovery_path "/v2/auth/.well-known/openid-configuration"
  @client_id "verso"
  @scope "profile email role openid lms.read calendar.read lms.delete lms.write calendar.write gradebook.write offline_access"
  @response_type "id_token token code"
  @redirect_uri "https://luminus.nus.edu.sg/auth/callback"

  @ocm_apim_subscription_key Fluminus.Constants.ocm_apim_subscription_key(Mix.env())
  @resource "sg_edu_nus_oauth"
  @vafs_client_id "E10493A3B1024F14BDC7D0D8B9F649E9-234390"

  alias Fluminus.HTTPClient

  @type t :: %__MODULE__{jwt: String.t() | nil, client: HTTPClient.t()}
  defstruct jwt: nil, client: %HTTPClient{}

  @doc """
  Creates a new `#{__MODULE__}` struct containing the given JWT and refresh token.
  """
  @spec new(String.t(), String.t()) :: __MODULE__.t()
  def new(jwt, refresh_token) when is_binary(jwt) and is_binary(refresh_token) do
    %__MODULE__{jwt: jwt, client: %HTTPClient{cookies: %{"idsrv" => refresh_token}}}
  end

  @doc """
  Obtains the JWT from a `#{__MODULE__}` struct. Note that the JWT is valid only for 30 minutes.
  """
  @spec get_jwt(__MODULE__.t()) :: String.t() | nil
  def get_jwt(%__MODULE__{jwt: jwt}), do: jwt

  @doc """
  Obtains the refresh token from a `#{__MODULE__}` struct. Note that the refresh token is valid only for 24 hours.
  """
  @spec get_refresh_token(__MODULE__.t()) :: String.t() | nil
  def get_refresh_token(%__MODULE__{client: %HTTPClient{cookies: %{"idsrv" => refresh_token}}}), do: refresh_token

  def get_refresh_token(%__MODULE__{}), do: nil

  @doc """
  Obtains a `#{__MODULE__}` struct containing JWT required for authorization and cookies to refresh JWT.
  Please note that the JWT is only valid for 30 minutes, and the refresh token for 24 hours.

  `username` is the username of your NUSNET account (in the format of e0123456).
  `password` is the password of your NUSNET account.

  ## Examples

      iex> Fluminus.Authorization.jwt("e0123456", "hunter2")
        {:ok,
         %Fluminus.Authorization{
           client: %Fluminus.HTTPClient{
             cookies: %{
               "idsrv" => "Ksxzb3TnGZaxhpzK-Bi9AgkrCxcFNX76bL_IysaLMdOxqSA-FmnT3oEwXeiuOIIkt2buDXcmbhDgGJmfyOoQpUth01_hK0tEdd9ve37VzBQRP32HIVCiE_s7M-vGgTAnxV08NjcQ27CoNeFhD2gZmoU50ncxQFAOtys2x0jD3j80srBITiKU1jJ59RA8Y2UyRqAOgzkk95CvPDpcTsP3g925qJ9JKG0tCZ7TxJ9D0PSeQ-lHfPW8mD_6qzztwr0StiEPaVr-iFzniuixFY82_moVDbzfoSOl2SVNkZlY2d-mY3o6Yt6HH6Jr_uslQXMtsa-1UEQFAP0GAE9RpARSrtA3hx_gsYnujHyIAKrlKTevA7xAAEw97U7Hxs2BAQzVx2P-AGhz-MZ_0AsfwQNC0_4zfw2OVQsYlyLrZoyyoK0"
             }
           },
           jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwNDQxNjcsIm5iZiI6MTU1MjA0Mzg2Nywibm9uY2UiOiJiNjE4ZjE3NzQwYTJlOWM3YjQ2ZjlmMmZmODJiYWQ1YSIsImlhdCI6MTU1MjA0Mzg2NywiYXRfaGFzaCIaIlA5TTF4dU9fNVVrdklXNDdKUHhYYn9iLCJjX2hhc2giOiJzTVZMRVM42Us0VjFIaFlPZmUtenRnIiwic2lkIjoiOTVlNTJjZjI4OTMyNzMyZjRjZjIxMzAxZjQ3NTE3ODQiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWVi2GYiLCJhdXRoX3RpbWUiOjE1NTIwNDM4NjcsImlkcCI6Ikakc3J2IiwiYWRkcmVzayI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.ElRgTpfGJc3np4N37JZZFr_8ZXkuBYjw_vxFxt_GV311gGJlDnh9YDepzWnIsNgtgnuLlkHdb73q9mt2XIcn6YHL0r2kI-CbdKx57aaDfE3-tudRgEv8vXIh53q0Tt61OR5_86qB2qr3QQn0WFvC5VJMYfQ-MJevGrcKFe80vFQPihSHtpznD3G7SyczY3m1yRWsiHNgymvUc4LM5QETOHYv72jDfo7VcxFpscwr4o3os_9fYM_62WuRo7OOL3WdD2XAQB6NGaeakIOQwqMbDSMSvpc0McpGW4uljlmBTiRfzCn7i9bnbfkWLJ5C6mK2o2CWgp1rr2f-HZsIIe-w2Q"
        }}
  """
  @spec jwt(String.t(), String.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_credentials} | {:error, any()}
  @deprecated "Use vafs_jwt/2 instead"
  def jwt(username, password) when is_binary(username) and is_binary(password) do
    with {:ok, %{client: client}, login_uri, xsrf} <- auth_login_info(),
         body <- xsrf |> Map.merge(%{"username" => username, "password" => password}) |> URI.encode_query(),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.post(client, login_uri, body),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location) do
      handle_callback(%__MODULE__{client: client}, location)
    else
      {:ok, _, _, %{status_code: 200}} -> {:error, :invalid_credentials}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Obtains a `#{__MODULE__}` struct containing JWT required for authorization and cookies to refresh JWT. It will be valid for 8 hours and is non-renewable (just like fossil fuels).

  `username` is the username of your NUSNET account (in the format of e0123456).
  `password` is the password of your NUSNET account.

  ## Examples

      iex> Fluminus.Authorization.vafs_jwt("nusstu\\e0123456", "hunter2")
        {:ok,
         %Fluminus.Authorization{
           client: %Fluminus.HTTPClient{
             cookies: %{}
           },
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
         {:ok, %HTTPClient{cookies: cookies}, _, %{status_code: 200, body: adfs_token_result}} <-
           HTTPClient.post(client, Path.join(@api_base_uri, "/login/adfstoken"), adfs_body, [
             {"Ocp-Apim-Subscription-Key", @ocm_apim_subscription_key},
             {"Content-Type", "application/x-www-form-urlencoded"}
           ]),
         {:ok, %{"access_token" => access_token}} <- Jason.decode(adfs_token_result) do
      {:ok, %__MODULE__{jwt: access_token, client: %HTTPClient{cookies: cookies}}}
    else
      {:ok, _, _, %{status_code: 200}} -> {:error, :invalid_credentials}
      {:error, error} -> {:error, error}
      x when is_map(x) -> {:error, :no_code_in_query}
    end
  end

  @doc """
  Renews the JWT of a `#{__MODULE__}` struct containing expired token using the cookies inside the struct.
  Please note that the cookie is only valid for 8 hours.

  ## Examples

      iex> Fluminus.Authorization.renew_jwt(auth)
      {:ok, }
  """
  @spec renew_jwt(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_authorization} | {:error, any()}
  @deprecated "vafs_jwt/2 returns an Authorization that is non-renewable"
  def renew_jwt(auth = %__MODULE__{}) do
    with {:ok, %{client: client}, auth_uri} <- auth_endpoint_uri(auth),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, auth_uri),
         {:ok, auth} <- handle_callback(%__MODULE__{client: client}, location) do
      {:ok, auth}
    else
      {:error, :invalid_callback} -> {:error, :invalid_authorization}
      {:error, error} -> {:error, error}
    end
  end

  @spec handle_callback(__MODULE__.t(), String.t()) :: {:ok, __MODULE__.t()}
  defp handle_callback(%__MODULE__{client: client}, location) when is_binary(location) do
    case URI.parse(location) do
      %{fragment: nil} ->
        {:error, :invalid_callback}

      %{fragment: fragment} ->
        %{"id_token" => id_token} = URI.decode_query(fragment)

        # To refresh the JWT, only `idsrv` cookie is checked by the server
        cookies = %{"idsrv" => client.cookies["idsrv"]}
        {:ok, %__MODULE__{jwt: id_token, client: %HTTPClient{cookies: cookies}}}
    end
  end

  @spec auth_login_info :: {:ok, __MODULE__.t(), String.t(), map()} | {:error, :floki} | {:error, any()}
  defp auth_login_info do
    with {:ok, %{client: client}, auth_uri} <- auth_endpoint_uri(),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, auth_uri),
         {:ok, client, _, %{status_code: 200, body: body}} <- HTTPClient.get(client, location),
         {:floki, [{_, _, [raw_json]}]} <- {:floki, Floki.find(body, "#modelJson")},
         {:ok, parsed} <- raw_json |> String.trim() |> HtmlEntities.decode() |> Jason.decode() do
      full_login_uri = full_auth_uri(parsed["loginUrl"])
      xsrf = %{parsed["antiForgery"]["name"] => parsed["antiForgery"]["value"]}

      {:ok, %__MODULE__{client: client}, full_login_uri, xsrf}
    else
      {:floki, _} -> {:error, :floki}
      {:error, error} -> {:error, error}
    end
  end

  @spec auth_endpoint_uri(__MODULE__.t()) :: {:ok, __MODULE__.t(), String.t()} | {:error, any()}
  defp auth_endpoint_uri(%__MODULE__{client: client} \\ %__MODULE__{}) do
    full_uri = full_auth_uri(@discovery_path)

    with {:ok, client, _, %{status_code: 200, body: body}} <- HTTPClient.get(client, full_uri),
         {:ok, %{"authorization_endpoint" => uri}} <- Jason.decode(body),
         uri_with_params <- auth_endpoint_uri_with_params(uri) do
      {:ok, %__MODULE__{client: client}, uri_with_params}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec auth_endpoint_uri_with_params(String.t()) :: String.t()
  defp auth_endpoint_uri_with_params(uri) do
    [state, nonce] = Stream.repeatedly(fn -> random_hex(16) end) |> Enum.take(2)

    query = %{
      state: state,
      nonce: nonce,
      client_id: @client_id,
      scope: @scope,
      response_type: @response_type,
      redirect_uri: @redirect_uri
    }

    "#{uri}?#{query |> URI.encode_query() |> String.replace("+", "%20")}"
  end

  @spec random_hex(non_neg_integer()) :: String.t()
  defp random_hex(no_of_bytes) when no_of_bytes > 0 do
    :crypto.strong_rand_bytes(no_of_bytes)
    |> Base.encode16()
    |> String.downcase()
  end

  @spec full_auth_uri(String.t()) :: String.t()
  defp full_auth_uri(path) do
    @auth_base_uri |> URI.merge(path) |> URI.to_string()
  end
end
