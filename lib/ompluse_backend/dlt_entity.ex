defmodule OmpluseBackend.DltEntity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dlt_entities" do
    field :ueid, :string
    field :entity_name, :string
    field :letter_of_authorization_url, :string
    field :entity_type, :string
    field :verification_status, :string, default: "pending"
    field :telecom_operator, :string
    belongs_to :user, OmpluseBackend.User
    timestamps()
  end

  def changeset(dlt_entity, attrs) do
    dlt_entity
    |> cast(attrs, [:ueid, :entity_name, :letter_of_authorization_url, :entity_type, :verification_status, :telecom_operator, :user_id])
    |> validate_required([:ueid, :entity_type, :user_id])
    |> unique_constraint(:ueid)
    |> validate_format(:ueid, ~r/^\d{19}$/, message: "must be a 9 digit")
  end
end
