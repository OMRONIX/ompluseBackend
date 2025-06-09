defmodule OmpluseBackendWeb.CompanyController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.Auth
  alias Pbkdf2
  alias OmpluseBackendWeb.AuthGuardian

  def register(conn, %{"company" => company_params}) do
    company_params = Map.put(company_params, "password_hash", Pbkdf2.hash_pwd_salt(company_params["password"]))

    case Auth.register_company(company_params) do
      {:ok, company} ->
        {:ok, token, _claims} = AuthGuardian.encode_and_sign(company)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{token: token, company: %{id: company.id, company_name: company.company_name}}))

      {:error, changeset} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
    end
  end

  def login(conn, %{"company_name" => company_name, "password" => password}) do
    case Auth.login_company(company_name, password) do
      {:ok, company, token} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{token: token, company: %{id: company.id, company_name: company.company_name}}))

      {:error, :invalid_credentials} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid credentials"}))
    end
  end

  def list_users(conn, _params) do
    company = Guardian.Plug.current_resource(conn)
    users = Auth.list_users_for_company(company.id)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{users: users}))
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
