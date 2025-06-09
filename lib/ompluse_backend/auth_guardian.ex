defmodule OmpluseBackendWeb.AuthGuardian do
  use Guardian, otp_app: :ompluse_backend

  alias OmpluseBackend.Auth

  # Generate subject for token
  def subject_for_token(%{id: id}, _claims), do: {:ok, to_string(id)}
  def subject_for_token(_, _), do: {:error, :invalid_resource}

  # Retrieve resource from claims
  def resource_from_claims(%{"sub" => id} = claims) do
    IO.inspect(claims, label: "Guardian Claims")
    IO.inspect(id, label: "Subject ID")

    user = Auth.get_user(id)
    company = Auth.get_company(id)

    IO.inspect({user, company}, label: "Resource Lookup")

    case user || company do
      nil ->
        IO.puts("No resource found for ID: #{id}")
        {:error, :resource_not_found}

      resource ->
        IO.inspect(resource, label: "Found Resource")
        {:ok, resource}
    end
  end

  def resource_from_claims(claims) do
    IO.inspect(claims, label: "Invalid Guardian Claims")
    {:error, :invalid_claims}
  end
end
