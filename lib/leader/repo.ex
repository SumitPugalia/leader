defmodule Leader.Repo do
  use Ecto.Repo,
    otp_app: :leader,
    adapter: Ecto.Adapters.Postgres
end
