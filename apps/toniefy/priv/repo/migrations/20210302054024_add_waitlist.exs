defmodule Toniex.Repo.Migrations.AddWaitlist do
  use Ecto.Migration

  def change do
    create table(:waitlist_entries) do
      add :email, :citext, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:waitlist_entries, [:email])
  end
end
