defmodule OmpluseBackend.GroupContact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "group_contacts" do
    field :phone_number, :string
    field :name, :string
    belongs_to :group, OmpluseBackend.Group


    timestamps()
  end

  def changeset(group_contact, attrs) do
    group_contact
    |> cast(attrs, [:phone_number, :name, :group_id])
    |> validate_required([:phone_number, :group_id])
    |> validate_format(:phone_number, ~r/^\d{10}$/, message: "must be a 10-digit phone number")
    |> unique_constraint([:group_id, :phone_number])
  end
end
