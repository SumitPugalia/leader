defmodule Leader.Model.NodeDetails do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :name,
    :is_master
  ]

  @primary_key {:id, :id, autogenerate: true}
  schema "node_details" do
    field(:name, :string)
    field(:is_master, :boolean, default: false)
  end

  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  @doc false
  def changeset(node_details, attrs) do
    node_details
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:name, [{:message, "Node with same name already exists"}])
  end
end
