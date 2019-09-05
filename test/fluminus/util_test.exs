defmodule Fluminus.UtilTest do
  use ExUnit.Case, async: true

  alias Fluminus.Util

  describe "Util.sanitise_filename/1" do
    test "replaces both nil and / with -" do
      assert Util.sanitise_filename("asd\0") == "asd-"
      assert Util.sanitise_filename("asd/asd/asd") == "asd-asd-asd"
      assert Util.sanitise_filename("\0asd/asd/asd") == "-asd-asd-asd"
    end

    test "works with another replacement" do
      assert Util.sanitise_filename("asd\0", "+") == "asd+"
      assert Util.sanitise_filename("asd/asd/asd", "+") == "asd+asd+asd"
      assert Util.sanitise_filename("\0asd/asd/asd", "+") == "+asd+asd+asd"
    end
  end
end
