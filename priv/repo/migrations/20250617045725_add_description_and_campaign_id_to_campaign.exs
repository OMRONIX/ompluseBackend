defmodule OmpluseBackend.Repo.Migrations.AddDescriptionAndCampaignIdToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :desc, :string
      add :campaign_id, :string
    end
  end
end
