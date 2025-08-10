defmodule BeholderTest do
  use ExUnit.Case
  doctest Beholder

  test "greets the world" do
    assert Beholder.hello() == :world
  end
end
