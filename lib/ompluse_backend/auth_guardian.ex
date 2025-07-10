defmodule OmpluseBackendWeb.AuthGuardian do
  use Guardian, otp_app: :ompluse_backend
  alias OmpluseBackend.{Repo, User, Company}
  require Logger

  def subject_for_token(%User{id: id}, _claims) do
    Logger.debug("Generating user token for ID: #{id}")
    {:ok, to_string(id)}
  end

  def subject_for_token(%Company{id: id}, _claims) do
    Logger.debug("Generating company token for ID: #{id}")
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def build_claims(claims, %User{}, _opts) do
    {:ok, Map.put(claims, "typ", "user")}
  end

  def build_claims(claims, %Company{}, _opts) do
    {:ok, Map.put(claims, "typ", "company")}
  end

  def resource_from_claims(%{"sub" => id, "typ" => "company"}) do
    Logger.debug("Resolving company resource for ID: #{id}")
    case Repo.get(Company, id) do
      nil ->
        Logger.error("No company found for ID: #{id}")
        {:error, :resource_not_found}
      company ->
        Logger.debug("Found company: #{inspect(company)}")
        {:ok, company}
    end
  end

  def resource_from_claims(%{"sub" => id, "typ" => "user"}) do
    Logger.debug("Resolving user resource for ID: #{id}")
    case Repo.get(User, id) do
      nil ->
        Logger.error("No user found for ID: #{id}")
        {:error, :resource_not_found}
      user ->
        Logger.debug("Found user: #{inspect(user)}")
        {:ok, user}
    end
  end

  def resource_from_claims(claims) do
    Logger.error("Invalid claims: #{inspect(claims)}")
    {:error, :invalid_claims}
  end
end
