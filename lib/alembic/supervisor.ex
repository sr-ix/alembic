defmodule Alembic.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @manager_name Alembic.EventManager
  @activity_sup_name Alembic.Activity.Supervisor
  @registry_name Alembic.Registry

  def init(:ok) do
    children = [
      worker(GenEvent, [[name: @manager_name]]),
      supervisor(Alembic.Activity.Supervisor, [[name: @activity_sup_name]]),
      worker(Alembic.Registry, [@manager_name, @activity_sup_name, [name: @registry_name]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
