defmodule OmpluseBackendWeb.AuthController do
  use OmpluseBackendWeb, :controller
  alias OmpluseBackend.{Auth, Repo, User, Company}
  alias Pbkdf2
  alias OmpluseBackendWeb.AuthGuardian

  def register(conn, %{"user" => user_params}) do
    user_params = Map.put(user_params, "password_hash", Pbkdf2.hash_pwd_salt(user_params["password"]))

    case Auth.register_user(user_params) do
      {:ok, user} ->
        {:ok, token, _claims} = AuthGuardian.encode_and_sign(user)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{token: token, user: %{id: user.id, user_name: user.user_name}}))

      {:error, changeset} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
    end
  end

  def login(conn, %{"user_name" => user_name, "password" => password}) do
    case Auth.login_user(user_name, password) do
      {:ok, user, token} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{token: token, user: %{id: user.id, user_name: user.user_name}}))

      {:error, :invalid_credentials} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid credentials"}))
    end
  end

  def request_password_reset(conn, %{"user_name" => user_name}) do
    IO.inspect("Requesting password reset for user_name: #{user_name}")
    resource = Repo.get_by(User, user_name: user_name) || Repo.get_by(Company, company_name: user_name)
    IO.inspect("Resource in reset password: #{inspect(resource)}")

    case resource do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{error: "User name not found"}))

      resource ->
        case Auth.generate_password_reset_token(resource) do
          {:ok, _resource, token} ->
            Auth.send_password_reset_email(resource, token)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{message: "Password reset email sent", token: token}))

          {:error, changeset} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
        end
    end
  end

  def reset_password(conn, %{"user_name" => user_name, "token" => token, "new_password" => new_password}) do
    case Auth.reset_password(user_name, token, new_password) do
      {:ok, _resource} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{message: "Password reset successfully"}))

      {:error, :invalid_token} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid or missing token"}))

      {:error, :token_expired} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Token expired"}))

      {:error, changeset} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{errors: changeset_errors(changeset)}))
    end
  end



  defp get_authenticated_resource(conn) do
    case Guardian.Plug.current_resource(conn) do
      %User{} = user -> {:ok, user}
      %Company{} = company -> {:ok, company}
      nil -> {:error, :unauthenticated}
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
