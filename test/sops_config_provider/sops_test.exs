defmodule SopsConfigProvider.SopsTest do
  use ExUnit.Case, async: true

  import Rewire
  import Hammox

  alias SopsConfigProvider.Sops
  alias SopsConfigProvider.Sops.SopsDecryptError
  alias SopsConfigProvider.Sops.SopsNotInstalledError
  alias SopsConfigProvider.State

  rewire(Sops, System: SystemMock)

  @yaml """
    a: 1
  """

  @json "{\"a\":1}"

  @app_name :sops_config_provider
  @secret_file_path "priv/test_samples/test.yaml"

  setup %{} do
    init_state =
      State.new!(
        app_name: @app_name,
        secret_file_path: @secret_file_path,
        sops_binary_path: "sops"
      )

    %{init_state: init_state}
  end

  describe "check_sops_availability/1" do
    test "when sops is installed", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", ["--version"] -> {:ok, 0} end)
      assert init_state == init_state |> Sops.check_sops_availability!()
    end

    test "when sops is not installed", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", ["--version"] -> {:error, 1} end)

      assert_raise(SopsNotInstalledError, fn ->
        init_state |> Sops.check_sops_availability!()
      end)
    end
  end

  describe "decrypt!/1 with yaml file" do
    test "when success", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", _, _ -> {@yaml, 0} end)
      assert %State{sops_content: @yaml} = init_state |> Sops.decrypt!()
    end

    test "when failed", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", _, _ -> {"error", 1} end)

      assert_raise(SopsDecryptError, fn -> init_state |> Sops.decrypt!() end)
    end
  end

  describe "decrypt!/1 with json file" do
    test "when success", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", _, _ -> {@json, 0} end)
      assert %State{sops_content: @json} = init_state |> Sops.decrypt!()
    end

    test "when failed", %{init_state: init_state} do
      stub(SystemMock, :cmd, fn "sops", _, _ -> {"error", 1} end)

      assert_raise(SopsDecryptError, fn -> init_state |> Sops.decrypt!() end)
    end
  end
end
