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
  """

  alias Fluminus.{API, Authorization}
  alias Fluminus.API.Module

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          directory?: bool(),
          children: [__MODULE__.t()] | nil
        }
  defstruct ~w(id name directory? children)a

  @doc """
  Creates `#{__MODULE__}` struct from a `Module`.
  """
  def from_module(_module = %Module{id: id, code: code}, auth = %Authorization{}) do
    %__MODULE__{
      id: id,
      name: sanitise_filename(code),
      directory?: true,
      children: get_children(id, auth)
    }
  end

  def from_module(_module, _auth), do: nil

  @doc """
  Loads the children of a given `#{__MODULE__}` struct.
  """
  def load_children(file = %__MODULE__{id: id, directory?: true, children: nil}, auth = %Authorization{}) do
    %__MODULE__{file | children: get_children(id, auth)}
  end

  def load_children(file = %__MODULE__{directory?: false, children: nil}, _auth) do
    %__MODULE__{file | children: []}
  end

  def load_children(file = %__MODULE__{}, _auth) do
    file
  end

  def get_download_url(_file = %__MODULE__{id: id}, auth) do
    {:ok, %{"data" => data}} = API.api(auth, "/files/file/#{id}/downloadurl")
    data
  end

  defp get_children(id, auth = %Authorization{}) when is_binary(id) do
    {:ok, %{"data" => directory_children_data}} = API.api(auth, "/files/?ParentID=#{id}")
    {:ok, %{"data" => files_children_data}} = API.api(auth, "/files/#{id}/file")

    Enum.map(directory_children_data ++ files_children_data, &parse_child/1)
  end

  defp sanitise_filename(name) when is_binary(name) do
    # According to http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html:
    # The bytes composing the name shall not contain the <NUL> or <slash> characters
    String.replace(name, ~r|[/\0]|, "-")
  end

  defp parse_child(child = %{"id" => id, "name" => name}) do
    directory? = is_map(child["access"])

    %__MODULE__{
      id: id,
      name: sanitise_filename(name),
      directory?: directory?,
      children: if(directory?, do: nil, else: [])
    }
  end
end
