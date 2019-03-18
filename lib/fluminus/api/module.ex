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

  alias Fluminus.{API, Authorization}

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
end
