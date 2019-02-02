defmodule Mix.Tasks.Fluminus do
  @moduledoc """
  Runs the Fluminus CLI.
  """
  use Mix.Task

  def run(args) do
    Fluminus.CLI.run(args)
  end
end
