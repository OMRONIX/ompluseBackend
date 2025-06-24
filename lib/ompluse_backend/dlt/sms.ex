defmodule OmpluseBackend.Dlt.Sms do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "sms_records" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :user_id, :string
    field :seq_id, :integer
    field :entity_id, :string
    field :sender_id, :string
    field :template_id, :string
    field :gateway_id, :string
    field :dlr_status, :string, default: "PENDING"
    field :submit_ts, :utc_datetime
    field :dlr_ts, :utc_datetime
    field :message, :string
    field :phone_number, :string
    field :telco_id, :string

    timestamps()
  end

  def changeset(sms, attrs) do
    sms
    |> cast(attrs, [
      :user_id,
      :seq_id,
      :entity_id,
      :sender_id,
      :template_id,
      :gateway_id,
      :dlr_status,
      :submit_ts,
      :dlr_ts,
      :message,
      :phone_number,
      :telco_id
    ])
    |> validate_required([
      :user_id,
      :entity_id,
      :sender_id,
      :template_id,
      :message,
      :phone_number
    ])
    |> validate_format(:phone_number, ~r/^\d{10}$/, message: "must be a 10-digit phone number")
    |> validate_format(:sender_id, ~r/^[A-Z0-9]{6}$/, message: "must be a 6-character alphanumeric string")
    |> validate_format(:template_id, ~r/^\d{19}$/, message: "must be a 19-digit string")
  end

end
