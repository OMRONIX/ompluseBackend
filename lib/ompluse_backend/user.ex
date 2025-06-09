defmodule OmpluseBackend.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :user_data, :map
    field :user_name, :string
    field :password_hash, :string
    belongs_to :company, OmpluseBackend.Company

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_name, :password_hash, :user_data, :company_id])
    |> validate_required([:user_name, :password_hash, :company_id])
    |> unique_constraint(:user_name)
  end
end
