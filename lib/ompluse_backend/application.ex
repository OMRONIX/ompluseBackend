defmodule OmpluseBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OmpluseBackendWeb.Telemetry,
      OmpluseBackend.Repo,
      {DNSCluster, query: Application.get_env(:ompluse_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OmpluseBackend.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: OmpluseBackend.Finch},
      # Start a worker by calling: OmpluseBackend.Worker.start_link(arg)
      # {OmpluseBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      OmpluseBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OmpluseBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OmpluseBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
