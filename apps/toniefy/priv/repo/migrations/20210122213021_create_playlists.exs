defmodule Toniex.Repo.Migrations.CreatePlaylists do
  use Ecto.Migration

  def change do
    create table(:playlists) do
      add :title, :string

      add :user_id, references("users", type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

  end
end
