defmodule Fluminus.API.Module do
  @moduledoc """
  Provides a `#{__MODULE__}` struct as an abstraction over a module in LumiNUS, and operations possible on
  the module using LumiNUS API.
  """

  @teacher_access ~w(access_Full access_Create access_Update access_Delete access_Settings_Read access_Settings_Update)

  @doc """
  Provides information regarding a module in LumiNUS.
  """
  @type t :: %__MODULE__{id: String.t(), code: String.t(), name: String.t(), teaching?: bool()}
  @enforce_keys [:id, :code, :name, :teaching?, :term]
  defstruct [:id, :code, :name, :teaching?, :term]

  @spec from_api(map()) :: %__MODULE__{}
  def from_api(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      code: map["name"],
      name: map["courseName"],
      teaching?: Enum.any?(@teacher_access, &map["access"][&1]),
      term: map["term"]
    }
  end
end
