defmodule Fluminus.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Fluminus.Authorization

  setup_all do
    HTTPoison.start()
  end

  test "jwt" do
  end
end
