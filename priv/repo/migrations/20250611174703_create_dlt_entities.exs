defmodule OmpluseBackend.Repo.Migrations.CreateDltEntities do
  use Ecto.Migration

  def change do
    create table(:dlt_entities) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :ueid, :string, null: false
      add :entity_name, :string
      add :letter_of_authorization_url, :string
      add :entity_type, :string, null: false
      add :verification_status, :string, default: "pending"
      add :telecom_operator, :string
      timestamps()
    end

    create unique_index(:dlt_entities, [:ueid], name: :unique_ueid_index)
  end
end
