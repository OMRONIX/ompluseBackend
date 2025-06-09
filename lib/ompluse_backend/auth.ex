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

  defp generate_token(resource) do
    {:ok, token, _claims} = OmpluseBackendWeb.AuthGuardian.encode_and_sign(resource)
    token
  end
end
