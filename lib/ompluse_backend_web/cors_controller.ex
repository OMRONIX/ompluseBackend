defmodule OmpluseBackendWeb.CorsController do
  use OmpluseBackendWeb, :controller

  def options(conn, _params) do
    send_resp(conn, 204, "")
  end
end
