defmodule OmpluseBackendWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller

  alias Guardian.Plug

  # API pipeline
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authentication pipeline
  pipeline :auth do
    plug Plug.Pipeline,
      module: OmpluseBackendWeb.AuthGuardian,
      error_handler: OmpluseBackendWeb.AuthErrorHandler
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"  # Verify the token from the Authorization header     # Ensure the user is authenticated
    plug Guardian.Plug.LoadResource
    plug :log_token
  end

  # Ensure user is authenticated
  pipeline :ensure_auth do
    plug Plug.EnsureAuthenticated
  end

  # Ensure resource belongs to the company
  pipeline :ensure_company do
    plug OmpluseBackendWeb.Plugs.AuthPlug
  end

  # Log token for debugging
  def log_token(conn, _opts) do
    token = Plug.current_token(conn)
    IO.inspect(token, label: "Extracted Token")
    conn
  end

  # Define API routes
  scope "/api", OmpluseBackendWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/company/register", CompanyController, :register
    post "/company/login", CompanyController, :login
  end

  # Protected routes requiring authentication
  scope "/api", OmpluseBackendWeb do
    pipe_through [:api, :auth]

    get "/dashboard", DashboardController, :index

    post "/dlt/entities", DltController, :create_entity
    get "/dlt/entities", DltController, :list_entities

    post "/dlt/senders", DltController, :create_sender
    get "/dlt/senders", DltController, :list_senders

    post "/dlt/templates", DltController, :create_template
    get "/dlt/templates", DltController, :list_templates

    post "/dlt/campaigns", DltController, :create_campaign
    get "/dlt/campaigns", DltController, :list_campaigns
  end


  # Company-specific routes
  scope "/api/companies/:company_id", OmpluseBackendWeb do
    pipe_through [:api]

    get "/users", CompanyController, :list_users
  end
end
