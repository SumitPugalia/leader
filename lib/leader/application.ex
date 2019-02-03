defmodule Leader.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # Starts a worker by calling: Leader.Worker.start_link(arg)
      # {Leader.Worker, arg}
      Leader.Repo,
      worker(Leader.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Leader.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
