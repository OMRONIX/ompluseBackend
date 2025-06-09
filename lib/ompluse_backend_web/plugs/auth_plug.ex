defmodule OmpluseBackendWeb.Plugs.AuthPlug do
  import Plug.Conn
  alias OmpluseBackend.{User, Company}

  def init(opts), do: opts

  def call(conn, _opts) do
    resource = Guardian.Plug.current_resource(conn)
    company_id = String.to_integer(conn.params["company_id"])
    IO.inspect({company_id, resource}, label: "AuthPlug Check")
    case resource do
      nil ->
        send_unauthorized(conn)

      %User{company_id: user_company_id} ->
        if user_company_id == company_id do
          conn
        else
          send_forbidden(conn)
        end

      %Company{id: company_id_from_token} ->
        if company_id_from_token == company_id do
          conn
        else
          send_forbidden(conn)
        end
    end
  end

  defp send_forbidden(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Jason.encode!(%{error: "Unauthorized access"}))
    |> halt()
  end

  defp send_unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "Unauthorized or invalid token"}))
    |> halt()
  end
end
