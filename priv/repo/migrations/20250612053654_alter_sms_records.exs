defmodule OmpluseBackend.Repo.Migrations.AlterSmsRecords do
  use Ecto.Migration

  def change do
      create table(:sms_records) do
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :sender_id, references(:senders, on_delete: :nilify_all)
      add :campaign_id, references(:campaigns, on_delete: :nilify_all)
    end
  end
end
