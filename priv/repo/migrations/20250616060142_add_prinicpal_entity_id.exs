defmodule OmpluseBackend.Repo.Migrations.AddPrinicpalEntityId do
  use Ecto.Migration
def change do
    alter table(:users) do
      add :principal_entity_id, :string
    end

    alter table(:companies) do
      add :principal_entity_id, :string
    end
  end
end
