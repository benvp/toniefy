defmodule Toniex.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Toniex.Repo
  alias Toniex.JobStatus
  alias Toniex.Library.{Playlist, Track, ToniesUpload}

  @doc """
  Returns the list of playlists.

  ## Examples

      iex> list_playlists(user)
      [%Playlist{}, ...]

  """
  def list_playlists(user) do
    Playlist
    |> where([p], p.user_id == ^user.id)
    |> preload(:tracks)
    |> Repo.all()
  end

  @doc """
  Gets a single playlist.

  Raises `Ecto.NoResultsError` if the Playlist does not exist.

  ## Examples

      iex> get_playlist!(123)
      %Playlist{}

      iex> get_playlist!(456)
      ** (Ecto.NoResultsError)

  """

  def get_playlist!(user, id) do
    Playlist
    |> where([p], p.id == ^id and p.user_id == ^user.id)
    |> preload(:tracks)
    |> Repo.one!()
  end

  @doc """
  Creates a playlist.

  ## Examples

      iex> create_playlist(user, %{field: value})
      {:ok, %Playlist{}}

      iex> create_playlist(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_playlist(user, attrs \\ %{}) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  # @doc """
  # Updates a playlist.

  # ## Examples

  #     iex> update_playlist(playlist, %{field: new_value})
  #     {:ok, %Playlist{}}

  #     iex> update_playlist(playlist, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """

  # def update_playlist(%Playlist{} = playlist, attrs) do
  #   playlist
  #   |> Playlist.changeset(attrs)
  #   |> Repo.update()
  # end

  @doc """
  Deletes a playlist.

  ## Examples

      iex> delete_playlist(playlist)
      {:ok, %Playlist{}}

      iex> delete_playlist(playlist)
      {:error, %Ecto.Changeset{}}

  """

  def delete_playlist(%Playlist{} = playlist) do
    case Repo.delete(playlist) do
      {:ok, list} ->
        Repo.preload(playlist, :tracks)
        |> Map.get(:tracks)
        |> Enum.each(&File.rm(&1.uri))

        {:ok, list}

      other ->
        other
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking playlist changes.

  ## Examples

      iex> change_playlist(playlist)
      %Ecto.Changeset{data: %Playlist{}}

  """

  # def change_playlist(%Playlist{} = playlist, attrs \\ %{}) do
  #   Playlist.changeset(playlist, attrs)
  # end

  ## Tracks

  def create_track(attrs) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  def create_tracks(attrs) do
    multi =
      Enum.reduce(attrs, Multi.new(), fn a, m ->
        Multi.insert(m, a.id, Track.changeset(%Track{}, a))
      end)

    Repo.transaction(multi)
  end

  @spec enqueue_tonie_upload(atom | %{:id => any, optional(any) => any}, keyword) ::
          {:error, any} | {:ok, Oban.Job.t()}
  def enqueue_tonie_upload(user, params) do
    %{
      id: Ecto.UUID.generate(),
      user_id: user.id,
      playlist_id: Keyword.fetch!(params, :playlist_id),
      household_id: Keyword.fetch!(params, :household_id),
      tonie_id: Keyword.fetch!(params, :tonie_id)
    }
    |> ToniesUpload.new(meta: %{user_id: user.id})
    |> Oban.insert()
    |> case do
      {:ok, %Oban.Job{} = job} ->
        JobStatus.put(job.id, %{
          status: :idle,
          queue: job.queue,
          message: "Warte auf Übertragung"
        })
        |> JobStatus.broadcast(user.id)

        {:ok, job}

      other ->
        other
    end
  end

  def active_upload_jobs(user) do
    query =
      from j in Oban.Job,
        where:
          j.queue == "tonies_upload" and j.state in ["scheduled", "available", "executing"] and
            fragment("meta ->> 'user_id' = ?", ^user.id)

    Repo.all(query)
  end
end
