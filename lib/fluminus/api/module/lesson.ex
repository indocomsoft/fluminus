defmodule Fluminus.API.Module.Lesson do
  @moduledoc """
  Provides an abstraction over a lesson plan in LumiNUS, and operations possible on them using
  LumiNUS API.

  Struct fields:
  * `:id` - id of the lesson plan
  * `:name` - name of the lesson plan
  * `:week` - which week the lesson plan is for
  * `:module_id` - the module id to which the lesson plan is from.
  """

  alias Fluminus.{API, Authorization}
  alias Fluminus.API.{File, Module}

  defstruct ~w(id name week module_id)a

  @type t :: %__MODULE__{id: String.t(), name: String.t(), week: String.t(), module_id: String.t()}

  @spec from_api(map(), Module.t()) :: __MODULE__.t()
  def from_api(%{"id" => id, "name" => name, "navigationLabel" => week}, %Module{id: module_id})
      when is_binary(id) and is_binary(name) and is_binary(week) and is_binary(module_id) do
    %__MODULE__{id: id, name: name, week: week, module_id: module_id}
  end

  @spec files(__MODULE__.t(), Authorization.t()) :: {:ok, [File.t()]} | {:error, any()}
  def files(%__MODULE__{id: id, module_id: module_id}, auth = %Authorization{}) do
    uri = "/lessonplan/Activity/?populate=TargetAncestor&ModuleID=#{module_id}&LessonID=#{id}"

    case API.api(auth, uri) do
      {:ok, %{"data" => data}} when is_list(data) ->
        {:ok, data |> Enum.map(&File.from_lesson/1) |> Enum.filter(&(&1 != nil))}

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, error} ->
        {:error, error}
    end
  end
end
