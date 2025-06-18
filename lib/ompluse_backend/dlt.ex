defmodule OmpluseBackend.Dlt do
  import Ecto.Query
  alias OmpluseBackend.{Repo, Contact, Campaign, Sender, Template, Group, GroupContact}
  alias Ecto.Multi

  def get_senders(%{id: user_id, __struct__: OmpluseBackend.User}) do
    Repo.all(from s in Sender, where: s.user_id == ^user_id)
  end

  def get_senders(%{id: company_id, __struct__: OmpluseBackend.Company}) do
    Repo.all(from s in Sender, where: s.company_id == ^company_id)
  end

  def get_templates(sender_id, %{id: user_id, __struct__: OmpluseBackend.User}) do
    Repo.all(from t in Template, where: t.sender_id == ^sender_id and t.user_id == ^user_id)
  end

  def get_templates(sender_id, %{id: company_id, __struct__: OmpluseBackend.Company}) do
    Repo.all(from t in Template, where: t.sender_id == ^sender_id and t.company_id == ^company_id)
  end

  def get_groups(%{id: user_id, __struct__: OmpluseBackend.User}) do
    Repo.all(from g in Group, where: g.user_id == ^user_id)
  end

  def get_groups(%{id: company_id, __struct__: OmpluseBackend.Company}) do
    Repo.all(from g in Group, where: g.company_id == ^company_id)
  end

  def get_group_contacts(group_id) do
    Repo.all(from gc in GroupContact, where: gc.group_id == ^group_id, select: [:phone_number, :name])
  end

  def process_sms(user_or_company, params) do
    with {:ok, sender} <- validate_sender(params["sender_id"], user_or_company),
         {:ok, template} <- validate_template(params["template_id"], params["sender_id"], user_or_company),
         {:ok, campaign} <- create_campaign(user_or_company, sender, template, params["content"]),
         {:ok, contacts} <- parse_contacts(params["contacts"], params, user_or_company, campaign.id),
         :ok <- send_sms(contacts, campaign) do
      {:ok, %{message: "SMS sent successfully", campaign_id: campaign.id}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_sender(sender_id, user_or_company) do
    sender =
      case user_or_company do
        %OmpluseBackend.User{id: user_id} ->
          Repo.get_by(Sender, sender_id: sender_id, user_id: user_id)
        %OmpluseBackend.Company{id: company_id} ->
          Repo.get_by(Sender, sender_id: sender_id, company_id: company_id)
      end

    if sender, do: {:ok, sender}, else: {:error, :invalid_sender}
  end

  defp validate_template(template_id, sender_id, user_or_company) do
    template =
      case user_or_company do
        %OmpluseBackend.User{id: user_id} ->
          Repo.get_by(Template, template_id: template_id, sender_id: sender_id, user_id: user_id)
        %OmpluseBackend.Company{id: company_id} ->
          Repo.get_by(Template, template_id: template_id, sender_id: sender_id, company_id: company_id)
      end

    if template, do: {:ok, template}, else: {:error, :invalid_template}
  end

  defp create_campaign(user_or_company, sender, template, content) do
    attrs = %{
      name: "SMS Campaign #{DateTime.utc_now() |> DateTime.to_string()}",
      entity_id: sender.entity_id,
      sender_id: sender.sender_id,
      template_id: template.template_id,
      desc: content,
      status: "approved",
      user_id: if(user_or_company.__struct__ == OmpluseBackend.User, do: user_or_company.id, else: nil),
      company_id: if(user_or_company.__struct__ == OmpluseBackend.Company, do: user_or_company.id, else: nil)
    }

    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert()
  end

  defp parse_contacts(contacts_input, params, user_or_company, campaign_id) do
    user_id = if user_or_company.__struct__ == OmpluseBackend.User, do: user_or_company.id, else: nil
    company_id = if user_or_company.__struct__ == OmpluseBackend.Company, do: user_or_company.id, else: nil
    remove_duplicates = Map.get(params, "remove_duplicates", false)
    remove_invalid = Map.get(params, "remove_invalid", false)

    contacts =
      case contacts_input do
        %{"textarea" => numbers} ->
          numbers
          |> String.split([",", "\n"], trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.map(fn phone_number ->
            %{phone_number: phone_number, name: nil, user_id: user_id, company_id: company_id, campaign_id: campaign_id}
          end)

        %{"file" => file_data, "file_type" => file_type} ->
          parse_file(file_data, file_type, user_id, company_id, campaign_id)

        %{"group_id" => group_id} ->
          get_group_contacts(group_id)
          |> Enum.map(fn gc ->
            %{phone_number: gc.phone_number, name: gc.name, user_id: user_id, company_id: company_id, campaign_id: campaign_id}
          end)
      end

    contacts = if remove_duplicates, do: Enum.uniq_by(contacts, & &1.phone_number), else: contacts
    contacts = if remove_invalid, do: Enum.filter(contacts, &valid_phone_number?/1), else: contacts

    if Enum.empty?(contacts) do
      {:error, :no_valid_contacts}
    else
      Multi.new()
      |> Multi.run(:insert_contacts, fn repo, _ ->
        contacts
        |> Enum.reduce_while({:ok, []}, fn attrs, {:ok, inserted} ->
          case repo.insert(Contact.changeset(%Contact{}, attrs)) do
            {:ok, contact} -> {:cont, {:ok, [contact | inserted]}}
            {:error, changeset} -> {:halt, {:error, changeset}}
          end
        end)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{insert_contacts: contacts}} -> {:ok, contacts}
        {:error, :insert_contacts, changeset, _} -> {:error, changeset}
      end
    end
  end

  defp parse_file(file_data, "csv", user_id, company_id, campaign_id) do
    file_data
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.filter(&String.trim/1)
    |> Enum.map(fn row ->
      case String.split(row, ",") do
        [phone_number | rest] ->
          name = if rest != [], do: String.trim(List.first(rest)), else: nil
          %{phone_number: String.trim(phone_number), name: name, user_id: user_id, company_id: company_id, campaign_id: campaign_id}
        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp parse_file(file_data, "xlsx", user_id, company_id, campaign_id) do
    # Assume file_data is base64-decoded XLSX content
    # Mock parsing (requires actual XLSX parsing library like `xlsxir`)
    file_data
    |> String.split("\n")
    |> Enum.drop(1)
    |> Enum.filter(&String.trim/1)
    |> Enum.map(fn row ->
      [phone_number | rest] = String.split(row, ",")
      name = if rest != [], do: String.trim(List.first(rest)), else: nil
      %{phone_number: String.trim(phone_number), name: name, user_id: user_id, company_id: company_id, campaign_id: campaign_id}
    end)
  end

  defp valid_phone_number?(%{phone_number: phone_number}) do
    phone_number =~ ~r/^\d{10}$/
  end

  defp send_sms(contacts, campaign) do
    # Batch process to avoid timeouts
    contacts
    |> Enum.chunk_every(100)
    |> Enum.each(fn batch ->
      batch
      |> Enum.each(fn contact ->
        # Mock SMS sending (replace with DLT platform API)
        IO.inspect(%{
          phone_number: contact.phone_number,
          sender_id: campaign.sender_id,
          template_id: campaign.template_id,
          content: campaign.content
        }, label: "Sending SMS")
      end)
    end)
    :ok
  end
end
