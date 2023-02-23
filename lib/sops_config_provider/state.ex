defmodule SopsConfigProvider.State do
  @moduledoc """
  Define data structure for state
  """
  use TypedStruct
  use Domo

  @type available_file_type :: :json | :yaml | nil

  typedstruct do
    field(:app_name, atom(), enforce: true)
    field(:secret_file_path, binary(), enforce: true)
    field(:file_type, available_file_type(), default: nil)
    field(:sops_binary_path, binary(), default: "sops")
    field(:sops_content, binary())
  end
end
