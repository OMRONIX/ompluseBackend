defmodule OmpluseBackend.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  schema "campaigns" do
    field :name, :string
    field :status, :string, default: "draft"
    belongs_to :user, OmpluseBackend.User
    belongs_to :entity, OmpluseBackend.DltEntity
    belongs_to :sender, OmpluseBackend.Sender
    belongs_to :template, OmpluseBackend.Template
    timestamps()
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :status, :user_id, :entity_id, :sender_id, :template_id])
    |> validate_required([:name, :user_id, :entity_id, :sender_id, :template_id])
  end
end
