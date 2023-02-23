defmodule SopsConfigProviderTest do
  use ExUnit.Case, async: true
  alias SopsConfigProvider.InitStateError
  alias SopsConfigProvider.State

  doctest SopsConfigProvider

  describe "init/1" do
    test "should return state" do
      state =
        State.new!(
          app_name: :my_app,
          secret_file_path: "/file_path"
        )

      assert(SopsConfigProvider.init(state) == state)
    end

    test "should raise InitStateError when the parameter is not State" do
      assert_raise(InitStateError, fn -> SopsConfigProvider.init("hoge") end)
    end
  end
end
