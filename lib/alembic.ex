defmodule Alembic do
  use Application

  def start(_type, _args) do
    Alembic.Supervisor.start_link
  end
end
