defmodule Fluminus.HTTPClientTest do
  use ExUnit.Case, async: true

  alias Fluminus.HTTPClient

  @temp_dir "test/temp/httpclient/"
  @download_url "http://localhost:8082/v2/api/files/download/6f3cfb8c-5b91-4d5a-849a-70dcb31eea87"

  setup_all do
    File.rm_rf!(@temp_dir)
    File.mkdir_p!(@temp_dir)

    on_exit(fn ->
      File.rm_rf!(@temp_dir)
    end)
  end

  test "download" do
    destination = Path.join(@temp_dir, "test")
    assert HTTPClient.download(%HTTPClient{}, @download_url, destination) == :ok
    assert HTTPClient.download(%HTTPClient{}, @download_url, destination) == {:error, :exists}
    assert HTTPClient.download(%HTTPClient{}, @download_url, destination, true) == :ok
  end
end
