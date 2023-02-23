defmodule SopsConfigProvider.StateTest do
  use ExUnit.Case, async: true

  alias SopsConfigProvider.State

  setup do
    %{
      app_name: :app_name,
      secret_file_path: "/secret_file_path"
    }
  end

  test "default value", init_state do
    assert({:ok, state} = State.new(init_state))

    assert state.file_type == nil
    assert state.sops_binary_path == "sops"
  end

  test "wrong file type", init_state do
    assert {:error, error} = init_state |> Map.put(:file_type, :pdf) |> State.new()

    assert(error |> Keyword.has_key?(:file_type))
  end
end
