defmodule OmpluseBackendWeb.AuthController do
  use OmpluseBackendWeb, :controller
  alias OmpluseBackend.{Repo, User, Auth}
  alias OmpluseBackendWeb.AuthGuardian
  alias Pbkdf2

  def register(conn, %{"user" => user_params}) do
    case Repo.get_by(User, user_name: user_params["user_name"]) do
      nil ->
        changeset = User.changeset(%User{}, user_params)
        case Repo.insert(changeset) do
          {:ok, user} ->
            {:ok, token, _claims} = AuthGuardian.encode_and_sign(user)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(201, Jason.encode!(%{token: token}))
          {:error, changeset} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: format_errors(changeset)}))
        end
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "User name already exists"}))
    end
  end

  def login(conn, %{"user_name" => user_name, "password" => password}) do
    case Repo.get_by(User, user_name: user_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid user name or password"}))
      user ->
        case Pbkdf2.verify_pass(password, user.password_hash) do
          true ->
            {:ok, token, _claims} = AuthGuardian.encode_and_sign(user)
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{token: token}))
          false ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: "Invalid user name or password"}))
        end
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
            |> send_resp(422, Jason.encode!(%{errors: format_errors(changeset)}))
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
        |> send_resp(422, Jason.encode!(%{errors: format_errors(changeset)}))
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
