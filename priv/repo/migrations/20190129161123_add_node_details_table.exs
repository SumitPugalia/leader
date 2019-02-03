defmodule Leader.Repo.Migrations.AddNodeDetailsTable do
  use Ecto.Migration

  def change do
  	create table(:node_details, primary_key: false) do
      add(:id, :serial, primary_key: true)
      add(:name, :string, unique: true)
      add(:is_master, :boolean)

    end

    create(unique_index(:node_details, [:name]))
  end
end
