defmodule InfisicalExTest do
  use ExUnit.Case
  doctest InfisicalEx

  # test "Hackney starts automatically" do
  #   {:ok, _} = InfisicalEx.get_secret("DATABASE_PASSWORD", "dev")

  #   assert Enum.any?(Application.started_applications(), fn {app, _, _} -> app == :hackney end)
  # end
end
