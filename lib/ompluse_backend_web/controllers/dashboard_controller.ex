defmodule OmpluseBackendWeb.DashboardController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn

  def index(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized or invalid token"}))
        |> halt()

      %OmpluseBackend.User{} = user ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{user: %{id: user.id, user_name: user.user_name, credits: user.credits, credits_used: user.credits_used}}))
    end
  end
end
