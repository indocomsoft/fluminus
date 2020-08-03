defmodule Fluminus.API.Module do
  @moduledoc """
  Provides an abstraction over a module in LumiNUS, and operations possible on
  the module using LumiNUS API.

  Struct fields:
  * `:id` - id of the module in the LumiNUS API
  * `:code` - code of the module, e.g. `"CS1101S"`
  * `:name` - name of the module, e.g. `"Programming Methodology"`
  * `:teaching?` - `true` if the user is teaching the module, `false` if the user is taking the module
  * `:term` - a string identifier used by the LumiNUS API to uniquely identify a term (semester), e.g. `"1820"`
  is invalid
  """

  alias Fluminus.{API, Authorization, Util}
  alias Fluminus.API.File
  alias Fluminus.API.Module.{Lesson, Weblecture}

  @teacher_access ~w(access_Full access_Create access_Update access_Delete access_Settings_Read access_Settings_Update)

  @type t :: %__MODULE__{
          id: String.t(),
          code: String.t(),
          name: String.t(),
          teaching?: bool(),
          term: String.t()
        }
  defstruct ~w(id code name teaching? term)a

  @doc """
  Creates `#{__MODULE__}` struct from LumiNUS API response.
  """
  @spec from_api(any()) :: {:ok, __MODULE__.t()} | :error
  def from_api(_api_response = %{"id" => id, "name" => code, "courseName" => name, "access" => access, "term" => term})
      when is_binary(id) and is_binary(code) and is_binary(name) and is_binary(term) and is_map(access) do
    {:ok,
     %__MODULE__{
       id: id,
       code: code,
       name: name,
       teaching?: Enum.any?(@teacher_access, &access[&1]),
       term: term
     }}
  end

  def from_api(_api_response), do: :error

  @doc """
  Returns a list of announcements for a given module.

  The LumiNUS API provides 2 separate endpoints for archived and non-archived announcements. By default,
  announcements are archived after roughly 16 weeks (hence, the end of the semester) so most of the times,
  we should never need to access archived announcements.
  """
  @spec announcements(__MODULE__.t(), Authorization.t(), bool()) ::
          {:ok, [%{title: String.t(), description: String.t(), datetime: DateTime.t()}]} | {:error, any()}
  def announcements(%__MODULE__{id: id}, auth = %Authorization{}, archived \\ false) do
    uri = "/announcement/#{if archived, do: "Archived", else: "NonArchived"}/#{id}?sortby=displayFrom%20ASC"

    case API.api(auth, uri) do
      {:ok, %{"data" => data}} ->
        {:ok,
         Enum.map(data, fn %{"title" => title, "description" => description, "displayFrom" => datetime} ->
           datetime =
             case DateTime.from_iso8601(datetime) do
               {:ok, datetime, _} -> datetime
               {:error, _} -> nil
             end

           %{title: title, description: HtmlSanitizeEx.strip_tags(description), datetime: datetime}
         end)}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Get all the weblectures associated with this Module.
  """
  @spec weblectures(__MODULE__.t(), Authorization.t()) :: {:ok, [String.t()]} | {:error, any()}
  def weblectures(module = %__MODULE__{id: id}, auth = %Authorization{}) do
    with uri_parent <- "/weblecture/?ParentID=#{id}",
         {:ok, %{"id" => panopto_id}} when is_binary(panopto_id) <- API.api(auth, uri_parent),
         uri_children <- "/weblecture/#{panopto_id}/sessions/?sortby=createdDate",
         {:ok, %{"data" => data}} when is_list(data) <- API.api(auth, uri_children) do
      {:ok, Enum.map(data, &Weblecture.from_api(&1, module))}
    else
      {:error,
       {:unexpected_content, %{status_code: 400, body: "{\"parentID\":[\"No weblecture found for this module.\"]}"}}} ->
        {:ok, []}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Get all the lesson plans associated with this Module.
  """
  @spec lessons(__MODULE__.t(), Authorization.t()) :: {:ok, [Lesson.t()]} | {:error, any()}
  def lessons(module = %__MODULE__{id: id}, auth = %Authorization{}) do
    uri = "/lessonplan/Lesson/?ModuleID=#{id}"

    case API.api(auth, uri) do
      {:ok, %{"data" => data}} when is_list(data) ->
        {:ok, Enum.map(data, &Lesson.from_api(&1, module))}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  def multimedias(module = %__Module__{id: id}, auth = %Authorization{}) do
    uri = "/multimedia/?ParentId=#{id}"

    case API.api(auth, uri) do
      {:ok, %{"data" => data}} when is_list(data) ->
        {:ok, Enum.map(data, &parse_multimedia(&1, auth))}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_multimedia(api_response = %{"id" => id, "name" => name}, auth = %Authorization{}) do
    base = %File{id: id, name: Util.sanitise_filename(name), allow_upload?: false, multimedia?: true}

    case api_response do
      %{"duration" => _} -> %File{base | directory?: false, children: []}
      _ -> %File{base | directory?: true, children: nil}
    end
  end
end
