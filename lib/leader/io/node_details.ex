defmodule Leader.IO.NodeDetails do
  alias Leader.Model.NodeDetails
  alias Leader.Repo
  import Ecto.Query

  def create(args) do
    args
    |> NodeDetails.changeset()
    |> Repo.insert()
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
    |> Repo.all()
    |> List.first()
  end

  def get_nodes_by_greater_than_id(id) do
    query =
      from(n in NodeDetails,
        select: n.name,
        where: n.id > ^id
      )

    query
    |> Repo.all()
    |> Enum.map(fn node -> String.to_atom(node) end)
  end

  def get_id(name) do
    query =
      from(n in NodeDetails,
        select: n.id,
        where: n.name == ^name
      )

    query
    |> Repo.one()
  end

  def update(node_name, %{is_master: is_master}) do
    query = from nd in NodeDetails, where: nd.name == ^node_name

    case Repo.update_all(query, set: [is_master: is_master]) do
      {1, nil} ->
        :ok

      {_, nil} ->
        IO.puts("Database Failure")
    end
  end
end
