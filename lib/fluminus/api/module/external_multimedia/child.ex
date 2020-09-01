defmodule Fluminus.API.Module.ExternalMultimedia.Child do
  @moduledoc """
  Provides an abstraction over an external multimedia channel's child.
  """

  defstruct ~w(name viewer_url client)a

  alias Fluminus.HTTPClient
  alias Fluminus.Util

  @type t :: %__MODULE__{name: String.t(), viewer_url: String.t(), client: HTTPClient.t()}

  @spec from_api(any(), HTTPClient.t()) :: __MODULE__.t()
  def from_api(%{"ViewerUrl" => viewer_url, "SessionName" => name}, client) do
    %__MODULE__{viewer_url: viewer_url, name: name, client: client}
  end

  @spec get_download_url(__MODULE__.t()) :: {:ok, String.t()} | {:error, any()}
  def get_download_url(%__MODULE__{viewer_url: viewer_url, client: client}) do
    with {:ok, client, _, %{status_code: 200, body: body}} <- HTTPClient.get(client, viewer_url),
         {:ok, parsed} <- Floki.parse_fragment(body),
         [{_, [_, {"content", video_url}], _}] <- Floki.find(parsed, "meta[property=\"og:video\"]"),
         {:ok, _, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, video_url) do
      {:ok, location}
    else
      {:error, error} -> {:error, error}
      x -> {:error, x}
    end
  end

  @spec download(__MODULE__.t(), String.t(), bool()) :: :ok | {:error, :exists | any()}
  def download(child = %__MODULE__{name: name}, path, verbose) do
    destination = Path.join(path, Util.sanitise_filename(name) <> ".mp4")
    f = fn -> get_download_url(child) end

    Util.download(f, destination, verbose)
  end
end
