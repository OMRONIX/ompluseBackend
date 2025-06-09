defmodule OmpluseBackend.Repo.Migrations.AddPasswordHashToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :password_hash, :string
    end

  end
end
