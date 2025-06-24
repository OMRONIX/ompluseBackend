defmodule OmpluseBackend.DltManager do
  import Ecto.Query
  alias OmpluseBackend.Campaign
  alias OmpluseBackend.Repo
  alias OmpluseBackend.{DltEntity, Sender, Template, Group, GroupContact}
  alias OmpluseBackend.Dlt.Sms

  #DLT Entity
  def create_entity(_user, attrs) do
    #  IO.inspect(attrs, label: "Params in DltManager.create_entity")
    %DltEntity{}
    |> DltEntity.changeset(attrs)
    |> Repo.insert()
  end

  def list_entities(user_id) do
    DltEntity
    |> where([e], e.user_id == ^user_id)
    |> Repo.all()
  end

  # Sender
def create_sender(_user, params) do
    IO.inspect(params, label: "Params in DltManager.create_sender")
    %Sender{}
    |> Sender.changeset(params)
    |> Repo.insert()
  end

  def list_senders(user_id) do
    Sender
    |> join(:inner, [s], e in DltEntity, on: s.entity_id == e.id)
    |> where([s, e], e.user_id == ^user_id)
    |> Repo.all()
  end

  #template
  def create_template(_user, params) do
      %Template{}
      |> Template.changeset(params)
      |> Repo.insert()
    end

  def list_templates(user_id) do
    Template
    |> join(:inner, [t], e in DltEntity, on: t.entity_id == e.id)
    |> join(:inner, [t, e], s in Sender, on: t.sender_id == s.id)
    |> where([t, e, s], e.user_id == ^user_id)
    |> Repo.all()
  end

  #campaign
  def create_campaign(user, params) do
    # with {:ok, entity} <- get_approved_entity(user.id, attrs["entity_id"]),
    #       {:ok, sender} <- get_approved_sender(entity, attrs["sender_id"]),
    #       {:ok, template} <- Repo.get(Template, attrs["template_id"]) do
    params = Map.put(params, "user_id", user.id)
    %Campaign{}
    |> Campaign.changeset(params)
    |> Repo.insert()
    end
  # end

def list_campaigns(user_id) do
  Campaign
  |> join(:inner, [c], e in DltEntity, on: c.entity_id == e.id) # Adjust join as per schema
  |> where([c, e], e.user_id == ^user_id)
  |> Repo.all()
end

def create_group(user, params) do
    attrs = %{
      name: params["name"],
      user_id: if(user.__struct__ == OmpluseBackend.User, do: user.id, else: nil),
      company_id: if(user.__struct__ == OmpluseBackend.Company, do: user.id, else: nil)
    }

    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end
def create_group_contact(user, attrs) do
  attrs = Map.put(attrs, "user_id", user.id)

  %GroupContact{}
  |> GroupContact.changeset(attrs)
  |> Repo.insert()
end


   def get_groups(user) do
    case user do
      %OmpluseBackend.User{id: user_id} ->
        Repo.all(from g in Group, where: g.user_id == ^user_id)
      %OmpluseBackend.Company{id: company_id} ->
        Repo.all(from g in Group, where: g.company_id == ^company_id)
    end
  end

  def get_group_contacts(group_id) do
    Repo.all(from gc in GroupContact, where: gc.group_id == ^group_id, select: [:phone_number, :name])
  end



  # defp get_approved_entity(user_id, entity_id) do
  #   entity = Repo.get(DltEntity, entity_id)

  #   if entity && entity.user_id == user_id && entity.verification_status == :approved do
  #     {:ok, entity}
  #   else
  #     {:error, "Entity not found or not approved"}
  #   end
  # end

  # defp get_approved_sender(entity, sender_id) do
  #   sender = Repo.get(Sender, sender_id)

  #   if sender && sender.entity_id == entity.id && sender.status == :approved do
  #     {:ok, sender}
  #   else
  #     {:error, "Sender not found or not approved"}
  #   end
  # end

  # def get_approved_template(entity_id, template_id) do
  #   template = Repo.get(Template, template_id)

  #   if template && template.entity_id == entity_id && template.status == :approved do
  #     {:ok, template}
  #   else
  #     {:error, "Template not found or not approved"}
  #   end
  # end

  def process_sms_submission(user, params) do
    sender_id = params["sender_id"]
    template_id = params["template_id"]
    message = params["message"]
    contacts_input = params["contacts"]
    group_ids = params["group_ids"]
    csv_file = params["csv_file"]

    # Validate sender_id and template_id
    with {:ok, sender} <- validate_sender(user.id, sender_id),
         {:ok, template} <- validate_template(user.id, template_id) do
      contacts = fetch_contacts(contacts_input, group_ids, csv_file, user.id)
      create_sms_records(user, sender, template, message, contacts)
    else
      {:error, reason} -> {:error, reason}
    end
  end

defp validate_sender(user_id, sender_id) do
  query =
    from s in Sender,
      join: e in assoc(s, :entity),
      where: s.sender_id == ^sender_id and e.user_id == ^user_id,
      preload: [entity: e]

  case Repo.one(query) do
    nil -> {:error, "Invalid or unapproved sender"}
    sender -> {:ok, sender}
  end
end

defp validate_template(user_id, template_id) do
  query =
    from t in Template,
      join: e in assoc(t, :entity),
      where: t.template_id == ^template_id and e.user_id == ^user_id,
      preload: [entity: e]

  case Repo.one(query) do
    nil -> {:error, "Invalid or unapproved template"}
    template -> {:ok, template}
  end
end


  defp fetch_contacts(contacts_input, group_ids, csv_file, user_id) do
    contacts = []
    contacts = contacts ++ parse_manual_contacts(contacts_input)
    contacts = contacts ++ parse_group_contacts(group_ids, user_id)
    contacts = contacts ++ parse_csv_contacts(csv_file)
    Enum.uniq(contacts) # Remove duplicates
  end

  defp parse_manual_contacts(contacts_input) do
    case contacts_input do
      nil -> []
      input -> String.split(input, ",") |> Enum.map(&String.trim/1) |> Enum.filter(&valid_phone?/1)
    end
  end

  defp parse_group_contacts(group_ids, user_id) do
  case group_ids do
    nil -> []
    ids ->
      from(gc in GroupContact,
        join: g in Group,
        on: g.id == gc.group_id,
        where: gc.group_id in ^ids and g.user_id == ^user_id,
        select: gc.phone_number
      )
      |> Repo.all()
      |> Enum.filter(&valid_phone?/1)
  end
end


  defp parse_csv_contacts(csv_file) do
    case csv_file do
      %Plug.Upload{path: path} ->
        File.stream!(path)
        |> CSV.decode(headers: true)
        |> Enum.map(fn {:ok, row} -> row["phone_number"] end)
        |> Enum.filter(&valid_phone?/1)
      _ -> []
    end
  end

  defp valid_phone?(phone) do
    String.match?(phone, ~r/^[0-9]{10}$/)
  end

defp create_sms_records(user, sender, template, message, contacts) do
    # Fetch gateway_id and telco_id (placeholder logic; replace with actual implementation)
    gateway_id = nil
    telco_id = nil

    sms_records =
      Enum.with_index(contacts, 1)
      |> Enum.map(fn {phone, _index} ->
        sms_params = %{
          user_id: to_string(user.id),
          seq_id: nil,
          entity_id: to_string(sender.entity_id),
          sender_id: sender.sender_id,
          template_id: template.template_id,
          gateway_id: gateway_id,
          dlr_status: "PENDING",
          submit_ts: DateTime.utc_now(),
          message: message,
          phone_number: phone,
          telco_id: telco_id
        }

        %Sms{}
        |> Sms.changeset(sms_params)
        |> Repo.insert!()
      end)

    {:ok, sms_records}
  end



end
