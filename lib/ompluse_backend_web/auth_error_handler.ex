defmodule OmpluseBackendWeb.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    IO.inspect({type, reason}, label: "Guardian Auth Error")
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "Unauthorized", type: to_string(type), reason: to_string(reason)}))
    |> halt()
  end
end
