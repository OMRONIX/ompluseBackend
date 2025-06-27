defmodule OmpluseBackendWeb.DltController do
  use OmpluseBackendWeb, :controller
  import Plug.Conn
  alias OmpluseBackend.DltManager

  # DLT Entity
  def create_entity(conn, params) do
    entity_params = params["entity"] || params
    letter_of_authorization = handle_file_upload(params["letter_of_authorization_url"])

    case letter_of_authorization do
      {:error, error} ->
        conn |> put_status(:bad_request) |> json(%{error: error})

      upload_path ->
        entity_params = if upload_path, do: Map.put(entity_params, "letter_of_authorization_url", upload_path), else: entity_params

        case Guardian.Plug.current_resource(conn) do
          nil ->
            conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

          user ->
            entity_params = entity_params |> Map.put("user_id", to_string(user.id)) |> Map.put("company_id", to_string(user.company_id))

            case DltManager.create_entity(user, entity_params) do
              {:ok, entity} ->
                conn
                |> put_status(:created)
                |> json(%{data: entity_json(entity)})

              {:error, changeset} ->
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
            end
        end
    end
  end

  def show_entity(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_entity(user.id, id) do
          {:ok, entity} ->
            conn |> json(%{data: entity_json(entity)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def list_entities(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        entities = DltManager.list_entities(user.id)
        conn |> json(%{data: Enum.map(entities, &entity_json/1)})
    end
  end

  def update_entity(conn, %{"id" => id, "entity" => params}) do
    # IO.inspect("Update entity Params: ", params)
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_entity(user.id, id, params) do
          {:ok, entity} ->
            conn |> json(%{data: entity_json(entity)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_entity(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_entity(user.id, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp entity_json(entity) do
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
  end

  # Sender
  def create_sender(conn, params) do
    sender_params = params["Sender"] || params
    letter_of_authorization = handle_file_upload(params["letter_of_authorization_url"])

    case letter_of_authorization do
      {:error, error} ->
        conn |> put_status(:bad_request) |> json(%{error: error})

      upload_path ->
        sender_params = if upload_path, do: Map.put(sender_params, "letter_of_authorization_url", upload_path), else: sender_params

        case Guardian.Plug.current_resource(conn) do
          nil ->
            conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

          user ->
            try do
              case DltManager.create_sender(user, sender_params) do
                {:ok, sender} ->
                  conn
                  |> put_status(:created)
                  |> json(%{data: sender_json(sender)})

                {:error, changeset} ->
                  conn
                  |> put_status(:unprocessable_entity)
                  |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
              end
            rescue
              e in Ecto.CastError ->
                conn |> put_status(:bad_request) |> json(%{error: "Invalid parameters: #{Exception.message(e)}"})
            end
        end
    end
  end

  def show_sender(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_sender(user.id, id) do
          {:ok, sender} ->
            conn |> json(%{data: sender_json(sender)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def list_senders(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        senders = DltManager.list_senders(user.id)
        conn |> json(%{data: Enum.map(senders, &sender_json/1)})
    end
  end

  def update_sender(conn, %{"id" => id, "sender" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_sender(user.id, id, params) do
          {:ok, sender} ->
            conn |> json(%{data: sender_json(sender)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_sender(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_sender(user.id, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp sender_json(sender) do
    %{
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
  end

  # Template
  def create_template(conn, %{"template" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.create_template(user, params) do
          {:ok, template} ->
            conn
            |> put_status(:created)
            |> json(%{data: template_json(template)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def show_template(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_template(user.id, id) do
          {:ok, template} ->
            conn |> json(%{data: template_json(template)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def list_templates(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        templates = DltManager.list_templates(user.id)
        conn |> json(%{data: Enum.map(templates, &template_json/1)})
    end
  end

  def update_template(conn, %{"id" => id, "template" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_template(user.id, id, params) do
          {:ok, template} ->
            conn |> json(%{data: template_json(template)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_template(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_template(user.id, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp template_json(template) do
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
  end

  # Campaign
  def create_campaign(conn, %{"campaign" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.create_campaign(user, params) do
          {:ok, campaign} ->
            conn
            |> put_status(:created)
            |> json(%{data: campaign_json(campaign)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def show_campaign(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_campaign(user.id, id) do
          {:ok, campaign} ->
            conn |> json(%{data: campaign_json(campaign)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def list_campaigns(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        campaigns = DltManager.list_campaigns(user.id)
        conn |> json(%{data: Enum.map(campaigns, &campaign_json/1)})
    end
  end

  def update_campaign(conn, %{"id" => id, "campaign" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_campaign(user.id, id, params) do
          {:ok, campaign} ->
            conn |> json(%{data: campaign_json(campaign)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_campaign(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_campaign(user.id, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp campaign_json(campaign) do
    %{
      id: campaign.id,
      desc: campaign.desc,
      campaign_id: campaign.campaign_id,
      name: campaign.name,
      status: campaign.status,
      entity_id: campaign.entity_id,
      sender_id: campaign.sender_id,
      template_id: campaign.template_id,
      inserted_at: campaign.inserted_at
    }
  end

  # Group
  def create_group(conn, %{"group" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.create_group(user, params) do
          {:ok, group} ->
            conn
            |> put_status(:created)
            |> json(%{data: group_json(group)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def show_group(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_group(user, id) do
          {:ok, group} ->
            conn |> json(%{data: group_json(group)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def list_groups(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        groups = DltManager.get_groups(user)
        conn |> json(%{data: Enum.map(groups, &group_json/1)})
    end
  end

  def update_group(conn, %{"id" => id, "group" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_group(user, id, params) do
          {:ok, group} ->
            conn |> json(%{data: group_json(group)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_group(conn, %{"id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_group(user, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp group_json(group) do
    %{
      id: group.id,
      name: group.name,
      user_id: group.user_id,
      company_id: group.company_id,
      inserted_at: group.inserted_at
    }
  end

  # Group Contact
  def create_group_contacts(conn, %{"group_id" => group_id, "group_contact" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        params = Map.put(params, "group_id", group_id)
        case DltManager.create_group_contact(user, params) do
          {:ok, contact} ->
            conn
            |> put_status(:created)
            |> json(%{data: group_contact_json(contact)})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def show_group_contacts(conn, %{"group_id" => group_id, "id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.get_group_contact(user.id, id) do
          {:ok, contact} ->
            conn |> json(%{data: group_contact_json(contact)})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  def get_group_contacts(conn, %{"group_id" => group_id}) do
    contacts = DltManager.get_group_contacts(group_id)
    conn |> json(%{data: Enum.map(contacts, &group_contact_json/1)})
  end

  def update_group_contacts(conn, %{"group_id" => _group_id, "id" => id, "group_contact" => params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.update_group_contact(user.id, id, params) do
          {:ok, contact} ->
            conn |> json(%{data: group_contact_json(contact)})
          {:error, error} when is_binary(error) ->
            conn |> put_status(:not_found) |> json(%{error: error})
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)})
        end
    end
  end

  def delete_group_contacts(conn, %{"group_id" => _group_id, "id" => id}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.delete_group_contact(user.id, id) do
          {:ok, _} ->
            conn |> put_status(:no_content) |> json(%{})
          {:error, error} ->
            conn |> put_status(:not_found) |> json(%{error: error})
        end
    end
  end

  defp group_contact_json(contact) do
    %{
      id: contact.id,
      phone_number: contact.phone_number,
      name: contact.name,
      group_id: contact.group_id,
      inserted_at: contact.inserted_at
    }
  end

  # SMS (keeping existing implementation)
  def create_sms(conn, %{"sms" => sms_params}) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn |> put_status(:unauthorized) |> json(%{error: "Unauthorized: No user logged in"})

      user ->
        case DltManager.process_sms_submission(user, sms_params) do
          {:ok, sms_records} ->
            conn
            |> put_status(:created)
            |> json(%{data: Enum.map(sms_records, &sms_json/1)})

          {:error, errors} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
        end
    end
  end

  defp sms_json(sms) do
    %{
      id: sms.id,
      uuid: sms.uuid,
      user_id: sms.user_id,
      seq_id: sms.seq_id,
      entity_id: sms.entity_id,
      sender_id: sms.sender_id,
      template_id: sms.template_id,
      gateway_id: sms.gateway_id,
      dlr_status: sms.dlr_status,
      submit_ts: sms.submit_ts,
      dlr_ts: sms.dlr_ts,
      message: sms.message,
      phone_number: sms.phone_number,
      telco_id: sms.telco_id,
      api_key: sms.api_key,
      channel: sms.channel,
      telemar_id: sms.telemar_id,
      count: sms.count,
      flash: sms.flash,
      multipart: sms.multipart,
      part_id: sms.part_id,
      is_primary: sms.is_primary,
      part_info: sms.part_info,
      cost: sms.cost,
      cost_unit: sms.cost_unit,
      encode: sms.encode,
      company_id: sms.company_id,
      dlt_error_code: sms.dlt_error_code,
      porter_id: sms.porter_id,
      inserted_at: sms.inserted_at
    }
  end

  defp handle_file_upload(upload) do
    case upload do
      %Plug.Upload{path: path, filename: filename} ->
        unique_filename = "#{System.os_time(:millisecond)}_#{filename}"
        upload_dir = Path.join(["priv/static/uploads"])
        File.mkdir_p!(upload_dir)
        dest_path = Path.join(upload_dir, unique_filename)

        case File.cp(path, dest_path) do
          :ok -> "/uploads/#{unique_filename}"
          {:error, reason} -> {:error, "Failed to upload file: #{reason}"}
        end
      nil -> nil
      _ -> {:error, "Invalid file upload"}
    end
  end
end
