defmodule OmpluseBackendWeb.DashboardController do
  use OmpluseBackendWeb, :controller
  alias OmpluseBackend.{DltManager, Repo, User, Company}

  def index(conn, params) do
    resource = Guardian.Plug.current_resource(conn)

    case resource do
      %User{} ->
        dashboard_data = DltManager.user_dashboard_data(resource)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: dashboard_data}))

      %Company{id: company_id} ->
        case Map.get(params, "user_id") do
          nil ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{error: "user_id parameter required"}))
          user_id ->
            case Repo.get_by(User, id: user_id, company_id: company_id) do
              nil ->
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(404, Jason.encode!(%{error: "User not found or not associated with company"}))
              user ->
                dashboard_data = DltManager.user_dashboard_data(user)
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(200, Jason.encode!(%{data: dashboard_data}))
            end
        end
    end
  end
end
