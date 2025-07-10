defmodule OmpluseBackendWeb.Plugs.EnsureCompany do
  import Plug.Conn
  alias OmpluseBackend.Company

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %Company{} ->
        conn
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Only companies can access this resource"}))
        |> halt()
    end
  end
end
