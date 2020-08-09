defmodule Fluminus.API.Module.ExternalMultimedia do
  @moduledoc """
  Provides an abstraction over an external multimedia channel.
  """

  defstruct ~w(id name children)a

  @type t :: %__MODULE__{id: String.t(), name: String.t()}

  alias Fluminus.{API, Authorization, HTTPClient}
  alias Fluminus.API.Module.ExternalMultimedia.Child

  @spec from_api(any()) :: __MODULE__.t()
  def from_api(%{"id" => id, "name" => name}) when is_binary(id) and is_binary(name) do
    %__MODULE__{id: id, name: name, children: nil}
  end

  @spec get_children(__MODULE__.t(), Authorization.t()) :: {:ok, [Child.t()]} | {:error, any()}
  def get_children(%__MODULE__{id: id}, auth = %Authorization{}) do
    uri = "/lti/Launch/mediaweb?context_id=#{id}"

    case API.api(auth, uri) do
      {:ok, %{"launchURL" => launch_url, "dataItems" => data_items}}
      when is_binary(launch_url) and is_list(data_items) ->
        data_items_combined =
          Enum.reduce(data_items, %{}, fn %{"key" => key, "value" => value}, acc -> Map.put(acc, key, value) end)

        do_get_children(launch_url, data_items_combined)

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec do_get_children(String.t(), map()) :: {:ok, String.t()} | {:error, any()}
  defp do_get_children(launch_url, data_items)
       when is_binary(launch_url) and is_map(data_items) do
    body = URI.encode_query(data_items)

    with {:ok, client, %{"location" => location}, %{status_code: 302}} <-
           HTTPClient.post(%HTTPClient{}, launch_url, body),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location),
         %{fragment: fragment} <- URI.parse(location),
         %{"folderID" => folder_id} <- URI.decode_query(fragment),
         folder_id <- String.trim(folder_id, "\""),
         body <- Jason.encode!(%{"queryParameters" => %{"folderID" => folder_id}}),
         {:ok, client, _, %{status_code: 200, body: body}} <-
           HTTPClient.post(client, "https://mediaweb.ap.panopto.com/Panopto/Services/Data.svc/GetSessions", body, [
             {"Content-Type", "application/json"}
           ]),
         {:ok, %{"d" => %{"Results" => results}}} <- Jason.decode(body) do
      {:ok, Enum.map(results, &Child.from_api(&1, client))}
    else
      {:error, error} -> {:error, error}
      x -> {:error, x}
    end
  end
end
