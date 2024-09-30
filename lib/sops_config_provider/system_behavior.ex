defmodule SopsConfigProvider.SystemBehavior do
  @callback cmd(binary(), list(term())) :: {term(), 0} | {term(), integer()}
  # updated to allow for passing keyword list to cmd with env and cd options
  @callback cmd(binary(), list(term()), keyword()) :: {term(), 0} | {term(), integer()}
end
