defmodule OmpluseBackend.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :user_id, references(:users, on_delete: :nilify_all)
      add :entity_id, references(:dlt_entities, on_delete: :nilify_all)
      add :sender_id, references(:senders, on_delete: :nilify_all)
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :name, :string
      add :status, :string, default: "draft"
      timestamps()
    end
  end
end
