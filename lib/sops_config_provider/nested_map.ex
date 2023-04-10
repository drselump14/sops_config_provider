defmodule SopsConfigProvider.NestedMap do
  @moduledoc """
  Utils to process nested map
  """

  @spec to_keyword_list(any) :: any
  def to_keyword_list(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} ->
      {key |> atomize_key(), to_keyword_list(value)}
    end)
    |> Enum.into([])
  end

  def to_keyword_list(leaf), do: leaf

  @spec atomize_key(atom | binary) :: atom
  defp atomize_key(key) when is_binary(key), do: key |> String.to_atom()
  defp atomize_key(key) when is_atom(key), do: key
end
