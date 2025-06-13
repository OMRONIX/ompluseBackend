defmodule OmpluseBackend.Repo.Migrations.AddLetterOfAuthorizationUrlToSenders do
  use Ecto.Migration

    def change do
      alter table(:senders) do
        add :letter_of_authorization_url, :string
      end
    end
    

end
