defmodule Fluminus.CLI do
  @moduledoc """
  Provides functions related to Fluminus' CLI.
  """

  def run(_) do
    HTTPoison.start()
    username = IO.gets("username: ") |> String.trim()
    password = password_get("password: ") |> String.trim()

    case Fluminus.Authorization.jwt(username, password) do
      {:ok, auth} ->
        IO.puts("Hi #{Fluminus.API.name(auth)}")
        modules = Fluminus.API.modules(auth)
        IO.puts("You are taking:")
        modules |> Enum.filter(&(not &1.teaching?)) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))
        IO.puts("And teaching:")
        modules |> Enum.filter(& &1.teaching?) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))

      {:error, :invalid_credentials} ->
        IO.puts("Invalid credentials!")

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
    end
  end

  # From Mix.Hex.Utils
  # Password prompt that hides input by every 1ms
  # clearing the line with stderr
  defp password_get(prompt) do
    pid = spawn_link(fn -> loop(prompt) end)
    ref = make_ref()
    value = IO.gets(prompt)

    send(pid, {:done, self(), ref})
    receive do: ({:done, ^pid, ^ref} -> :ok)

    value
  end

  defp loop(prompt) do
    receive do
      {:done, parent, ref} ->
        send(parent, {:done, self(), ref})
        IO.write(:standard_error, "\e[2K\r")
    after
      1 ->
        IO.write(:standard_error, "\e[2K\r#{prompt}")
        loop(prompt)
    end
  end
end
