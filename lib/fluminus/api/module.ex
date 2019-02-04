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
  * `:valid?` - whether the struct should be considered valid. `false` if the parameter to `#{__MODULE__}.from_api/1`
  is invalid
  """

  alias Fluminus.{API, Authorization}

  @teacher_access ~w(access_Full access_Create access_Update access_Delete access_Settings_Read access_Settings_Update)

  @type t :: %__MODULE__{
          id: String.t(),
          code: String.t(),
          name: String.t(),
          teaching?: bool(),
          term: String.t(),
          valid?: bool()
        }
  @enforce_keys [:valid?]
  defstruct ~w(id code name teaching? term valid?)a

  @doc """
  Creates `#{__MODULE__}` struct from LumiNUS API response.
  """
  @spec from_api(any()) :: %__MODULE__{valid?: bool()}
  def from_api(_api_response = %{"id" => id, "name" => code, "courseName" => name, "access" => access, "term" => term}) do
    %__MODULE__{
      id: id,
      code: code,
      name: name,
      teaching?: Enum.any?(@teacher_access, &access[&1]),
      term: term,
      valid?: true
    }
  end

  def from_api(_api_response), do: %__MODULE__{valid?: false}

  @doc """
  Returns a list of `{announcement_title, announcement_content}` for a given module.

  The LumiNUS API provides 2 separate endpoints for archived and non-archived announcements. By default,
  announcements are archived after roughly 16 weeks (hence, the end of the semester) so most of the times,
  we should never need to access archived announcements.
  """
  @spec announcements(__MODULE__.t(), Authorization.t(), bool()) :: [{String.t(), String.t()}]
  def announcements(%__MODULE__{id: id}, auth = %Authorization{}, archived \\ false) do
    uri = "/announcement/#{if archived, do: "Archived", else: "NonArchived"}/#{id}?sortby=displayFrom%20DESC"
    {:ok, %{"data" => data}} = API.api(auth, uri)
    Enum.map(data, &{&1["title"], HtmlSanitizeEx.strip_tags(&1["description"])})
  end
end
