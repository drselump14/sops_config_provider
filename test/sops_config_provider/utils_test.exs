defmodule SopsConfigProvider.UtilsTest do
  use ExUnit.Case, async: true

  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils

  setup %{} do
    init_state =
      State.new!(
        app_name: :app_name,
        secret_file_path: "/secret"
      )

    %{init_state: init_state}
  end

  test "convert_to_map!/1 when file_type is yaml", %{init_state: init_state} do
    yaml = """
      a: 1
    """

    state =
      init_state
      |> Map.put(:sops_content, yaml)
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
end
