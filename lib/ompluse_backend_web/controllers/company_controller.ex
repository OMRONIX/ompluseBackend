defmodule OmpluseBackendWeb.CompanyController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.DltManager
  alias OmpluseBackendWeb.AuthGuardian

def register(conn, %{"company" => company_params}) do
  case OmpluseBackend.Auth.register_company(company_params) do
    {:ok, company} ->
      {:ok, token, _claims} = AuthGuardian.encode_and_sign(company)
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, Jason.encode!(%{
        token: token,
        company: %{
          id: company.id,
          company_name: company.company_name
        }
      }))

    {:error, changeset} ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
  end
end

  def login(conn, %{"company_name" => company_name, "password" => password}) do
    case OmpluseBackend.Auth.login_company(company_name, password) do
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

  def list_users(conn, %{"company_id" => company_id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized: No company logged in"}))

      %OmpluseBackend.Company{id: current_company_id} = _company ->
        if to_string(current_company_id) == company_id do
          users = DltManager.list_company_users(company_id)
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: users}))
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "Forbidden: Company ID mismatch"}))
        end
    end
  end

  def add_user(conn, %{"company_id" => company_id, "user" => user_params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized: No company logged in"}))

      %OmpluseBackend.Company{id: current_company_id} = company ->
        if to_string(current_company_id) == company_id do
          case DltManager.add_company_user(company, user_params) do
            {:ok, user} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(201, Jason.encode!(%{data: %{id: user.id, user_name: user.user_name, credits: user.credits}}))

            {:error, changeset} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
          end
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "Forbidden: Company ID mismatch"}))
        end
    end
  end

  def assign_credits(conn, %{"company_id" => company_id, "user_id" => user_id, "credits" => credits}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized: No company logged in"}))

      %OmpluseBackend.Company{id: current_company_id} = _company ->
        if to_string(current_company_id) == company_id do
          case DltManager.assign_credits(company_id, user_id, credits) do
            {:ok, user} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(200, Jason.encode!(%{data: %{id: user.id, user_name: user.user_name, credits: user.credits}}))

            {:error, error} when is_binary(error) ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(404, Jason.encode!(%{error: error}))

            {:error, changeset} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
          end
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "Forbidden: Company ID mismatch"}))
        end
    end
  end

  def delete_user(conn, %{"company_id" => company_id, "user_id" => user_id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized: No company logged in"}))

      %OmpluseBackend.Company{id: current_company_id} = _company ->
        if to_string(current_company_id) == company_id do
          case DltManager.delete_company_user(company_id, user_id) do
            {:ok, _user} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(204, Jason.encode!(%{}))

            {:error, error} when is_binary(error) ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(404, Jason.encode!(%{error: error}))

            {:error, changeset} ->
              conn
              |> put_resp_content_type("application/json")
              |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
          end
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{error: "Forbidden: Company ID mismatch"}))
        end
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
