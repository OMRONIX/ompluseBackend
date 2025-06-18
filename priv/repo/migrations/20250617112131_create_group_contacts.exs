defmodule OmpluseBackend.Repo.Migrations.CreateGroupContacts do
  use Ecto.Migration

  def change do
    create table(:group_contacts) do
      add :group_id, references(:groups), null: false
      add :phone_number, :string, null: false
      add :name, :string

      timestamps()
    end

    create unique_index(:group_contacts, [:group_id, :phone_number])
  end
end
