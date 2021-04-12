defmodule Toniex.Library.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias Toniex.Library

  schema "tracks" do
    field :artist, :string
    field :duration, :integer
    field :title, :string
    field :uri, :string

    belongs_to :playlist, Library.Playlist

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:artist, :title, :duration, :uri, :playlist_id])
    |> validate_required([:artist, :title, :duration, :uri, :playlist_id])
  end
end
