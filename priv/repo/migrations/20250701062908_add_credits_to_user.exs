defmodule OmpluseBackend.Repo.Migrations.AddCreditsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :credits, :float, default: 0.0
      add :credits_used, :float, default: 0.0
    end
  end
end
