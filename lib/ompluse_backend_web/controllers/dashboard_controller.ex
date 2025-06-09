defmodule OmpluseBackendWeb.DashboardController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.User
  alias OmpluseBackend.Company
def index(conn, _params) do
  resource = Guardian.Plug.current_resource(conn)
  token = Guardian.Plug.current_token(conn)
  IO.inspect({token, resource}, label: "Dashboard Auth Check")
  case resource do
    nil ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, Jason.encode!(%{error: "Unauthorized or invalid token"}))
      |> halt()
    %User{} = user ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{user: %{id: user.id, user_name: user.user_name}}))
    %Company{} = company ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{company: %{id: company.id, company_name: company.company_name}}))
  end
end
end
