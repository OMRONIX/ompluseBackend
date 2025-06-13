defmodule OmpluseBackend.Repo.Migrations.CreateSenders do
  use Ecto.Migration

  def change do
    create table(:senders) do
      add :entity_id, references(:dlt_entities, on_delete: :nilify_all)
      add :sender_id, :string, null: false
      add :desc, :text
      add :status, :string, default: "pending"
      add :approved_by, :string
      add :approved_on, :date
      timestamps()
    end

    create index(:senders, [:entity_id])

  end
end
