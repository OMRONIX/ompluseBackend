defmodule OmpluseBackend.Auth do
  import Ecto.Query
  alias OmpluseBackend.{Repo, User, Company}
  alias Pbkdf2

  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def register_company(attrs) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def login_user(user_name, password) do
    user = Repo.get_by(User, user_name: user_name)

    case user do
      nil ->
        {:error, :invalid_credentials}

      user ->
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
      nil ->
        {:error, :invalid_credentials}

      company ->
        if Pbkdf2.verify_pass(password, company.password_hash) do
          {:ok, company, generate_token(company)}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  def list_users_for_company(company_id) do
    query = from u in User, where: u.company_id == ^company_id, select: [:id, :user_name, :user_data]
    Repo.all(query)
  end

  def get_user(id) do
    Repo.get(User, String.to_integer(id))
  end

  def get_company(id) do
    Repo.get(Company, String.to_integer(id))
  end


  def generate_password_reset_token(user_or_company) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    expires_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(3600, :second) # 1 hour expiry

    case user_or_company do
      %User{} = user ->
        changeset = Ecto.Changeset.change(user, reset_password_token: token, reset_password_expires_at: expires_at)
        Repo.update(changeset)

      %Company{} = company ->
        changeset = Ecto.Changeset.change(company, reset_password_token: token, reset_password_expires_at: expires_at)
        Repo.update(changeset)
    end
    |> case do
      {:ok, resource} -> {:ok, resource, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def send_password_reset_email(user_or_company, token) do
    # In a real implementation, this would send an email
    # For this example, we'll return a mock success
    identifier = case user_or_company do
      %User{} -> user_or_company.user_name
      %Company{} -> user_or_company.company_name
    end
    IO.puts("Sending password reset email to #{identifier} with token: #{token}")
    {:ok, :email_sent}
  end

  def reset_password(user_name, token, new_password) do
    resource = Repo.get_by(User, reset_password_token: token, user_name: user_name) ||
               Repo.get_by(Company, reset_password_token: token, company_name: user_name)

    with %{} = resource <- resource,
         true <- !is_nil(resource.reset_password_expires_at) && DateTime.compare(resource.reset_password_expires_at, DateTime.utc_now()) == :gt do
      changeset =
        case resource do
          %User{} ->
            User.changeset(resource, %{
              password_hash: Pbkdf2.hash_pwd_salt(new_password),
              reset_password_token: nil,
              reset_password_expires_at: nil
            })
          %Company{} ->
            Company.changeset(resource, %{
              password_hash: Pbkdf2.hash_pwd_salt(new_password),
              reset_password_token: nil,
              reset_password_expires_at: nil
            })
        end

      Repo.update(changeset)
    else
      nil -> {:error, :invalid_token}
      false -> {:error, :token_expired}
    end
  end


  defp generate_token(resource) do
    {:ok, token, _claims} = OmpluseBackendWeb.AuthGuardian.encode_and_sign(resource)
    token
  end
end
