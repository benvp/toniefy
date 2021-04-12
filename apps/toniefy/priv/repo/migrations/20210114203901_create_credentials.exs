defmodule Toniex.Repo.Migrations.CreateCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add :username, :string
      add :email, :string
      add :provider, :string
      add :access_token, :string, size: 5000
      add :refresh_token, :string, size: 5000
      add :scopes, :string
      add :expires_at, :utc_datetime
      add :refresh_expires_at, :utc_datetime

      add :user_id, references("users", type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:credentials, [:user_id, :provider], name: :unique_credentials_index)
  end
end
