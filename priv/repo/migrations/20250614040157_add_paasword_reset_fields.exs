defmodule OmpluseBackend.Repo.Migrations.AddPaaswordResetFields do
  use Ecto.Migration

 def change do
    alter table(:users) do
      add :reset_password_token, :string
      add :reset_password_expires_at, :utc_datetime
    end

    alter table(:companies) do
      add :reset_password_token, :string
      add :reset_password_expires_at, :utc_datetime
    end
  end
end
