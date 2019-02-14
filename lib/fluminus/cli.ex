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

  @spec run([String.t()], Authorization.t()) :: :ok
  defp run(args, auth = %Authorization{}) do
    {parsed, _, _} = OptionParser.parse(args, strict: [announcements: :boolean, files: :boolean, download_to: :string])

    IO.puts("Hi #{Fluminus.API.name(auth)}")
    modules = Fluminus.API.modules(auth, true)
    IO.puts("You are taking:")
    modules |> Enum.filter(&(not &1.teaching?)) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))
    IO.puts("And teaching:")
    modules |> Enum.filter(& &1.teaching?) |> Enum.each(&IO.puts("- #{&1.code} #{&1.name}"))
    IO.puts("")

    Enum.each(parsed, fn
      {:announcements, true} -> list_announcements(auth, modules)
      {:files, true} -> list_files(auth, modules)
      {:download_to, path} -> download_to(auth, modules, path)
    end)
  end

  defp download_to(auth, modules, path) do
    IO.puts("Download to #{path}")

    if Elixir.File.dir?(path) do
      for mod <- modules do
        IO.puts("## #{mod.code}\n")

        mod
        |> File.from_module(auth)
        |> download_file(auth, path)

        IO.puts("\n")
      end
    else
      IO.puts("Download destination does not exist or is not a directory!")
    end
  end

  defp download_file(file, auth, path) do
    destination = Path.join(path, file.name)

    if file.directory? do
      Elixir.File.mkdir_p!(destination)

      file.children
      |> Enum.map(&File.load_children(&1, auth))
      |> Enum.each(&download_file(&1, auth, destination))
    else
      case File.download(file, auth, path) do
        :ok -> IO.puts("Downloaded to #{destination}")
        {:error, :exists} -> :ok
        {:error, reason} -> IO.puts("Unable to download to #{destination}, reason: #{reason}")
      end
    end
  end

  defp list_files(auth, modules) do
    IO.puts("\n# Files:\n")

    for mod <- modules do
      IO.puts("## #{mod.code} #{mod.name}")

      mod |> File.from_module(auth) |> list_file(auth)
      IO.puts("")
    end
  end

  defp list_announcements(auth, modules) do
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

  @spec load_credentials :: {String.t(), String.t()}
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

  @spec clear_credentials() :: :ok | nil
  defp clear_credentials do
    case Elixir.File.rm(@config_file) do
      :ok ->
        IO.puts("Cleared stored credentials")
        :ok

      {:error, _} ->
        nil
    end
  end

  @spec save_credentials(String.t(), String.t()) :: :ok | :error
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

  @spec confirm?(String.t()) :: bool()
  defp confirm?(prompt) when is_binary(prompt) do
    answer = prompt |> IO.gets() |> String.trim() |> String.downcase()

    case answer do
      "y" -> true
      "n" -> false
      _ -> confirm?(prompt)
    end
  end

  @spec list_file(File.t(), Authorization.t()) :: :ok
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
  @spec password_get(String.t()) :: String.t()
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
