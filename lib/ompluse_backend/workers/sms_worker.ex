defmodule OmpluseBackend.Workers.SmsWorker do
  use Oban.Worker, queue: :sms, max_attempts: 5

  alias OmpluseBackend.{Repo, Dlt.Sms}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"sms_id" => sms_id}}) do
    case Repo.get(Sms, sms_id) do
      nil ->
        {:error, "SMS record not found"}

      sms ->
        # Placeholder for actual SMS service
        IO.puts("Processing SMS to #{sms.phone_number}")
        #sms_service_function(sms)
        :ok
    end
  end
end
