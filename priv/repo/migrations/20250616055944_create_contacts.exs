defmodule OmpluseBackend.Repo.Migrations.CreateContacts do
  use Ecto.Migration

   def change do
    create table(:contacts) do
      add :phone_number, :string, null: false
      add :name, :string
      add :user_id, references(:users)
      add :company_id, references(:companies)
      add :campaign_id, references(:campaigns)

      timestamps()
    end

    create unique_index(:contacts, [:phone_number, :campaign_id])
  end
end
