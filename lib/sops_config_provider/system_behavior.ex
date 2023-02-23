defmodule SopsConfigProvider.SystemBehavior do
  @callback cmd(binary(), list(term())) :: {term(), 0} | {term(), integer()}
end
