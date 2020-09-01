defmodule Fluminus.API.Module.Weblecture do
  @moduledoc """
  Provides an abstraction over a weblecture in LumiNUS, and operations possible on them using
  LumiNUS API.

  Struct fields:
  * `:id` - id of the weblecture
  * `:name` - name of the weblecture
  * `:module_id` - the module_id to which the weblecture is from.
  """

  defstruct ~w(module_id id name)a

  @type t :: %__MODULE__{module_id: String.t(), id: String.t(), name: String.t()}

  alias Fluminus.{API, Authorization, HTTPClient, Util}
  alias Fluminus.API.Module

  @doc """
  Creates `#{__MODULE__}` struct from LumiNUS API response.
  """
  @spec from_api(api_response :: any(), Module.t()) :: __MODULE__.t()
  def from_api(%{"id" => id, "name" => name}, %Module{id: module_id}) when is_binary(id) and is_binary(module_id) do
    %__MODULE__{id: id, module_id: module_id, name: name}
  end

  @doc """
  Obtains the download url for a given weblecture.
  """
  @spec get_download_url(__MODULE__.t(), Authorization.t()) :: {:ok, String.t()} | {:error, any()}
  def get_download_url(%__MODULE__{module_id: module_id, id: id}, auth = %Authorization{})
      when is_binary(module_id) and is_binary(id) do
    uri = "/lti/Launch/panopto?context_id=#{module_id}&resource_link_id=#{id}"

    case API.api(auth, uri) do
      {:ok, %{"launchURL" => launch_url, "dataItems" => data_items}}
      when is_binary(launch_url) and is_list(data_items) ->
        data_items_combined =
          Enum.reduce(data_items, %{}, fn %{"key" => key, "value" => value}, acc -> Map.put(acc, key, value) end)

        do_get_download_url(launch_url, data_items_combined)

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec do_get_download_url(String.t(), map()) :: {:ok, String.t()} | {:error, any()}
  defp do_get_download_url(launch_url, data_items) when is_binary(launch_url) and is_map(data_items) do
    body = URI.encode_query(data_items)

    with {:ok, client, %{"location" => location}, %{status_code: 302}} <-
           HTTPClient.post(%HTTPClient{}, launch_url, body),
         {:ok, client, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, location),
         {:ok, client, _, %{status_code: 200, body: body}} <- HTTPClient.get(client, location),
         {:floki, {:ok, parsed}} <- {:floki, Floki.parse_fragment(body)},
         {:floki, [{_, [_, {"content", video_url}], _}]} <- {:floki, Floki.find(parsed, "meta[property=\"og:video\"]")},
         {:ok, _, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, video_url) do
      {:ok, location}
    else
      {:ok, _, _, response} -> {:error, {:unexpected_response, response}}
      {:floki, _} -> {:error, :floki}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Downloads the given weblecture to the location specified by `path`.

  This function will return `{:error, :exists}` if the file already exists in the given `path`
  """
  @spec download(__MODULE__.t(), Authorization.t(), Path.t(), bool()) :: :ok | {:error, :exists | any()}
  def download(weblecture = %__MODULE__{name: name}, auth = %Authorization{}, path, verbose) do
    destination = Path.join(path, "#{Util.sanitise_filename(name)}.mp4")
    f = fn -> get_download_url(weblecture, auth) end

    Util.download(f, destination, verbose)
  end
end
