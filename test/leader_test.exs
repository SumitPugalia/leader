defmodule LeaderTest do
  use ExUnit.Case
  doctest Leader

  test "greets the world" do
    assert Leader.hello() == :world
  end
end
