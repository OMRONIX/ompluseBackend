defmodule OmpluseBackend.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :user_data, :map
    field :user_name, :string
    field :password_hash, :string
    field :reset_password_token, :string
    field :reset_password_expires_at, :utc_datetime
    belongs_to :company, OmpluseBackend.Company

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_name, :password_hash, :user_data, :company_id, :reset_password_token, :reset_password_expires_at])
    |> validate_required([:user_name, :password_hash, :company_id])
    |> unique_constraint(:user_name)
    |> unique_constraint(:email)
    |> validate_length(:user_name, min: 3, max: 20)
    |> validate_length(:password_hash, min: 6)
    |> validate_format(:user_name, ~r/^[a-zA-Z0-9_]+$/, message: "can only contain letters, numbers, and underscores")
  end
end
