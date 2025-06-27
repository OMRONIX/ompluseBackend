defmodule OmpluseBackend.Repo.Migrations.AddOtherElemToSmsRecords do
  use Ecto.Migration

  def change do
     alter table(:sms_records) do
      add :api_key, :string
      add :channel, :string
      add :telemar_id, :string
      add :count, :string
      add :flash, :boolean
      add :multipart, :boolean
      add :part_id, :string
      add :is_primary, :boolean
      add :part_info, :string
      add :cost, :string
      add :cost_unit, :string
      add :encode, :string
      add :company_id, :string
      add :dlt_error_code, :string
      add :porter_id, :string

    end

  end
end
