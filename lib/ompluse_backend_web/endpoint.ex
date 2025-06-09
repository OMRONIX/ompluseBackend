defmodule OmpluseBackendWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ompluse_backend

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_ompluse_backend_key",
    signing_salt: "xinbmDo0",
    same_site: "Lax"
  ]




  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :ompluse_backend,
    gzip: false,
    only: OmpluseBackendWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :ompluse_backend
  end

  plug CORSPlug,
  origin: ["http://localhost:3000"],  # your Next.js dev server
  methods: ["GET", "POST", "OPTIONS"],
  headers: ["Authorization", "Content-Type"],
  max_age: 86400


  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]




  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug OmpluseBackendWeb.Router
end
