defmodule OmpluseBackend.Repo.Migrations.AddPrincipalEntityIdInCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :principal_entity_id, :string
    end

  end
end
