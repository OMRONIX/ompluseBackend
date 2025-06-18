defmodule OmpluseBackend.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :phone_number, :string
    field :name, :string
    belongs_to :user, OmpluseBackend.User
    belongs_to :company, OmpluseBackend.Company
    belongs_to :campaign, OmpluseBackend.Campaign

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:phone_number, :name, :user_id, :company_id, :campaign_id])
    |> validate_required([:phone_number, :campaign_id])
    |> unique_constraint(:phone_number, name: :contacts_phone_number_campaign_id_index)
    |> validate_format(:phone_number, ~r/^\d{10}$/, message: "must be a 10 digit phone number")
  end


end
