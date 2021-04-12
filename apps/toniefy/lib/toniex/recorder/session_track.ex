defmodule Toniex.Recorder.SessionTrack do
  import Ecto.Changeset

  use Ecto.Schema

  embedded_schema do
    field :artist, :string
    field :title, :string
    field :duration, :integer
    field :uri, :string
  end

  def changeset(session_track, attrs) do
    session_track
    |> cast(attrs, [:artist, :title, :duration, :uri])
    |> validate_required([:artist, :title, :duration, :uri])
  end
end
