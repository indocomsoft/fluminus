defmodule Mix.Tasks.Fluminus do
  @help """
  mix fluminus [OPTIONS]

  --announcements     Show announcements
  --files             Show files
  --download-to=PATH  Download files to PATH
  """

  @moduledoc """
  Runs the Fluminus CLI.

  ```
  #{@help}
  ```
  """

  @shortdoc "Runs the Fluminus CLI."

  use Mix.Task

  def run(args) do
    if "--help" in args or "-h" in args do
      IO.puts(@help)
    else
      Fluminus.CLI.run(args)
    end
  end
end
