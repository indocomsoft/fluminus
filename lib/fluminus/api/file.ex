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

  alias Fluminus.{API, Authorization, Util}
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
  @spec from_module(Module.t(), Authorization.t()) :: {:ok, __MODULE__.t()} | :error
  def from_module(_module = %Module{id: id, code: code}, auth = %Authorization{}) do
    case get_children(id, auth, false) do
      {:ok, children} ->
        {:ok,
         %__MODULE__{
           id: id,
           name: Util.sanitise_filename(code),
           directory?: true,
           children: children,
           allow_upload?: false
         }}

      {:error, _} ->
        :error
    end
  end

  @spec from_lesson(any()) :: __MODULE__.t() | nil
  def from_lesson(%{"target" => %{"id" => id, "name" => name, "isResourceType" => false}})
      when is_binary(id) and is_binary(name) do
    %__MODULE__{id: id, name: name, directory?: false, children: [], allow_upload?: false}
  end

  def from_lesson(_), do: nil

  @doc """
  Loads the children of a given `#{__MODULE__}` struct.
  """
  @spec load_children(__MODULE__.t(), Authorization.t()) :: {:ok, __MODULE__.t()} | :error
  def load_children(
        file = %__MODULE__{id: id, directory?: true, children: nil, allow_upload?: allow_upload?},
        auth = %Authorization{}
      ) do
    case get_children(id, auth, allow_upload?) do
      {:ok, children} -> {:ok, %__MODULE__{file | children: children}}
      {:error, _} -> :error
    end
  end

  def load_children(file = %__MODULE__{directory?: false, children: nil}, _auth) do
    {:ok, %__MODULE__{file | children: []}}
  end

  def load_children(file = %__MODULE__{}, _auth) do
    {:ok, file}
  end

  @doc """
  Obtains the download url for a given file.

  Note that the download url of a directory is a url to that directory zipped.
  """
  @spec get_download_url(__MODULE__.t(), Authorization.t()) :: {:ok, String.t()} | {:error, any()}
  def get_download_url(_file = %__MODULE__{id: id}, auth = %Authorization{}) do
    case API.api(auth, "files/file/#{id}/downloadurl") do
      {:ok, %{"data" => data}} when is_binary(data) -> {:ok, data}
      {:ok, response} -> {:error, {:unexpected_response, response}}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Downloads the given file to the location specified by `path`.

  This function will return `{:error, :exists}` if the file already exists in the given `path`
  """
  @spec download(__MODULE__.t(), Authorization.t(), Path.t(), bool()) :: :ok | {:error, :exists | any()}
  def download(file = %__MODULE__{name: name}, auth = %Authorization{}, path, verbose \\ false) do
    destination = Path.join(path, name)
    f = fn -> get_download_url(file, auth) end

    Util.download(f, destination, verbose)
  end

  @spec get_children(String.t(), Authorization.t(), bool()) :: {:ok, [__MODULE__.t()]} | {:error, any()}
  defp get_children(id, auth = %Authorization{}, allow_upload?) when is_binary(id) and is_boolean(allow_upload?) do
    with {:directory, {:ok, %{"data" => directory_children_data}}} <-
           {:directory, API.api(auth, "/files/?ParentID=#{id}")},
         {:files, {:ok, %{"data" => files_children_data}}} <-
           {:files, API.api(auth, "/files/#{id}/file#{if allow_upload?, do: "?populate=Creator", else: ""}")} do
      {:ok, Enum.map(directory_children_data ++ files_children_data, &parse_child(&1, allow_upload?))}
    else
      response -> {:error, response}
    end
  end

  @spec parse_child(map(), bool()) :: __MODULE__.t()
  defp parse_child(child = %{"id" => id, "name" => name}, add_creator_name?) when is_boolean(add_creator_name?) do
    directory? = is_map(child["access"])

    %__MODULE__{
      id: id,
      name: Util.sanitise_filename("#{if add_creator_name?, do: "#{child["creatorName"]} - ", else: ""}#{name}"),
      directory?: directory?,
      children: if(directory?, do: nil, else: []),
      allow_upload?: if(child["allowUpload"], do: true, else: false)
    }
  end
end
