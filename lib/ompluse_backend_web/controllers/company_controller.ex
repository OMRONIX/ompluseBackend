defmodule OmpluseBackendWeb.CompanyController do
  use OmpluseBackendWeb, :controller
  alias OmpluseBackend.{Repo, Company, DltManager}
  alias OmpluseBackendWeb.AuthGuardian
  alias Pbkdf2

  def register(conn, %{"company" => company_params}) do
    case Repo.get_by(Company, company_name: company_params["company_name"]) do
      nil ->
        changeset = Company.changeset(%Company{}, company_params)
        case Repo.insert(changeset) do
          {:ok, company} ->
            {:ok, token, _claims} = AuthGuardian.encode_and_sign(company)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{token: token}))
          {:error, changeset} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: format_errors(changeset)}))
        end
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Company name already exists"}))
    end
  end

  def login(conn, %{"company_name" => company_name, "password" => password}) do
    case Repo.get_by(Company, company_name: company_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid company name or password"}))
      company ->
        case Pbkdf2.verify_pass(password, company.password_hash) do
          true ->
            {:ok, token, _claims} = AuthGuardian.encode_and_sign(company)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{token: token}))
          false ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: "Invalid company name or password"}))
        end
    end
  end

  def list_users(conn, %{"company_id" => company_id}) do
    case Guardian.Plug.current_resource(conn) do
      %Company{} ->
        users = DltManager.list_company_users(company_id)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: users}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Forbidden"}))
    end
  end

  def add_user(conn, %{"company_id" => company_id, "user" => user_params}) do
    case Guardian.Plug.current_resource(conn) do
      %Company{id: id} ->
        case DltManager.add_company_user(%Company{id: id}, user_params) do
          {:ok, user} ->
            dashboard_data = DltManager.user_dashboard_data(user)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{data: dashboard_data}))
          {:error, changeset} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: format_errors(changeset)}))
        end
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Forbidden"}))
    end
  end

  def assign_credits(conn, %{"company_id" => company_id, "user_id" => user_id, "credits" => credits}) do
    case Guardian.Plug.current_resource(conn) do
      %Company{} ->
        case DltManager.assign_credits(company_id, user_id, credits) do
          {:ok, user} ->
            dashboard_data = DltManager.user_dashboard_data(user)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: dashboard_data}))
          {:error, reason} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{error: reason}))
        end
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Forbidden"}))
    end
  end

  def delete_user(conn, %{"company_id" => company_id, "user_id" => user_id}) do
    case Guardian.Plug.current_resource(conn) do
      %Company{} ->
        case DltManager.delete_company_user(company_id, user_id) do
          {:ok, user} ->
            # dashboard_data = DltManager.user_dashboard_data(user)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{message: "User deleted successfully"}))
          {:error, reason} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{error: reason}))
        end
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Forbidden"}))
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
