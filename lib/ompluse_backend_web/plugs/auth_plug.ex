defmodule OmpluseBackendWeb.Plugs.AuthPlug do
  import Plug.Conn
  alias OmpluseBackend.{User, Company}

  def init(opts), do: opts

  def call(conn, _opts) do
    resource = Guardian.Plug.current_resource(conn)
    company_id = conn.params["company_id"]

    case {resource, company_id} do
      {nil, _} ->
        send_unauthorized(conn)

      {%User{}, nil} ->
        send_forbidden(conn, "Only companies can access this resource")

      {%User{company_id: user_company_id}, company_id} ->
        if user_company_id == String.to_integer(company_id) do
          conn
        else
          send_forbidden(conn, "User does not belong to the specified company")
        end

      {%Company{id: company_id_from_token}, nil} ->
        conn

      {%Company{id: company_id_from_token}, company_id} ->
        if company_id_from_token == String.to_integer(company_id) do
          conn
        else
          send_forbidden(conn, "Company ID mismatch")
        end
    end
  end

  defp send_forbidden(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(403, Jason.encode!(%{error: message}))
    |> halt()
  end

  defp send_unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "Unauthorized or invalid token"}))
    |> halt()
  end
end
