defmodule OmpluseBackend.Repo.Migrations.CrearteSmsRecords do
  use Ecto.Migration

  def change do
    create table(:sms_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uuid, :uuid
      add :user_id, :string
      add :seq_id, :integer
      add :entity_id, :string, null: false
      add :sender_id, :string, null: false
      add :template_id, :string, null: false
      add :gateway_id, :string
      add :dlr_status, :string, default: "PENDING"
      add :submit_ts, :utc_datetime
      add :dlr_ts, :utc_datetime
      add :message, :string, null: false
      add :phone_number, :string, null: false
      add :telco_id, :string

      timestamps()
    end

    create index(:sms_records, [:user_id])
    create index(:sms_records, [:entity_id])
    create index(:sms_records, [:sender_id])
    create index(:sms_records, [:template_id])
    create unique_index(:sms_records, [:uuid])
  end
end
