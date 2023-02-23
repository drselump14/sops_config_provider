defmodule SopsConfigProvider.SopsBehavior do
  alias SopsConfigProvider.State

  @callback check_sops_availability!(State.t()) :: State.t()
  @callback decrypt!(State.t()) :: State.t()
end
