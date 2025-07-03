defmodule OmpluseBackendWeb.CompanyDashboardController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.DltManager

  def index(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized or invalid token"}))
        |> halt()

      %OmpluseBackend.User{} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Forbidden: Only companies can access this dashboard"}))
        |> halt()

      %OmpluseBackend.Company{id: company_id} = company ->
        users = DltManager.list_company_users(company_id)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          company: %{id: company.id, company_name: company.company_name},
          users: users
        }))
    end
  end
end
