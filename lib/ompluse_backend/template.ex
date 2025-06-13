defmodule OmpluseBackend.Template do
  use Ecto.Schema
  import Ecto.Changeset

  schema "templates" do
    field :template_content, :string
    field :template_type, Ecto.Enum, values: [:transactional, :promotional, :service_implicit, :service_explicit], default: :transactional
    field :template_status, Ecto.Enum, values: [:pending, :approved, :rejected], default: :pending
    field :dlt_template_id, :string
    belongs_to :entity, OmpluseBackend.DltEntity
    belongs_to :sender, OmpluseBackend.Sender
    timestamps()
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:template_content, :template_type, :template_status, :dlt_template_id, :entity_id, :sender_id])
    |> validate_required([:template_content, :template_type, :entity_id, :sender_id])
    |> unique_constraint(:dlt_template_id)
  end
end
