defmodule OmpluseBackend.Sender do
  use Ecto.Schema
  import Ecto.Changeset

  schema "senders" do
    field :sender_id, :string
    field :desc, :string
    field :status, Ecto.Enum, values: [:pending, :approved, :rejected], default: :pending
    field :approved_by, :string
    field :approved_on, :date
    belongs_to :entity, OmpluseBackend.DltEntity
    timestamps()
  end

  def changeset(sender, attrs) do
    sender
    |> cast(attrs, [:sender_id, :desc, :status, :approved_by, :approved_on, :entity_id])
    |> validate_required([:sender_id, :entity_id])
    |> validate_length(:sender_id, is: 6)
  end
end
