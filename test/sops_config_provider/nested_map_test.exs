defmodule SopsConfigProvider.NestedMapTest do
  use ExUnit.Case, async: true

  alias SopsConfigProvider.NestedMap

  describe "test to_keyword_list/1" do
    setup %{} do
      map = %{
        "a" => "b",
        "c" => %{
          "d" => "e",
          "f" => %{
            "g" => "h"
          }
        }
      }

      %{map: map}
    end

    test "converts nested map to keyword list", %{map: map} do
      assert NestedMap.to_keyword_list(map) == [
               a: "b",
               c: [
                 d: "e",
                 f: [
                   g: "h"
                 ]
               ]
             ]
    end
  end
end
