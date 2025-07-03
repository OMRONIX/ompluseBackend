defmodule OmpluseBackend.Auth do
  import Ecto.Query
  alias OmpluseBackend.{Repo, User, Company}
  alias Pbkdf2

  # -- Registration Functions --

  def register_user(attrs) do
    attrs = hash_password_if_present(attrs)
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def register_company(attrs) do
    attrs = hash_password_if_present(attrs)
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  defp hash_password_if_present(attrs) do
    case Map.get(attrs, "password") do
      nil -> attrs
      password -> Map.put(attrs, "password_hash", Pbkdf2.hash_pwd_salt(password))
    end
  end

  # -- Login Functions --

  def login_user(user_name, password) do
    user = Repo.get_by(User, user_name: user_name)

    case user do
      nil -> {:error, :invalid_credentials}
      %User{} ->
        if Pbkdf2.verify_pass(password, user.password_hash) do
          {:ok, user, generate_token(user)}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def login_company(company_name, password) do
    company = Repo.get_by(Company, company_name: company_name)

    case company do
      nil -> {:error, :invalid_credentials}
      %Company{} ->
        if Pbkdf2.verify_pass(password, company.password_hash) do
          {:ok, company, generate_token(company)}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  # -- Password Reset --

  def generate_password_reset_token(user_or_company) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    expires_at = DateTime.utc_now() |> DateTime.add(3600, :second)

    changeset =
      Ecto.Changeset.change(user_or_company,
        reset_password_token: token,
        reset_password_expires_at: expires_at
      )

    case Repo.update(changeset) do
      {:ok, resource} -> {:ok, resource, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def send_password_reset_email(user_or_company, token) do
    identifier =
      case user_or_company do
        %User{} -> user_or_company.user_name
        %Company{} -> user_or_company.company_name
      end

    IO.puts("Sending password reset email to #{identifier} with token: #{token}")
    {:ok, :email_sent}
  end

  def reset_password(user_name, token, new_password) do
    resource =
      Repo.get_by(User, reset_password_token: token, user_name: user_name) ||
        Repo.get_by(Company, reset_password_token: token, company_name: user_name)

    with %{} = resource <- resource,
         true <- not is_nil(resource.reset_password_expires_at) and
                 DateTime.compare(resource.reset_password_expires_at, DateTime.utc_now()) == :gt do
      changeset =
        resource
        |> Ecto.Changeset.change(%{
          password_hash: Pbkdf2.hash_pwd_salt(new_password),
          reset_password_token: nil,
          reset_password_expires_at: nil
        })

      Repo.update(changeset)
    else
      nil -> {:error, :invalid_token}
      false -> {:error, :token_expired}
    end
  end

  # -- Utility --

  def list_users_for_company(company_id) do
    from(u in User, where: u.company_id == ^company_id, select: [:id, :user_name, :user_data])
    |> Repo.all()
  end

  def get_user(id), do: Repo.get(User, String.to_integer(id))
  def get_company(id), do: Repo.get(Company, String.to_integer(id))

  defp generate_token(resource) do
    {:ok, token, _claims} = OmpluseBackendWeb.AuthGuardian.encode_and_sign(resource)
    token
  end
end
