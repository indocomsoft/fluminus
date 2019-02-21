defmodule Fluminus.API.File do
  @moduledoc """
  Provides an abstraction over a file/directory in LumiNUS, and operations possible on them using
  LumiNUS API.

  Struct fields:
  * `:id` - id of the file
  * `:name` - the name of the file
  * `:directory?` - whether this file is a directory
  * `:children` - `nil` indicated the need to fetch, otherwise it contains a list of its children.
  if `directory?` is `false`, then this field contains an empty list.
  * `:allow_upload?` - whether this is a student submission folder.
  """

  alias Fluminus.{API, Authorization}
  alias Fluminus.API.Module

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          directory?: bool(),
          children: [__MODULE__.t()] | nil,
          allow_upload?: bool()
        }
  defstruct ~w(id name directory? children allow_upload?)a

  @doc """
  Creates `#{__MODULE__}` struct from a `Module`.
  """
  @spec from_module(Module.t(), Authorization.t()) :: __MODULE__.t()
  def from_module(_module = %Module{id: id, code: code}, auth = %Authorization{}) do
    %__MODULE__{
      id: id,
      name: sanitise_filename(code),
      directory?: true,
      children: get_children(id, auth, false),
      allow_upload?: false
    }
  end

  @doc """
  Loads the children of a given `#{__MODULE__}` struct.
  """
  @spec load_children(__MODULE__.t(), Authorization.t()) :: __MODULE__.t()
  def load_children(
        file = %__MODULE__{id: id, directory?: true, children: nil, allow_upload?: allow_upload?},
        auth = %Authorization{}
      ) do
    %__MODULE__{file | children: get_children(id, auth, allow_upload?)}
  end

  def load_children(file = %__MODULE__{directory?: false, children: nil}, _auth) do
    %__MODULE__{file | children: []}
  end

  def load_children(file = %__MODULE__{}, _auth) do
    file
  end

  @doc """
  Obtains the download url for a given file.

  Note that the download url of a directory is a url to that directory zipped.
  """
  @spec get_download_url(__MODULE__.t(), Authorization.t()) :: String.t()
  def get_download_url(_file = %__MODULE__{id: id}, auth = %Authorization{}) do
    {:ok, %{"data" => data}} = API.api(auth, "/files/file/#{id}/downloadurl")
    data
  end

  @doc """
  Downloads the given file to the location specified by `path`.

  This function will return `{:error, :exists}` if the file already exists in the given `path`
  """
  @spec download(__MODULE__.t(), Authorization.t(), Path.t()) :: :ok | {:error, :exists | any()}
  def download(file = %__MODULE__{name: name}, auth = %Authorization{}, path) do
    destination = Path.join(path, name)

    with {:exists?, false} <- {:exists?, File.exists?(destination)},
         url <- get_download_url(file, auth),
         {:ok, file} <- File.open(destination, [:write]),
         {:ok, response} = HTTPoison.get(url, [], stream_to: self(), async: :once),
         :ok <- download_loop(response, file),
         :ok <- File.close(file) do
      :ok
    else
      {:exists?, true} -> {:error, :exists}
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_loop(response = %HTTPoison.AsyncResponse{id: id}, file) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^id} ->
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^id} ->
        IO.binwrite(file, chunk)
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncEnd{id: ^id} ->
        :ok
    end
  end

  @spec get_children(String.t(), Authorization.t(), bool()) :: [__MODULE__.t()]
  defp get_children(id, auth = %Authorization{}, allow_upload?) when is_binary(id) and is_boolean(allow_upload?) do
    {:ok, %{"data" => directory_children_data}} = API.api(auth, "/files/?ParentID=#{id}")

    {:ok, %{"data" => files_children_data}} =
      API.api(auth, "/files/#{id}/file#{if allow_upload?, do: "?populate=Creator", else: ""}")

    Enum.map(directory_children_data ++ files_children_data, &parse_child(&1, allow_upload?))
  end

  @spec sanitise_filename(String.t()) :: String.t()
  defp sanitise_filename(name) when is_binary(name) do
    # According to http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html:
    # The bytes composing the name shall not contain the <NUL> or <slash> characters
    String.replace(name, ~r|[/\0]|, "-")
  end

  @spec parse_child(map(), bool()) :: __MODULE__.t()
  defp parse_child(child = %{"id" => id, "name" => name}, add_creator_name?) when is_boolean(add_creator_name?) do
    directory? = is_map(child["access"])

    %__MODULE__{
      id: id,
      name: sanitise_filename("#{if add_creator_name?, do: "#{child["creatorName"]} - ", else: ""}#{name}"),
      directory?: directory?,
      children: if(directory?, do: nil, else: []),
      allow_upload?: (if child["allowUpload"], do: true, else: false)
    }
  end
end
