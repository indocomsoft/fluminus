defmodule Fluminus.API do
  @moduledoc """
  Provides an abstraction over the LumiNUS API.

  This module is dependent on `Fluminus.Authorization` to authorize to the LumiNUS servers.
  """

  @api_base_url Fluminus.Constants.api_base_url(Mix.env())
  @ocm_apim_subscription_key Fluminus.Constants.ocm_apim_subscription_key(Mix.env())

  @type headers() :: [{String.t(), String.t()}]

  alias Fluminus.API.Module
  alias Fluminus.Authorization
  alias Fluminus.HTTPClient

  @doc """
  Returns the name of the user with the given authorization.

  The LumiNUS API returns the name of the user all capitalised, but this function normalises the
  capitalisation to Title Case.

  ## Examples

      iex> Fluminus.API.name(auth)
      "John Smith"
  """
  @spec name(Authorization.t()) :: {:ok, String.t()} | {:error, any()}
  def name(auth = %Authorization{}) do
    case api(auth, "/user/Profile") do
      {:ok, %{"userNameOriginal" => name}} when is_binary(name) ->
        result =
          name
          |> String.split()
          |> Enum.map(&String.capitalize/1)
          |> Enum.join(" ")

        {:ok, result}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Returns information about the current term.

  ## Examples

      iex> Fluminus.API.current_term(auth)
      %{term: "1820", description: "2018/2019 Semester 2"}
  """
  @spec current_term(Authorization.t()) :: {:ok, %{term: String.t(), description: String.t()}} | {:error, any()}
  def current_term(auth = %Authorization{}) do
    case api(auth, "/setting/AcademicWeek/current?populate=termDetail") do
      {:ok, %{"termDetail" => %{"term" => term, "description" => description}}}
      when is_binary(term) and is_binary(description) ->
        {:ok, %{term: term, description: description}}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Returns the modules that the user with the given authorization is taking.

  * `current_term_only` - if `true`, will only return modules that the user is currently taking this semester.
  Otherwise, return all modules that are still in the LumiNUS system.

  ## Examples

      iex> Fluminus.API.modules(auth)
      {:ok,
        [
          %Fluminus.API.Module{
            code: "CS2100",
            id: "063773a9-43ac-4dc0-bdc6-4be2f5b50300",
            name: "Computer Organisation",
            teaching?: true,
            term: "1820"
          },
          %Fluminus.API.Module{
            code: "ST2334",
            id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
            name: "Probability and Statistics",
            teaching?: false,
            term: "1820"
          },
          %Fluminus.API.Module{
            code: "CS1101S",
            id: "8722e9a5-abc5-4160-820d-bf69d8a63c6f",
            name: "Programming Methodology",
            teaching?: true,
            term: "1810"
          }
        ]
      }

      iex> Fluminus.API.modules(auth, true)
      {:ok,
        [
          %Fluminus.API.Module{
            code: "CS2100",
            id: "063773a9-43ac-4dc0-bdc6-4be2f5b50300",
            name: "Computer Organisation",
            teaching?: true,
            term: "1820"
          },
          %Fluminus.API.Module{
            code: "ST2334",
            id: "40582141-1a1d-41b6-ba3a-efa44ff7fd05",
            name: "Probability and Statistics",
            teaching?: false,
            term: "1820"
          }
        ]
      }
  """
  @spec modules(Authorization.t()) :: {:ok, [Module.t()]} | {:error, any()}
  def modules(auth = %Authorization{}, current_term_only \\ false) do
    case api(auth, "/module") do
      {:ok, %{"data" => data}} ->
        mods =
          data
          |> Enum.map(&Module.from_api/1)
          |> Enum.map(fn
            {:ok, mod = %Module{}} -> mod
            _ -> nil
          end)
          |> Enum.reject(&is_nil/1)

        if current_term_only do
          case current_term(auth) do
            {:ok, %{term: term}} -> {:ok, Enum.filter(mods, &(&1.term == term))}
            error -> {:error, {:current_term, error}}
          end
        else
          {:ok, mods}
        end

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Makes a LumiNUS API call with a given authorization, and then parses the JSON response.

  ## Examples

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
  @spec api(Authorization.t(), String.t(), :get | :post, String.t(), headers()) ::
          {:ok, map()} | {:error, :expired_token} | {:error, {:unexpected_content, any()}} | {:error, any()}
  def api(%Authorization{jwt: jwt}, path, method \\ :get, body \\ "", headers \\ [])
      when method in [:get, :post] do
    headers =
      headers ++
        [
          {"Authorization", "Bearer #{jwt}"},
          {"Ocp-Apim-Subscription-Key", @ocm_apim_subscription_key},
          {"Content-Type", "application/json"}
        ]

    uri = full_api_uri(path)

    case HTTPClient.request(%HTTPClient{}, method, uri, body, headers) do
      {:ok, _, _, %{status_code: 200, body: body}} -> Jason.decode(body)
      {:ok, _, _, %{status_code: 401}} -> {:error, :expired_token}
      {:ok, _, _, response} -> {:error, {:unexpected_content, response}}
      {:error, error} -> {:error, error}
    end
  end

  @spec full_api_uri(String.t()) :: String.t()
  defp full_api_uri(path) do
    @api_base_url |> URI.merge(path) |> URI.to_string()
  end
end
