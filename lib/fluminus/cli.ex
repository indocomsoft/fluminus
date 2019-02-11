defmodule Fluminus.CLI do
  @moduledoc """
  Provides functions related to Fluminus' CLI.
  """

  @config_file "config.json"

  alias Fluminus.API.File
  alias Fluminus.Authorization

  def run(args) do
    HTTPoison.start()
    {username, password} = load_credentials()

    case Authorization.jwt(username, password) do
      {:ok, auth} ->
        save_credentials(username, password)
        run(args, auth)

      {:error, :invalid_credentials} ->
        IO.puts("Invalid credentials!")
        clear_credentials()
        run(args)

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}")
    end
  end

  def run(args, auth = %Authorization{}) do
    {parsed, _, _} = OptionParser.parse(args, strict: [announcements: :boolean, files: :boolean])

    IO.puts("Hi #{Fluminus.API.name(auth)}")
    modules = Fluminus.API.modules(auth)
    IO.puts("You are taking:")
    modules |> Enum.filter(&(not &1.teaching?)) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))
    IO.puts("And teaching:")
    modules |> Enum.filter(& &1.teaching?) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))

    if parsed[:announcements] do
      IO.puts("\n# Announcements:\n")

      for mod <- modules do
        IO.puts("## #{mod.code} #{mod.name}")

        for {title, description} <- Fluminus.API.Module.announcements(mod, auth) do
          IO.puts("=== #{title} ===")
          IO.puts(description)
        end

        IO.puts("")
      end
    end

    if parsed[:files] do
      IO.puts("\n# Files:\n")

      for mod <- modules do
        IO.puts("## #{mod.code} #{mod.name}")

        mod |> File.from_module(auth) |> list_file(auth)
        IO.puts("")
      end
    end
  end

  defp load_credentials do
    with {:ok, data} <- Elixir.File.read(@config_file),
         {:ok, decoded} <- Jason.decode(data) do
      {decoded["username"], decoded["password"]}
    else
      _ ->
        username = IO.gets("username: ") |> String.trim()
        password = password_get("password: ") |> String.trim()
        {username, password}
    end
  end

  def clear_credentials do
    case Elixir.File.rm(@config_file) do
      :ok ->
        IO.puts("Cleared stored credentials")
        :ok

      {:error, _} ->
        nil
    end
  end

  defp save_credentials(username, password) when is_binary(username) and is_binary(password) do
    data = %{username: username, password: password}

    with {:exists, false} <- {:exists, Elixir.File.exists?(@config_file)},
         true <- confirm?("Do you want to store your credential? (WARNING: they are stored in plain text) [y/n]"),
         {:ok, encoded} <- Jason.encode(data),
         :ok <- Elixir.File.write("config.json", encoded) do
      :ok
    else
      {:exists, true} ->
        :ok

      {:error, reason} ->
        IO.puts("Unable to save credentials: #{reason}")
        :error
    end
  end

  defp confirm?(prompt) when is_binary(prompt) do
    answer = prompt |> IO.gets() |> String.trim() |> String.downcase()

    case answer do
      "y" -> true
      "n" -> false
      _ -> confirm?(prompt)
    end
  end

  defp list_file(file, auth), do: list_file(file, auth, "")

  defp list_file(file, auth, prefix) when is_binary(prefix) do
    if file.directory? do
      file.children
      |> Enum.map(&File.load_children(&1, auth))
      |> Enum.each(&list_file(&1, auth, "#{prefix}/#{file.name}"))
    else
      IO.puts("#{prefix}/#{file.name}")
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
