defmodule Alembic.Registry do
  use GenServer

  ## Client API

  @doc """
  Start the registry.
  """
  def start_link(event_manager, activities, opts \\ []) do
    GenServer.start_link(__MODULE__, {event_manager, activities}, opts)
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.call(server, :stop)
  end

  @doc """
  Looks up the activity pid for the `name` stored in `server`.

  Returns `{:ok, pid}` if the activity exists; `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is an activity associated to the given `name` in `server`
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server Callbacks

  def init({events, activities}) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, %{names: names, refs: refs, events: events, activities: activities}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, HashDict.fetch(state.names, name), state}
  end

  def handle_call({:create, name}, _from, state) do
    if HashDict.get(state.names, name) do
      {:noreply, state}
    else
      {:ok, pid} = Alembic.Activity.Supervisor.start_activity(state.activities)
      ref = Process.monitor(pid)
      refs = HashDict.put(state.refs, ref, name)
      names = HashDict.put(state.names, name, pid)

      GenEvent.sync_notify(state.events, {:create, name, pid})
      {:noreply, %{state | names: names, refs: refs}}
    end
  end

  def handle_call({:stop, _from, state}) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    names = HashDict.delete(state.names, name)

    GenEvent.sync_notify(state.events, {:exit, name, pid})
    {:noreply, %{state | names: names, refs: refs}}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
