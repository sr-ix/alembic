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
    ets = :ets.new(:registry_table, [:set, :public])
    registry = start_registry(ets)
    {:ok, registry: registry, ets: ets}
  end

  defp start_registry(ets) do
    {:ok, sup} = Alembic.Activity.Supervisor.start_link
    {:ok, manager} = GenEvent.start_link
    {:ok, registry} = Alembic.Registry.start_link(ets, manager, sup)

    GenEvent.add_mon_handler(manager, Forwarder, self())
    registry
  end

  test "spawns activities", %{registry: registry, ets: ets} do
    assert Alembic.Registry.lookup(ets, "shopping") == :error

    Alembic.Registry.create(registry, "shopping")
    assert {:ok, activity} = Alembic.Registry.lookup(ets, "shopping")

    Alembic.Activity.put(activity, "milk", 1)
    assert Alembic.Activity.get(activity, "milk") == 1
  end

  test "removes activities on exit", %{registry: registry, ets: ets} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(ets, "shopping")
    Agent.stop(activity)
    assert_receive {:exit, "shopping", ^activity}
    assert Alembic.Registry.lookup(ets, "shopping") == :error
  end

  test "sends events on create and crash", %{registry: registry, ets: ets} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(ets, "shopping")
    assert_receive {:create, "shopping", ^activity}

    Agent.stop(activity)
    assert_receive {:exit, "shopping", ^activity}
  end

  test "removes activity on crash", %{registry: registry, ets: ets} do
    Alembic.Registry.create(registry, "shopping")
    {:ok, activity} = Alembic.Registry.lookup(ets, "shopping")

    # Kill the activity and wait for the notification
    Process.exit(activity, :shutdown)
    assert_receive {:exit, "shopping", ^activity}
    assert Alembic.Registry.lookup(ets, "shopping") == :error
  end

  test "monitors existing entries", %{registry: registry, ets: ets} do
    activity = Alembic.Registry.create(registry, "shopping")

    # Kill the registry. We unlink first, otherwise it will kill the test
    Process.unlink(registry)
    Process.exit(registry, :shutdown)

    # Start a new registry with the existing table and access the activity
    start_registry(ets)
    assert Alembic.Registry.lookup(ets, "shopping") == {:ok, activity}

    # Once the activity dies, we should receive notifications
    Process.exit(activity, :shutdown)
    assert_receive {:exit, "shopping", ^activity}
    assert Alembic.Registry.lookup(ets, "shopping") == :error
  end
end
