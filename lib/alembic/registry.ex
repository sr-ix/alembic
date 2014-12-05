defmodule Alembic.Registry do
  use GenServer

  ## Client API

  @doc """
  Start the registry.
  """
  def start_link(table, event_manager, activities, opts \\ []) do
    GenServer.start_link(__MODULE__, {table, event_manager, activities}, opts)
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
  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{^name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end

  @doc """
  Ensures there is an activity associated to the given `name` in `server`
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server Callbacks

  def init({table, events, activities}) do
    refs = :ets.foldl(fn {name, pid}, acc ->
      HashDict.put(acc, Process.monitor(pid), name)
    end, HashDict.new, table)
    
    {:ok, %{names: table, refs: refs, events: events, activities: activities}}
  end

  def handle_call({:create, name}, _from, state) do
    case lookup(state.names, name) do
      {:ok, pid} ->
        {:reply, pid, state}
      :error ->
        {:ok, pid} = Alembic.Activity.Supervisor.start_activity(state.activities)
        ref = Process.monitor(pid)
        refs = HashDict.put(state.refs, ref, name)
        :ets.insert(state.names, {name, pid})
        GenEvent.sync_notify(state.events, {:create, name, pid})
        {:reply, pid, %{state | refs: refs}}
    end
  end

  def handle_call({:stop, _from, state}) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    :ets.delete(state.names, name)
    GenEvent.sync_notify(state.events, {:exit, name, pid})
    {:noreply, %{state | refs: refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
