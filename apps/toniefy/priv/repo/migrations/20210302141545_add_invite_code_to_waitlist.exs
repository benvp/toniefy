defmodule Toniex.Repo.Migrations.AddInviteCodeToWaitlist do
  use Ecto.Migration

  def change do
    alter table(:waitlist_entries) do
      add :invite_code, :citext
    end
  end
end
