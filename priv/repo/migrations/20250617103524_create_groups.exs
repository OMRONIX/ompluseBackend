defmodule OmpluseBackend.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string, null: false
      add :user_id, references(:users)
      add :company_id, references(:companies)

      timestamps()
    end
  end
end
