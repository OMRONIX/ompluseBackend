defmodule OmpluseBackend.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :user_name, :credits, :credits_used, :company_id, :inserted_at, :updated_at]}
  schema "users" do
    field :user_name, :string
    field :password_hash, :string
    field :user_data, :map
    field :credits, :float, default: 0.0
    field :credits_used, :float, default: 0.0
    field :reset_password_token, :string
    field :reset_password_expires_at, :utc_datetime
    belongs_to :company, OmpluseBackend.Company
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_name, :password_hash, :user_data, :credits, :credits_used, :reset_password_token, :reset_password_expires_at, :company_id])
    |> validate_required([:user_name, :company_id])
    |> unique_constraint(:user_name)
  end
end
