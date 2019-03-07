defmodule Fluminus.Authorization do
  @moduledoc """
  Provides an abstraction over the OpenID Connect flow authorization process as
  used by LumiNUS

  Struct fields:
  * `:client` - the `HTTPClient` containing the cookies to be used to refresh the JWT.
  * `:jwt` - the JWT Bearer token to be used by the API.
  """

  @auth_base_uri "https://luminus.nus.edu.sg"
  @discovery_path "/v2/auth/.well-known/openid-configuration"
  @client_id "verso"
  @scope "profile email role openid lms.read calendar.read lms.delete lms.write calendar.write gradebook.write offline_access"
  @response_type "id_token token code"
  @redirect_uri "https://luminus.nus.edu.sg/auth/callback"

  alias Fluminus.HTTPClient

  @type t :: %__MODULE__{jwt: String.t() | nil, client: HTTPClient.t()}
  defstruct jwt: nil, client: %HTTPClient{}

  @doc """
  Obtains a `#{__MODULE__}` struct containing JWT required for authorization and cookies to refresh JWT.
  Please note that the JWT is usually only valid for 1 hour, and the cookies for 24 hours.

  `username` is the username of your NUSNET account (in the format of e0123456).
  `password` is the password of your NUSNET account.

  ## Examples

      iex> Fluminus.Authorization.jwt("e0123456", "hunter2")
      {:ok, }
  """
  @spec jwt(String.t(), String.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_credentials} | {:error, any()}
  def jwt(username, password) when is_binary(username) and is_binary(password) do
    with {:ok, %{client: client}, login_uri, xsrf} <- auth_login_info(),
         body <- xsrf |> Map.merge(%{"username" => username, "password" => password}) |> URI.encode_query(),
         {:ok, client, %{"Location" => location}, %{status_code: 302}} <- HTTPClient.post(client, login_uri, body),
         {:ok, client, %{"Location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location) do
      handle_callback(%__MODULE__{client: client}, location)
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
      {:ok, }
  """
  @spec renew_jwt(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, :invalid_authorization} | {:error, any()}
  def renew_jwt(auth = %__MODULE__{}) do
    with {:ok, %{client: client}, auth_uri} <- auth_endpoint_uri(auth),
         {:ok, client, %{"Location" => location}, %{status_code: 302}} <- HTTPClient.get(client, auth_uri),
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
         {:ok, client, %{"Location" => location}, %{status_code: 302}} <- HTTPClient.get(client, auth_uri),
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
