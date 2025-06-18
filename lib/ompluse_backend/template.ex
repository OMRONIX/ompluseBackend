defmodule OmpluseBackend.Template do
  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :template_content, :string
    field :template_type, :string
    field :template_status, Ecto.Enum, values: [:pending, :approved, :rejected], default: :pending
    field :template_id, :string
    belongs_to :entity, OmpluseBackend.DltEntity
    belongs_to :sender, OmpluseBackend.Sender
    timestamps()
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:template_content, :template_type, :template_status,  :entity_id, :sender_id, :template_id])
    |> validate_required([:template_content, :template_type, :entity_id, :sender_id, :template_id])
    |> unique_constraint(:template_id)
    |> validate_format(:template_id, ~r/^\d{19}$/, message: "must be a 9 digit")
  end
end
