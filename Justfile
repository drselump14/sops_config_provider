load_iex_dev_mix := "iex --dot-iex iex_dev.exs -S mix"

default:
  just -l

console:
  {{load_iex_dev_mix}}
