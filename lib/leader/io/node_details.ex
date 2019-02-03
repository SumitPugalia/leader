defmodule Leader.IO.NodeDetails do
  alias Leader.Model.NodeDetails
  alias Leader.Repo
  import Ecto.Query

  def create(args) do
    args
    |> NodeDetails.changeset()
    |> Repo.insert!()
  end

  def get_all_nodes() do
    query =
      from(n in NodeDetails,
        select: n.name
      )

    query
    |> Repo.all()
    |> Enum.map(fn node -> String.to_atom(node) end)
  end

  def get_master_node() do
    query =
      from(n in NodeDetails,
        select: n.name,
        where: n.is_master == true
      )

    query
    # change to one
    |> Repo.one()
    |> String.to_atom()
  end
end
