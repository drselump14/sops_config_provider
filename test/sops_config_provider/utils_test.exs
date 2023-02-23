defmodule SopsConfigProvider.UtilsTest do
  use ExUnit.Case, async: true

  import Mock

  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils

  @yaml """
    a: 1
  """

  @json "{\"a\":1}"

  @app_name :app_name
  @secret_file_path "test/samples/test.yml"

  setup %{} do
    init_state =
      State.new!(
        app_name: @app_name,
        secret_file_path: @secret_file_path,
        sops_binary_path: "sops"
      )

    %{init_state: init_state}
  end

  test "resolve_secret_file_location!/1", %{init_state: init_state} do
    with_mocks([
      {Application, [], [app_dir: fn @app_name, @secret_file_path -> @secret_file_path end]},
      {Application, [], [get_env: fn _, _, _ -> "" end]},
      {Application, [], [fetch_env: fn _, _ -> "" end]}
    ]) do
      assert %State{secret_file_path: @secret_file_path} =
               init_state |> Utils.resolve_secret_file_location!()
    end

    with_mocks([
      {Application, [], [app_dir: fn @app_name, @secret_file_path -> "wrong.yml" end]},
      {Application, [], [get_env: fn _, _, _ -> "" end]},
      {Application, [], [fetch_env: fn _, _ -> "" end]}
    ]) do
      assert_raise(Utils.SecretFileNotFoundError, fn ->
        init_state |> Utils.resolve_secret_file_location!()
      end)
    end
  end

  test "check_sops_availability!/1", %{init_state: init_state} do
    with_mock(System, cmd: fn "sops", ["--version"] -> {:ok, 0} end) do
      assert init_state == init_state |> Utils.check_sops_availability!()
    end

    with_mock(System, cmd: fn "sops", ["--version"] -> {:error, 1} end) do
      assert_raise(Utils.SopsNotInstalledError, fn ->
        init_state |> Utils.check_sops_availability!()
      end)
    end
  end

  test "decrypt!/1 with yaml file", %{init_state: init_state} do
    with_mock(System, cmd: fn "sops", _ -> {@yaml, 0} end) do
      assert %State{sops_content: @yaml} = init_state |> Utils.decrypt!()
    end

    with_mock(System, cmd: fn "sops", _ -> {"error", 1} end) do
      assert_raise(Utils.SopsDecryptError, fn -> init_state |> Utils.decrypt!() end)
    end
  end

  test "decrypt!/1 with json file", %{init_state: init_state} do
    with_mock(System, cmd: fn "sops", _ -> {@json, 0} end) do
      assert %State{sops_content: @json} = init_state |> Utils.decrypt!()
    end

    with_mock(System, cmd: fn "sops", _ -> {"error", 1} end) do
      assert_raise(Utils.SopsDecryptError, fn -> init_state |> Utils.decrypt!() end)
    end
  end

  test "get_file_type/1 for yaml", %{init_state: init_state} do
    state =
      init_state
      |> Map.put(:secret_file_path, "test/sample/test.yaml")
      |> State.ensure_type!()

    assert(%State{file_type: :yaml} = Utils.get_file_type(state))
  end

  test "get_file_type/1 for json", %{init_state: init_state} do
    state =
      init_state
      |> Map.put(:secret_file_path, "test/sample/test.json")
      |> State.ensure_type!()

    assert(%State{file_type: :json} = Utils.get_file_type(state))
  end

  test "convert_to_map!/1 when file_type is yaml", %{init_state: init_state} do
    state =
      init_state
      |> Map.put(:sops_content, @yaml)
      |> Map.put(:file_type, :yaml)
      |> State.ensure_type!()

    assert Utils.convert_to_map!(state) == %{a: 1}
  end

  test "convert_to_map!/1 when file_type is json", %{init_state: init_state} do
    map = %{a: 1}
    json = map |> Jason.encode!()

    state =
      init_state
      |> Map.put(:sops_content, json)
      |> Map.put(:file_type, :json)
      |> State.ensure_type!()

    assert Utils.convert_to_map!(state) == map
  end
end
