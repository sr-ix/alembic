defmodule Alembic.RegistryTest do
  use ExUnit.Case, async: true

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    {:ok, sup} = Alembic.Activity.Supervisor.start_link
    {:ok, manager} = GenEvent.start_link
    {:ok, registry} = Alembic.Registry.start_link(manager, sup)

    GenEvent.add_mon_handler(manager, Forwarder, self())
    {:ok, registry: registry}
  end

  test "spawns activities", %{registry: registry} do
    assert Alembic.Registry.lookup(registry, "shopping") == :error

    Alembic.Registry.create(registry, "shopping")
    assert {:ok, activity} = Alembic.Registry.lookup(registry, "shopping")

    Alembic.Activity.put(activity, "milk", 1)
    assert Alembic.Activity.get(activity, "milk") == 1
  end

  test "removes activities on exit", %{registry: registry} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(registry, "shopping")
    Agent.stop(activity)
    assert Alembic.Registry.lookup(registry, "shopping") == :error
  end

  test "sends events on create and crash", %{registry: registry} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(registry, "shopping")
    assert_receive {:create, "shopping", ^activity}

    Agent.stop(activity)
    assert_receive {:exit, "shopping", ^activity}
  end

  test "removes activity on crash", %{registry: registry} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(registry, "shopping")

    # Kill the activity and wait for the notification
    Process.exit(activity, :shutdown)
    assert_receive {:exit, "shopping", ^activity}
    assert Alembic.Registry.lookup(registry, "shopping") == :error
  end
end
