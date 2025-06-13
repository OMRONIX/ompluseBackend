defmodule OmpluseBackendWeb.DltController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.DltManager


  # Entity
  def create_entity(conn, params) do


    entity_params =
      case params do
        %{"entity" => entity_params} -> entity_params
        %{"ueid" => _} = params -> params
        _ -> %{}
      end

    letter_of_authorization =
      case params["letter_of_authorization_url"] do
        %Plug.Upload{path: path, filename: filename} ->
          unique_filename = "#{System.os_time(:millisecond)}_#{filename}"
          upload_dir = Path.join(["priv/static/uploads"])
          File.mkdir_p!(upload_dir)
          dest_path = Path.join(upload_dir, unique_filename)

          case File.cp(path, dest_path) do
            :ok -> "/uploads/#{unique_filename}"
            {:error, reason} -> {:error, "Failed to upload file: #{reason}"}
          end

        nil ->
          nil

        _ ->
          {:error, "Invalid file upload"}
      end

    case letter_of_authorization do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})

      upload_path ->
        entity_params =
          if upload_path,
            do: Map.put(entity_params, "letter_of_authorization_url", upload_path),
            else: entity_params

        case Guardian.Plug.current_resource(conn) do
          nil ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Unauthorized: No user logged in"})

          user ->
            # Convert user ID to string if it's an integer


            entity_params =
              entity_params
              |> Map.put("user_id", to_string(user.id))
              |> Map.put("company_id", to_string(user.company_id))

               IO.inspect(entity_params, label: "Updated Entity Params with String IDs")


            case DltManager.create_entity(user, entity_params) do

              {:ok, entity} ->
                conn
                |> put_status(:created)
                |> json(%{
                  data: %{
                    id: entity.id,
                    ueid: entity.ueid,
                    entity_name: entity.entity_name,
                    entity_type: entity.entity_type,
                    verification_status: entity.verification_status,
                    telecom_operator: entity.telecom_operator,
                    letter_of_authorization_url: entity.letter_of_authorization_url,
                    inserted_at: entity.inserted_at
                  }
                })

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: changeset.errors})
            end
        end
    end
  end

  def list_entities(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        entities = DltManager.list_entities(user.id)
        conn
        |> json(%{
          data: Enum.map(entities, fn entity ->
            %{
              id: entity.id,
              ueid: entity.ueid,
              entity_name: entity.entity_name,
              entity_type: entity.entity_type,
              verification_status: entity.verification_status,
              telecom_operator: entity.telecom_operator,
              letter_of_authorization_url: entity.letter_of_authorization_url,
              inserted_at: entity.inserted_at
            }
          end)
        })
    end
  end

  # Sender

  def create_sender(conn, params) do
    sender_params =
      case params do
        %{"Sender" => sender_params} -> sender_params
        %{"sender_id" => _} = params -> params
        _ -> %{}
      end
      IO.inspect(params, label: "Params in DltController")
      IO.inspect(sender_params, label: "Sender Params in DltController")

    letter_of_authorization =
      case params["letter_of_authorization_url"] do
        %Plug.Upload{path: path, filename: filename} ->
          unique_filename = "#{System.os_time(:millisecond)}_#{filename}"
          upload_dir = Path.join(["priv/static/uploads/sender"])
          File.mkdir_p!(upload_dir)
          dest_path = Path.join(upload_dir, unique_filename)

          case File.cp(path, dest_path) do
            :ok -> "/uploads/#{unique_filename}"
            {:error, reason} -> {:error, "Failed to upload file: #{reason}"}
          end

        nil ->
          nil

        _ ->
          {:error, "Invalid file upload"}
      end

    case letter_of_authorization do
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: error})

      upload_path ->
        sender_params =
          if upload_path,
            do: Map.put(sender_params, "letter_of_authorization_url", upload_path),
            else: sender_params

        case Guardian.Plug.current_resource(conn) do
          nil ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Unauthorized: No user logged in"})

          user ->
            IO.inspect(user, label: "Current User in DltController")
            # IO.inspect(sender_params, label: "Sender Params in DltController")

            try do
              case DltManager.create_sender(user, sender_params) do
                {:ok, sender} ->
                  conn
                  |> put_status(:created)
                  |> json(%{
                    data: %{
                      id: sender.id,
                      sender_id: sender.sender_id,
                      desc: sender.desc,
                      status: sender.status,
                      entity_id: sender.entity_id,
                      approved_by: sender.approved_by,
                      approved_on: sender.approved_on,
                      letter_of_authorization_url: sender.letter_of_authorization_url,
                      inserted_at: sender.inserted_at
                    }
                  })

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
              end
            rescue
              e in Ecto.CastError ->
                conn
                |> put_status(:bad_request)
                |> json(%{error: "Invalid parameters: #{Exception.message(e)}"})
            end
        end
    end
  end


  def list_senders(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        senders = DltManager.list_senders(user.id)
        conn
        |> json(%{
          data: Enum.map(senders, fn sender ->
            %{
              id: sender.id,
              sender_id: sender.sender_id,
              desc: sender.desc,
              status: sender.status,
              entity_id: sender.entity_id,
              approved_by: sender.approved_by,
              approved_on: sender.approved_on,
              inserted_at: sender.inserted_at
            }
          end)
        })
    end
  end

  # Template
  def create_template(conn, %{"template" => template_params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        case DltManager.create_template(user, template_params) do
          {:ok, template} ->
            conn
            |> put_status(:created)
            |> json(%{
              data: %{
                id: template.id,
                template_content: template.template_content,
                template_type: template.template_type,
                template_status: template.template_status,
                entity_id: template.entity_id,
                sender_id: template.sender_id,
                template_id: template.template_id,
                inserted_at: template.inserted_at
              }
            })

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset.errors})
        end
    end
  end

  def list_templates(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        templates = DltManager.list_templates(user.id)
        conn
        |> json(%{
          data: Enum.map(templates, fn template ->
            %{
              id: template.id,
              template_content: template.template_content,
              template_type: template.template_type,
              template_status: template.template_status,
              entity_id: template.entity_id,
              sender_id: template.sender_id,
              template_id: template.template_id,
              inserted_at: template.inserted_at
            }
          end)
        })
    end
  end

  # Campaign
  def create_campaign(conn, %{"campaign" => campaign_params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        case DltManager.create_campaign(user, campaign_params) do
          {:ok, campaign} ->
            conn
            |> put_status(:created)
            |> json(%{
              data: %{
                id: campaign.id,
                name: campaign.name,
                status: campaign.status,
                entity_id: campaign.entity_id,
                sender_id: campaign.sender_id,
                template_id: campaign.template_id,
                inserted_at: campaign.inserted_at
              }
            })

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: changeset.errors})
        end
    end
  end

  def list_campaigns(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        IO.inspect(user, label: "Current User in DltController")
        campaigns = DltManager.list_campaigns(user.id)
        conn
        |> json(%{
          data: Enum.map(campaigns, fn campaign ->
            %{
              id: campaign.id,
              name: campaign.name,
              status: campaign.status,
              entity_id: campaign.entity_id,
              sender_id: campaign.sender_id,
              template_id: campaign.template_id,
              inserted_at: campaign.inserted_at
            }
          end)
        })
    end
  end
end
