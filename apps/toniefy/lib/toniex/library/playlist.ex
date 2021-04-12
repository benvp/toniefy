defmodule Toniex.Library.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  alias Toniex.Accounts
  alias Toniex.Library.Track

  schema "playlists" do
    field :title, :string

    has_many :tracks, Track
    belongs_to :user, Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
