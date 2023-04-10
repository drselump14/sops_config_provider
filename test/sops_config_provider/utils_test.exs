defmodule SopsConfigProvider.UtilsTest do
  use ExUnit.Case, async: true

  alias SopsConfigProvider.State
  alias SopsConfigProvider.Utils
  alias SopsConfigProvider.Utils.SecretFileNotFoundError

  @yaml """
    a: 1
  """

  @keyword_list [
    a: 1
  ]

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

  describe "resolve_secret_file_location/1" do
    test "correct_path", %{init_state: init_state} do
      assert init_state |> Utils.resolve_secret_file_location!()
    end

    test "wrong_path", %{init_state: init_state} do
      assert_raise SecretFileNotFoundError, fn ->
        init_state
        |> Map.put(:secret_file_path, "wrong.yml")
        |> State.ensure_type!()
        |> Utils.resolve_secret_file_location!()
      end
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

  test "convert_to_keyword_list!/1 when file_type is yaml", %{init_state: init_state} do
    state =
      init_state
      |> Map.put(:sops_content, @yaml)
      |> Map.put(:file_type, :yaml)
      |> State.ensure_type!()

    assert Utils.convert_to_keyword_list!(state) == @keyword_list
  end

  test "convert_to_keyword_list!/1 when file_type is json", %{init_state: init_state} do
    json = ~S({"a": 1})

    state =
      init_state
      |> Map.put(:sops_content, json)
      |> Map.put(:file_type, :json)
      |> State.ensure_type!()

    assert Utils.convert_to_keyword_list!(state) == @keyword_list
  end
end
