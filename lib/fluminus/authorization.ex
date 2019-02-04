defmodule Fluminus.Authorization do
  @moduledoc """
  Provides an abstraction over the OpenID Connect flow authorization process as
  used by LumiNUS

  Struct fields:
  * `:cookies` - cookies that needs to be sent to the server
  * `:jwt` - contains the JWT to be used for authorization to the server
  """

  @auth_base_uri "https://luminus.nus.edu.sg"
  @discovery_path "/v2/auth/.well-known/openid-configuration"
  @client_id "verso"
  @scope "profile email role openid lms.read calendar.read lms.delete lms.write calendar.write gradebook.write offline_access"
  @response_type "id_token token code"
  @redirect_uri "https://luminus.nus.edu.sg/auth/callback"

  @type t :: %__MODULE__{cookies: %{required(String.t()) => String.t()}, jwt: String.t() | nil}
  defstruct cookies: %{}, jwt: nil

  @doc """
  Obtains a `#{__MODULE__}` struct containing JWT required for authorization and cookies to refresh JWT.
  Please note that the JWT is usually only valid for 1 hour, and the cookies for 24 hours.

  `username` is the username of your NUSNET account (in the format of e0123456).
  `password` is the password of your NUSNET account.

  ## Examples

      iex> Fluminus.Authorization.jwt("e0123456", "hunter2")
      {:ok,
       %Fluminus.Authorization{
         cookies: %{
           "idsrv" => "Fnl_dY2mhtVU9nyZLb93vpU9I4eZVcWyhrnwBwCkkbrtjBsUFTGVr6JQk_x1DbdsieBzzoxqzVnrQ-dUCwqRD-dKkA1ixFnCggcX_PMcrIzr4PiZj35Z2LpVkMuWSju2BrLOJgpqCO0FFFv3uSX4Ll_jnEgPrptkHPnm6yxHls_oobhn_29Itf--NGWmWdzytx7hOktHBkeBRYhljrUHxqkGtYD2lRngMYBLBLHnTwYnu8ALRVu1oqyeEmEjQbh0pUdDCaLsnIvrFKKVQuB0Fh1z3awLUWJ8awomebTmgE5VeA68RLxy1y3J7rAJCW2IQz4WTpF1lowUry_W3UfIqUbYGcPqcdITcO2FrF6iXmxCaRWsuh07b41dQLYS04o9PRI_Q_gZYRdXroCrd_VPHdLzWi9eOnZ9fHCiG5fj1Do"
         },
         jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NDkxMDkzNjQsIm5iZiI6MTu0OTEwOTA2NCwibm9uY2UiOiI1NjlaY2VlMDM1MzdjNjQ2ZmU2MmE1MjIzOGFlN2E3ZiIsImlhdCI6MTU0OTEwOTA2NCwiYXRfaGFzaCI6ImZxWWFlLWRNaWRJNGIxZTJSMUVUUkEiLCJjX2hhc2giOiIxSkI3M1BheFVmTUROZVoybmZFcGd3Iiwic3ViIjoiMDMwODkyNTItMGM5Ni00ZmFiLWIwODAaZjJhZWIwN2VlYjBmIiwiYXV0aF90aW1lIjoxNTQ5MTA5MDY0LCJpZHAiOiJpZHNydiIsImFkZHJlc3MiOiJSZXF1ZXN0IGFsbCBjbGFpbXMiLCJhbXIiOlsicGFzc3dvcmQiXX0.NKmxw6ipXr6H2aD2cdoBiMvch9FCmeYAdtsHjYoGerhiaBdoxJ-um8P-0ThEouF4P6YYmltMSsNo9tWFNWOIhY9anU1TgTdYaYCqx5w8N9aAemRF9-PjTZMPCRCnk1xVyI3q06C_uinNJQ00So1lcA9rneWBJJecZwgwKht7EvsUiEUjXso1LgiBxO9LPOcrA47PaMti-228nN6EsxEx7Zpl8bLpQLDWX8XN8N2IKYoyo8nlQKThgziotgKXYJO22Z2DYImGTB46X2u2MfscSAedjzEhssJwVre5w2zztAAgU7E2mSif6V7jC42W7OmKQmi79_N10OAxxMUqUc7c0Q"
       }}
  """
  @spec jwt(String.t(), String.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_credentials} | {:error, any()}
  def jwt(username, password) when is_binary(username) and is_binary(password) do
    with {:ok, auth, login_uri, xsrf} <- auth_login_info(),
         body <- xsrf |> Map.merge(%{"username" => username, "password" => password}) |> URI.encode_query(),
         {:ok, auth, %{status_code: 302, headers: %{"Location" => location}}} <- http_post(auth, login_uri, body),
         {:ok, auth, %{status_code: 302, headers: %{"Location" => location}}} <- http_get(auth, location) do
      handle_callback(auth, location)
    else
      {:ok, _, %{status_code: 200}} -> {:error, :invalid_credentials}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Renews the JWT of a `#{__MODULE__}` struct containing expired token using the cookies inside the struct.
  Please note that the cookie is only valid for 24 hours.

  ## Examples

      iex> Fluminus.Authorization.renew_jwt(auth)
      {:ok,
       %Fluminus.Authorization{
         cookies: %{
           "idsrv" => "Fnl_dY2mhtVU9nyZLb93vpU9I4eZVcWyhrnwBwCkkbrtjBsUFTGVr6JQk_x1DbdsieBzzoxqzVnrQ-dUCwqRD-dKkA1ixFnCggcX_PMcrIzr4PiZj35Z2LpVkMuWSju2BrLOJgpqCO0FFFv3uSX4Ll_jnEgPrptkHPnm6yxHls_oobhn_29Itf--NGWmWdzytx7hOktHBkeBRYhljrUHxqkGtYD2lRngMYBLBLHnTwYnu8ALRVu1oqyeEmEjQbh0pUdDCaLsnIvrFKKVQuB0Fh1z3awLUWJ8awomebTmgE5VeA68RLxy1y3J7rAJCW2IQz4WTpF1lowUry_W3UfIqUbYGcPqcdITcO2FrF6iXmxCaRWsuh07b41dQLYS04o9PRI_Q_gZYRdXroCrd_VPHdLzWi9eOnZ9fHCiG5fj1Do"
         },
         jwt: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NDkxMDkzNjQsIm5iZiI6MTu0OTEwOTA2NCwibm9uY2UiOiI1NjlaY2VlMDM1MzdjNjQ2ZmU2MmE1MjIzOGFlN2E3ZiIsImlhdCI6MTU0OTEwOTA2NCwiYXRfaGFzaCI6ImZxWWFlLWRNaWRJNGIxZTJSMUVUUkEiLCJjX2hhc2giOiIxSkI3M1BheFVmTUROZVoybmZFcGd3Iiwic3ViIjoiMDMwODkyNTItMGM5Ni00ZmFiLWIwODAaZjJhZWIwN2VlYjBmIiwiYXV0aF90aW1lIjoxNTQ5MTA5MDY0LCJpZHAiOiJpZHNydiIsImFkZHJlc3MiOiJSZXF1ZXN0IGFsbCBjbGFpbXMiLCJhbXIiOlsicGFzc3dvcmQiXX0.NKmxw6ipXr6H2aD2cdoBiMvch9FCmeYAdtsHjYoGerhiaBdoxJ-um8P-0ThEouF4P6YYmltMSsNo9tWFNWOIhY9anU1TgTdYaYCqx5w8N9aAemRF9-PjTZMPCRCnk1xVyI3q06C_uinNJQ00So1lcA9rneWBJJecZwgwKht7EvsUiEUjXso1LgiBxO9LPOcrA47PaMti-228nN6EsxEx7Zpl8bLpQLDWX8XN8N2IKYoyo8nlQKThgziotgKXYJO22Z2DYImGTB46X2u2MfscSAedjzEhssJwVre5w2zztAAgU7E2mSif6V7jC42W7OmKQmi79_N10OAxxMUqUc7c0Q"
       }}
  """
  @spec renew_jwt(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_authorization} | {:error, any()}
  def renew_jwt(auth = %__MODULE__{}) do
    with {:ok, auth_uri} <- auth_endpoint_uri(),
         {:ok, auth, %{status_code: 302, headers: %{"Location" => location}}} <- http_get(auth, auth_uri),
         {:ok, auth} <- handle_callback(auth, location) do
      {:ok, auth}
    else
      {:error, :invalid_callback} -> {:error, :invalid_authorization}
      {:error, error} -> {:error, error}
    end
  end

  @spec handle_callback(__MODULE__.t(), String.t()) :: {:ok, __MODULE__.t()}
  defp handle_callback(auth = %__MODULE__{}, location) when is_binary(location) do
    case URI.parse(location) do
      %{fragment: nil} ->
        {:error, :invalid_callback}

      %{fragment: fragment} ->
        %{"id_token" => id_token} = URI.decode_query(fragment)

        # To refresh the JWT, only `idsrv` cookie is checked by the server
        cookies = %{"idsrv" => auth.cookies["idsrv"]}
        {:ok, %__MODULE__{auth | cookies: cookies, jwt: id_token}}
    end
  end

  @spec auth_login_info :: {:ok, __MODULE__.t(), String.t(), map()} | {:error, :floki} | {:error, any()}
  defp auth_login_info do
    with {:ok, auth_uri} <- auth_endpoint_uri(),
         {:ok, auth, %{status_code: 302, headers: %{"Location" => location}}} <- http_get(%__MODULE__{}, auth_uri),
         {:ok, auth, %{status_code: 200, body: body}} <- http_get(auth, location),
         {:floki, [{_, _, [raw_json]}]} <- {:floki, Floki.find(body, "#modelJson")},
         {:ok, parsed} <- raw_json |> String.trim() |> HtmlEntities.decode() |> Jason.decode() do
      full_login_uri = full_auth_uri(parsed["loginUrl"])
      xsrf = %{parsed["antiForgery"]["name"] => parsed["antiForgery"]["value"]}

      {:ok, auth, full_login_uri, xsrf}
    else
      {:floki, _} -> {:error, :floki}
      {:error, error} -> {:error, error}
    end
  end

  @spec http_get(__MODULE__.t(), String.t(), %{required(String.t()) => String.t()}) ::
          {:ok, %HTTPoison.Response{}, __MODULE__.t()} | {:error, %HTTPoison.Error{}}
  defp http_get(authorization = %__MODULE__{}, url, headers \\ %{}) when is_binary(url) and is_map(headers) do
    http_request(authorization, :get, url, "", headers)
  end

  @spec http_post(__MODULE__.t(), String.t(), String.t(), %{required(String.t()) => String.t()}) ::
          {:ok, %HTTPoison.Response{}, __MODULE__.t()} | {:error, %HTTPoison.Error{}}
  defp http_post(
         authorization = %__MODULE__{},
         url,
         body,
         headers \\ %{"Content-Type" => "application/x-www-form-urlencoded"}
       )
       when is_binary(url) and is_map(headers) do
    http_request(authorization, :post, url, body, headers)
  end

  @spec http_request(__MODULE__.t(), :get | :post, String.t(), String.t(), %{
          required(String.t()) => String.t()
        }) :: {:ok, %HTTPoison.Response{}, __MODULE__.t()} | {:error, %HTTPoison.Error{}}
  defp http_request(authorization = %__MODULE__{}, method, url, body, headers)
       when method in [:get, :post] and is_binary(url) and is_binary(body) and is_map(headers) do
    headers = Map.put(headers, "Cookie", cookies_string(authorization))

    # Increase timeout to 10s because LumiNUS authorization takes a long time
    # if the username format does not follow e0123456
    case HTTPoison.request(method, url, body, headers, recv_timeout: 10_000) do
      {:ok, response = %HTTPoison.Response{headers: headers}} ->
        headers = Map.new(headers)
        raw_cookie = Map.get(headers, "Set-Cookie")

        {:ok, add_cookie(authorization, raw_cookie), %HTTPoison.Response{response | headers: headers}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec add_cookie(__MODULE__.t(), nil | String.t()) :: __MODULE__.t()
  defp add_cookie(authorization = %__MODULE__{}, nil), do: authorization

  defp add_cookie(authorization = %__MODULE__{cookies: cookies}, raw_cookie)
       when is_binary(raw_cookie) do
    [key, value] = raw_cookie |> String.split(";") |> List.first() |> String.split("=")
    %__MODULE__{authorization | cookies: Map.put(cookies, key, value)}
  end

  @spec cookies_string(__MODULE__.t()) :: String.t()
  defp cookies_string(%__MODULE__{cookies: cookies}) when is_map(cookies) do
    cookies |> Enum.map(fn {k, v} -> "#{k}=#{v}; " end) |> Enum.join()
  end

  @spec auth_endpoint_uri :: {:ok, String.t()} | {:error, any()}
  defp auth_endpoint_uri do
    full_uri = full_auth_uri(@discovery_path)

    with {:ok, _, %{status_code: 200, body: body}} <- http_get(%__MODULE__{}, full_uri),
         {:ok, %{"authorization_endpoint" => uri}} <- Jason.decode(body),
         uri_with_params <- auth_endpoint_uri_with_params(uri) do
      {:ok, uri_with_params}
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
