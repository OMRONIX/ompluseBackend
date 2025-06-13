defmodule OmpluseBackend.DltManager do
  import Ecto.Query
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
  def create_sender(user, attrs) do
    with {:ok, entity} <- get_approved_entity(user.id, attrs["entity_id"]) do
      %Sender{}
      |> Sender.changeset(Map.merge(attrs, %{entity_id: entity.id}))
      |> Repo.insert()
    end
  end

  def list_senders(user_id) do
    Sender
    |> join(:inner, [s], e in DltEntity, on: s.entity_id == e.id)
    |> where([s, e], e.user_id == ^user_id)
    |> Repo.all()
  end

  #template
  def create_template(user, attrs) do
    with {:ok, entity} <- get_approved_entity(user.id, attrs["entity_id"]),
          {:ok, sender} <- get_approved_sender(entity, attrs["sender_id"]) do
      %Template{}
      |> Template.changeset(Map.merge(attrs, %{entity_id: entity.id, sender_id: sender.id}))
      |> Repo.insert()
    end
  end

  def list_templates(user_id) do
    Template
    |> join(:inner, [t], e in DltEntity, on: t.entity_id == e.id)
    |> join(:inner, [t, e], s in Sender, on: t.sender_id == s.id)
    |> where([t, e, s], e.user_id == ^user_id)
    |> Repo.all()
  end

  #campaign
  def create_campaign(user, attrs) do
    with {:ok, entity} <- get_approved_entity(user.id, attrs["entity_id"]),
          {:ok, sender} <- get_approved_sender(entity, attrs["sender_id"]),
          {:ok, template} <- Repo.get(Template, attrs["template_id"]) do
      %OmpluseBackend.Campaign{}
      |> OmpluseBackend.Campaign.changeset(Map.merge(attrs, %{
        user_id: user.id,
        entity_id: entity.id,
        sender_id: sender.id,
        template_id: template.id
      }))
      |> Repo.insert()
    end
  end

  def list_campaigns(user_id) do
    OmpluseBackend.Campaign
    |> where([c, e, s, t], e.user_id == ^user_id)
    |> Repo.all()
  end

  defp get_approved_entity(user_id, entity_id) do
    entity = Repo.get(DltEntity, entity_id)

    if entity && entity.user_id == user_id && entity.status == :approved do
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
