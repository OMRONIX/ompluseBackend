defmodule OmpluseBackend.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    belongs_to :user, OmpluseBackend.User
    belongs_to :company, OmpluseBackend.Company

    timestamps()
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :user_id, :company_id])
    |> validate_required([:name])
  end
end
