defmodule Alembic.ActivityTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, activity} = Alembic.Activity.start_link
    {:ok, activity: activity}
  end

  test "store values by any key", %{activity: activity} do
    assert Alembic.Activity.get(activity, "milk") == nil

    Alembic.Activity.put(activity, "milk", 3)
    assert Alembic.Activity.get(activity, "milk") == 3

    assert Alembic.Activity.delete(activity, "milk") == 3
    assert Alembic.Activity.get(activity, "milk") == nil
  end
end
