defmodule Alembic.Activity do
  @doc """
  Starts a new activity.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

  @doc """
  Get a `value` from the activity.
  """
  def get(activity, key) do
    Agent.get(activity, &HashDict.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `activity`.
  """
  def put(activity, key, value) do
    Agent.update(activity, &HashDict.put(&1, key, value))
  end

  @doc """
  Deletes `key` from `activity`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(activity, key) do
    Agent.get_and_update(activity, fn dict ->
      HashDict.pop(dict, key)
    end)
  end
end
