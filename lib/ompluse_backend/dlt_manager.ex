defmodule OmpluseBackend.DltManager do
  import Ecto.Query
  alias OmpluseBackend.Campaign
  alias OmpluseBackend.Repo
  alias OmpluseBackend.{DltEntity, Sender, Template}

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


  defp get_approved_entity(user_id, entity_id) do
    entity = Repo.get(DltEntity, entity_id)

    if entity && entity.user_id == user_id && entity.verification_status == :approved do
      {:ok, entity}
    else
      {:error, "Entity not found or not approved"}
    end
  end

  defp get_approved_sender(entity, sender_id) do
    sender = Repo.get(Sender, sender_id)

    if sender && sender.entity_id == entity.id && sender.status == :approved do
      {:ok, sender}
    else
      {:error, "Sender not found or not approved"}
    end
  end

  def get_approved_template(entity_id, template_id) do
    template = Repo.get(Template, template_id)

    if template && template.entity_id == entity_id && template.status == :approved do
      {:ok, template}
    else
      {:error, "Template not found or not approved"}
    end
  end

end
