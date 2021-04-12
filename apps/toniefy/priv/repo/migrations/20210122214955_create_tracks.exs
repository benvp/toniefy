defmodule Toniex.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :artist, :string
      add :title, :string
      add :duration, :integer
      add :uri, :string
      add :playlist_id, references(:playlists, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:tracks, [:playlist_id])
  end
end
