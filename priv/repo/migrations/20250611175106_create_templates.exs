defmodule OmpluseBackend.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add :entity_id, references(:dlt_entities, on_delete: :nilify_all)
      add :sender_id, references(:senders, on_delete: :nilify_all)
      add :template_content, :text, null: false
      add :template_type, :string, null: false
      add :template_status, :string, default: "pending"
      add :template_id, :string
      timestamps()
    end

    create unique_index(:templates, [:dlt_template_id])

  end
end
