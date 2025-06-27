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
    plug Guardian.Plug.VerifyHeader, realm: "Bearer" # Verify the token from the Authorization header
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
    pipe_through [:api, :auth]

    get "/dashboard", DashboardController, :index
  end

  scope "/api", OmpluseBackendWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/company/register", CompanyController, :register
    post "/company/login", CompanyController, :login
    post "/password/reset", AuthController, :request_password_reset
    post "/password/reset/confirm", AuthController, :reset_password
  end

  # Protected routes requiring authentication
  scope "/api/dlt", OmpluseBackendWeb do
    pipe_through [:api, :auth, :ensure_auth]

    # DLT Entity Routes
    post "/entities", DltController, :create_entity
    get "/entities", DltController, :list_entities
    get "/entities/:id", DltController, :show_entity
    put "/entities/:id", DltController, :update_entity
    delete "/entities/:id", DltController, :delete_entity

    # Sender Routes
    post "/senders", DltController, :create_sender
    get "/senders", DltController, :list_senders
    get "/senders/:id", DltController, :show_sender
    put "/senders/:id", DltController, :update_sender
    delete "/senders/:id", DltController, :delete_sender

    # Template Routes
    post "/templates", DltController, :create_template
    get "/templates", DltController, :list_templates
    get "/templates/:id", DltController, :show_template
    put "/templates/:id", DltController, :update_template
    delete "/templates/:id", DltController, :delete_template

    # Campaign Routes
    post "/campaigns", DltController, :create_campaign
    get "/campaigns", DltController, :list_campaigns
    get "/campaigns/:id", DltController, :show_campaign
    put "/campaigns/:id", DltController, :update_campaign
    delete "/campaigns/:id", DltController, :delete_campaign

    # Group Routes
    post "/groups", DltController, :create_group
    get "/groups", DltController, :list_groups
    get "/groups/:id", DltController, :show_group
    put "/groups/:id", DltController, :update_group
    delete "/groups/:id", DltController, :delete_group

    # Group Contact Routes
    post "/groups/:group_id/contacts", DltController, :create_group_contacts
    get "/groups/:group_id/contacts", DltController, :get_group_contacts
    get "/groups/:group_id/contacts/:id", DltController, :show_group_contacts
    put "/groups/:group_id/contacts/:id", DltController, :update_group_contacts
    delete "/groups/:group_id/contacts/:id", DltController, :delete_group_contacts

    # SMS Route
    post "/sms", DltController, :create_sms
  end

  # Company-specific routes
  scope "/api/companies/:company_id", OmpluseBackendWeb do
    pipe_through [:api, :auth, :ensure_company]

    get "/users", CompanyController, :list_users
  end
end
