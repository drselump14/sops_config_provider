defmodule SopsConfigProviderTest do
  use ExUnit.Case, async: true
  alias SopsConfigProvider.InitStateError
  alias SopsConfigProvider.Sops
  alias SopsConfigProvider.Sops.SopsDecryptError
  alias SopsConfigProvider.State

  import Hammox
  import Rewire

  doctest SopsConfigProvider
  rewire(SopsConfigProvider, Sops: SopsMock)

  @yaml """
    a: 1
  """

  @app_name :sops_config_provider
  @secret_file_path "priv/test_samples/test.yml"

  describe "init/1" do
    test "when the argument is map" do
      state = %{
        app_name: :my_app,
        secret_file_path: "/file_path"
      }

      assert(%State{} = SopsConfigProvider.init(state))
    end

    test "when the argument is State struct, should return state" do
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

  describe "load/2" do
    setup %{} do
      init_state =
        State.new!(
          app_name: @app_name,
          secret_file_path: @secret_file_path,
          sops_binary_path: "sops"
        )

      config = [b: "2"]

      %{init_state: init_state, config: config}
    end

    test "when success", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        state |> Map.put(:sops_content, @yaml) |> State.ensure_type!()
      end)

      # Make sure the old config doesn't have :sops key
      refute config |> Keyword.has_key?(:sops)

      assert new_config = config |> SopsConfigProvider.load(init_state)

      assert new_config |> Keyword.has_key?(:sops)

      assert new_config[:b] == "2"
      assert new_config[:sops][:a] == 1
    end

    test "when failed", %{init_state: init_state, config: config} do
      stub(SopsMock, :check_sops_availability!, fn state -> state end)

      stub(SopsMock, :decrypt!, fn state ->
        raise SopsDecryptError, "error"
      end)

      assert_raise SopsDecryptError, fn -> config |> SopsConfigProvider.load(init_state) end
    end
  end
end
