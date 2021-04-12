defmodule Toniex.Recorder.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias Toniex.Accounts
  alias Toniex.Recorder.SessionTrack

  schema "recorder_sessions" do
    embeds_many :tracks, SessionTrack
    belongs_to :user, Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:user_id])
    |> cast_embed(:tracks, with: &SessionTrack.changeset/2)
    |> validate_required([:tracks, :user_id])
  end
end
