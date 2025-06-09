defmodule OmpluseBackend.Repo do
  use Ecto.Repo,
    otp_app: :ompluse_backend,
    adapter: Ecto.Adapters.Postgres
end
