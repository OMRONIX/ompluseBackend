defmodule OmpluseBackendWeb.AuthGuardian do
  use Guardian, otp_app: :ompluse_backend
  alias OmpluseBackend.{Repo, User, Company}

  def subject_for_token(%User{id: id}, _claims), do: {:ok, to_string(id)}
  def subject_for_token(%Company{id: id}, _claims), do: {:ok, to_string(id)}
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => id}) do
    case Repo.get(Company, id) || Repo.get(User, id) do
      nil -> {:error, :resource_not_found}
      resource -> {:ok, resource}
    end
  end

  def resource_from_claims(_claims), do: {:error, :invalid_claims}
end
