defmodule OmpluseBackend.Repo.Migrations.AddTemplateIdToTemplates do
  use Ecto.Migration

  def change do
    alter table(:templates) do
      add :template_id, :string
    end
  end
end
