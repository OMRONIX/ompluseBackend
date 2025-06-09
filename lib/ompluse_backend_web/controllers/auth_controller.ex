defmodule OmpluseBackendWeb.AuthController do
  use OmpluseBackendWeb, :controller
  alias OmpluseBackend.Auth
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

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
