defmodule Fluminus.API.Module.ExternalMultimedia.Child do
  @moduledoc """
  Provides an abstraction over an external multimedia channel's child.
  """

  defstruct ~w(name viewer_url client)a

  alias Fluminus.HTTPClient
  alias Fluminus.Util

  @type t :: %__MODULE__{name: String.t(), viewer_url: String.t(), client: HTTPClient.t()}

  def from_api(%{"ViewerUrl" => viewer_url, "SessionName" => name}, client) do
    %__MODULE__{viewer_url: viewer_url, name: name, client: client}
  end

  def get_download_url(%__MODULE__{viewer_url: viewer_url, client: client}) do
    with {:ok, client, _, %{status_code: 200, body: body}} <- HTTPClient.get(client, viewer_url),
         [{_, [_, {"content", video_url}], _}] <- Floki.find(body, "meta[property=\"og:video\"]"),
         {:ok, _, %{"location" => location}, %{status_code: 302}} <- HTTPClient.get(client, video_url) do
      {:ok, location}
    else
      {:error, error} -> {:error, error}
      x -> {:error, x}
    end
  end

  def download(child = %__MODULE__{name: name}, path, verbose) do
    destination = Path.join(path, Util.sanitise_filename(name) <> ".mp4")
    f = fn -> get_download_url(child) end

    Util.download(f, destination, verbose)
  end
end
