defmodule OmpluseBackend.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :tan, :string
    field :address, :string
    field :gst, :string
    field :company_name, :string
    field :contact_number, :string
    field :pan, :string
    field :cin, :string
    field :business_type, :string
    field :website_url, :string
    field :password_hash, :string
    field :reset_password_token, :string
    field :reset_password_expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:company_name, :contact_number, :address, :pan, :gst, :tan, :cin, :business_type, :website_url, :password_hash])
    |> validate_required([:company_name, :password_hash])
    |> unique_constraint(:company_name)
  end
end
