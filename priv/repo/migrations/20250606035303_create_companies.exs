defmodule OmpluseBackend.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :company_name, :string
      add :contact_number, :string
      add :address, :string
      add :pan, :string
      add :gst, :string
      add :tan, :string
      add :cin, :string
      add :business_type, :string
      add :website_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
