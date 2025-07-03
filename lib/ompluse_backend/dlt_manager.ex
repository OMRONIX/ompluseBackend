defmodule OmpluseBackend.DltManager do
  import Ecto.Query
  alias OmpluseBackend.{Campaign, Repo, DltEntity, Sender, Template, Group, GroupContact, User, Company}
  alias OmpluseBackend.Dlt.Sms
  alias Pbkdf2

 # Company Dashboard Functions
  def list_company_users(company_id) do
    User
    |> where([u], u.company_id == ^company_id)
    |> Repo.all()
    |> Enum.map(&user_dashboard_data/1)
  end

  def add_company_user(company, user_params) do
    user_params = Map.merge(user_params, %{
      "company_id" => to_string(company.id),
      "password_hash" => Pbkdf2.hash_pwd_salt(user_params["password"])
    })

    OmpluseBackend.Auth.register_user(user_params)
  end

  def assign_credits(company_id, user_id, credits) when is_number(credits) and credits >= 0 do
    with {:ok, user} <- get_company_user(company_id, user_id) do
      user
      |> User.changeset(%{credits: user.credits + credits})
      |> Repo.update()
    end
  end

 def delete_company_user(company_id, user_id) do
    with {:ok, user} <- get_company_user(company_id, user_id) do
      Repo.transaction(fn ->
        # Subquery for entity_ids
        entity_ids_query =
          from e in DltEntity,
            where: e.user_id == ^to_string(user_id),
            select: e.id

        # Delete associated records
        Repo.delete_all(from e in DltEntity, where: e.user_id == ^to_string(user_id))
        Repo.delete_all(from s in Sender, where: s.entity_id in subquery(entity_ids_query))
        Repo.delete_all(from t in Template, where: t.entity_id in subquery(entity_ids_query))
        Repo.delete_all(from c in Campaign, where: c.user_id == ^to_string(user_id))
        Repo.delete_all(
          from gc in GroupContact,
            join: g in Group,
            on: gc.group_id == g.id,
            where: g.user_id == ^to_string(user_id)
        )
        Repo.delete_all(from g in Group, where: g.user_id == ^to_string(user_id))

        # Delete the user
        case Repo.delete(user) do
          {:ok, user} -> {:ok, user}
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  defp get_company_user(company_id, user_id) do
    case Repo.get_by(User, id: user_id, company_id: company_id) do
      nil -> {:error, "User not found or not associated with company"}
      user -> {:ok, user}
    end
  end

  defp user_dashboard_data(user) do
    user_id_str = to_string(user.id) # Cast to string for consistency

    entity_ids_query =
      from e in DltEntity,
        where: e.user_id == ^user_id_str,
        select: e.id

    entities_count =
      Repo.one(
        from e in DltEntity,
          where: e.user_id == ^user_id_str,
          select: count("*")
      ) || 0

    senders_count =
      Repo.one(
        from s in Sender,
          where: s.entity_id in subquery(entity_ids_query),
          select: count("*")
      ) || 0

    templates_count =
      Repo.one(
        from t in Template,
          where: t.entity_id in subquery(entity_ids_query),
          select: count("*")
      ) || 0

    campaigns_count =
      Repo.one(
        from c in Campaign,
          where: c.user_id == ^user_id_str,
          select: count("*")
      ) || 0

    credits_used =
      Repo.one(
        from s in Sms,
          where: s.user_id == ^user_id_str,
          select: coalesce(sum(fragment("CAST(? AS FLOAT)", s.cost)), 0.0)
      ) || 0.0

    %{
      id: user.id,
      user_name: user.user_name,
      credits: user.credits || 0.0,
      entities_count: entities_count,
      senders_count: senders_count,
      templates_count: templates_count,
      campaigns_count: campaigns_count,
      credits_used: credits_used
    }
  end

  # DLT Entity
  def create_entity(user, attrs) do
    %DltEntity{}
    |> DltEntity.changeset(attrs |> Map.put("user_id", to_string(user.id)))
    |> Repo.insert()
  end

  def get_entity(user_id, id) do
    case Repo.get_by(DltEntity, id: id, user_id: user_id) do
      nil -> {:error, "Entity not found"}
      entity -> {:ok, entity}
    end
  end

  def list_entities(user_id) do
    DltEntity
    |> where([e], e.user_id == ^user_id)
    |> Repo.all()
  end

  def update_entity(user_id, id, attrs) do
    with {:ok, entity} <- get_entity(user_id, id) do
      entity
      |> DltEntity.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_entity(user_id, id) do
    with {:ok, entity} <- get_entity(user_id, id) do
      Repo.transaction(fn ->
        Repo.delete_all(from s in Sender, where: s.entity_id == ^entity.id)
        Repo.delete_all(from t in Template, where: t.entity_id == ^entity.id)
        case Repo.delete(entity) do
          {:ok, entity} -> {:ok, entity}
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  # Sender
  def create_sender(_user, attrs) do
    %Sender{}
    |> Sender.changeset(attrs)
    |> Repo.insert()
  end

  def get_sender(user_id, id) do
    query =
      from s in Sender,
        join: e in DltEntity,
        on: s.entity_id == e.id,
        where: s.id == ^id and e.user_id == ^user_id

    case Repo.one(query) do
      nil -> {:error, "Sender not found"}
      sender -> {:ok, sender}
    end
  end

  def list_senders(user_id) do
    Sender
    |> join(:inner, [s], e in DltEntity, on: s.entity_id == e.id)
    |> where([s, e], e.user_id == ^user_id)
    |> Repo.all()
  end

  def update_sender(user_id, id, attrs) do
    with {:ok, sender} <- get_sender(user_id, id) do
      sender
      |> Sender.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_sender(user_id, id) do
    with {:ok, sender} <- get_sender(user_id, id) do
      Repo.delete(sender)
    end
  end

  # Template
  def create_template(_user, attrs) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  def get_template(user_id, id) do
    query =
      from t in Template,
        join: e in DltEntity,
        on: t.entity_id == e.id,
        where: t.id == ^id and e.user_id == ^user_id

    case Repo.one(query) do
      nil -> {:error, "Template not found"}
      template -> {:ok, template}
    end
  end

  def list_templates(user_id) do
    Template
    |> join(:inner, [t], e in DltEntity, on: t.entity_id == e.id)
    |> join(:inner, [t, e], s in Sender, on: t.sender_id == s.id)
    |> where([t, e, s], e.user_id == ^user_id)
    |> Repo.all()
  end

  def update_template(user_id, id, attrs) do
    with {:ok, template} <- get_template(user_id, id) do
      template
      |> Template.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_template(user_id, id) do
    with {:ok, template} <- get_template(user_id, id) do
      Repo.delete(template)
    end
  end

  # Campaign
  def create_campaign(user, attrs) do
    attrs = Map.put(attrs, "user_id", to_string(user.id))
    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert()
  end

  def get_campaign(user_id, id) do
    query =
      from c in Campaign,
        join: e in DltEntity,
        on: c.entity_id == e.id,
        where: c.id == ^id and e.user_id == ^user_id

    case Repo.one(query) do
      nil -> {:error, "Campaign not found"}
      campaign -> {:ok, campaign}
    end
  end

  def list_campaigns(user_id) do
    Campaign
    |> join(:inner, [c], e in DltEntity, on: c.entity_id == e.id)
    |> where([c, e], e.user_id == ^user_id)
    |> Repo.all()
  end

  def update_campaign(user_id, id, attrs) do
    with {:ok, campaign} <- get_campaign(user_id, id) do
      campaign
      |> Campaign.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_campaign(user_id, id) do
    with {:ok, campaign} <- get_campaign(user_id, id) do
      Repo.delete(campaign)
    end
  end

  # Group
  def create_group(user, attrs) do
    params = %{
      name: attrs["name"],
      user_id: if(user.__struct__ == OmpluseBackend.User, do: to_string(user.id), else: nil),
      company_id: if(user.__struct__ == OmpluseBackend.Company, do: to_string(user.id), else: nil)
    }

    %Group{}
    |> Group.changeset(params)
    |> Repo.insert()
  end

  def get_group(user, id) do
    query =
      case user do
        %OmpluseBackend.User{id: user_id} ->
          from g in Group, where: g.id == ^id and g.user_id == ^user_id
        %OmpluseBackend.Company{id: company_id} ->
          from g in Group, where: g.id == ^id and g.company_id == ^company_id
      end

    case Repo.one(query) do
      nil -> {:error, "Group not found"}
      group -> {:ok, group}
    end
  end

  def get_groups(user) do
    case user do
      %OmpluseBackend.User{id: user_id} ->
        Repo.all(from g in Group, where: g.user_id == ^user_id)
      %OmpluseBackend.Company{id: company_id} ->
        Repo.all(from g in Group, where: g.company_id == ^company_id)
    end
  end

  def update_group(user, id, attrs) do
    with {:ok, group} <- get_group(user, id) do
      group
      |> Group.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_group(user, id) do
    with {:ok, group} <- get_group(user, id) do
      Repo.transaction(fn ->
        # Delete associated GroupContact records
        Repo.delete_all(from gc in GroupContact, where: gc.group_id == ^group.id)
        case Repo.delete(group) do
          {:ok, group} -> {:ok, group}
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  # Group Contact
  def create_group_contact(user, attrs) do
    attrs = Map.put(attrs, "user_id", to_string(user.id))
    %GroupContact{}
    |> GroupContact.changeset(attrs)
    |> Repo.insert()
  end

  def get_group_contact(user_id, id) do
    case Repo.get_by(GroupContact, id: id, user_id: user_id) do
      nil -> {:error, "Group contact not found"}
      contact -> {:ok, contact}
    end
  end

  def get_group_contacts(group_id) do
    Repo.all(from gc in GroupContact, where: gc.group_id == ^group_id, select: [:phone_number, :name, :inserted_at])
  end

  def update_group_contact(user_id, id, attrs) do
    with {:ok, contact} <- get_group_contact(user_id, id) do
      contact
      |> GroupContact.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_group_contact(user_id, id) do
    with {:ok, contact} <- get_group_contact(user_id, id) do
      Repo.delete(contact)
    end
  end

  # SMS Processing
  def process_sms_submission(user, params) do
    sender_id = params["sender_id"]
    template_id = params["template_id"]
    message = params["message"]
    contacts_input = params["contacts"]
    group_ids = params["group_ids"]
    csv_file = params["csv_file"]
    flash = params["flash"]
    multipart = params["multipart"]

    with {:ok, sender} <- validate_sender(user.id, sender_id),
         {:ok, template} <- validate_template(user.id, template_id),
         {:ok, user} <- check_credits(user, length(fetch_contacts(contacts_input, group_ids, csv_file, user.id))) do
      contacts = fetch_contacts(contacts_input, group_ids, csv_file, user.id)
      create_sms_records(user, sender, template, message, contacts, flash, multipart)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp check_credits(user, contact_count) do
    cost_per_message = 0.1 # Example cost per SMS
    total_cost = contact_count * cost_per_message
    if user.credits >= total_cost do
      {:ok, user}
    else
      {:error, "Insufficient credits"}
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
    Enum.uniq(contacts)
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

  defp create_sms_records(user, sender, template, message, contacts, flash, multipart) do
    gateway_id = nil
    telco_id = nil
    cost_per_message = 0.1 # Example cost per SMS
    total_cost = length(contacts) * cost_per_message

    # Deduct credits
    user
    |> User.changeset(%{credits: user.credits - total_cost})
    |> Repo.update!()

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
          telco_id: telco_id,
          api_key: nil,
          channel: nil,
          telemar_id: nil,
          count: nil,
          flash: flash,
          multipart: multipart,
          part_id: nil,
          is_primary: nil,
          part_info: nil,
          cost: to_string(cost_per_message),
          cost_unit: "credits",
          encode: nil,
          company_id: to_string(user.company_id),
          dlt_error_code: nil,
          porter_id: nil
        }

        %Sms{}
        |> Sms.changeset(sms_params)
        |> Repo.insert!()
      end)

    {:ok, sms_records}
  end
end
