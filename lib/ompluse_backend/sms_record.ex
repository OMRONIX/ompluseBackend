defmodule OmpluseBackend.SmsRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sms_records" do
    field :recipient_phone, :string
    field :message, :string
    field :status, Ecto.Enum, values: [:pending, :sent, :failed], default: :pending
    belongs_to :sender, OmpluseBackend.Sender
    belongs_to :template, OmpluseBackend.Template
    belongs_to :campaign, OmpluseBackend.Campaign
    belongs_to :user, OmpluseBackend.User
    timestamps()
  end

  def changeset(sms_record, attrs) do
    sms_record
    |> cast(attrs, [:recipient_phone, :message, :status, :sender_id, :template_id, :campaign_id, :user_id])
    |> validate_required([:recipient_phone, :message, :sender_id, :template_id, :user_id])
    |> validate_format(:recipient_phone, ~r/^\+\d{10,15}$/, message: "Invalid phone number")
  end
end
