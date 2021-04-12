defmodule Toniex.Repo.Migrations.CreateRecorderSessions do
  use Ecto.Migration

  def change do
    create table(:recorder_sessions) do
      add :tracks, :map, default: %{}
      add :user_id, references("users", type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

  end
end
