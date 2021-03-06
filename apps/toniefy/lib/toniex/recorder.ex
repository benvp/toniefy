defmodule Toniex.Recorder do
  import Ecto.Query

  alias Timex.Duration
  alias Toniex.{Accounts, Repo, JobStatus, Recorder}
  alias Toniex.Clients.Spotify
  alias Toniex.Recorder.Session

  require Logger

  @upload_dir Application.fetch_env!(:toniex, :upload_dir)

  @spec enqueue(Toniex.Accounts.User.t(), binary) ::
          {:error, :invalid_uri | :max_duration_exceeded | any} | {:ok, Oban.Job.t()}
  def enqueue(user, uri_or_url) do
    client =
      Accounts.get_session(user, :spotify)
      |> Spotify.client()

    with true <- spotify_uri_valid?(uri_or_url),
         uri <- Spotify.to_uri(uri_or_url),
         :ok <- spotify_validate_duration(client, uri) do
      %{
        id: Ecto.UUID.generate(),
        user_id: user.id,
        uri: uri
      }
      |> Recorder.Spotify.new(meta: %{user_id: user.id})
      |> Oban.insert()
      |> case do
        {:ok, %Oban.Job{} = job} ->
          JobStatus.put(job.id, %{
            status: :idle,
            queue: job.queue,
            message: "Warte auf Start der Aufnahme"
          })
          |> JobStatus.broadcast(user.id)

          {:ok, job}

        other ->
          other
      end
    else
      false -> {:error, :invalid_uri}
      error -> error
    end
  end

  def cancel_recording(job) do
    Oban.cancel_job(job.id)
    JobStatus.delete(job.id)
  end

  def list_jobs(user) do
    query =
      from j in Oban.Job,
        where: j.queue == "spotify_recorder" and fragment("meta ->> 'user_id' = ?", ^user.id)

    Repo.all(query)
  end

  def active_jobs(user) do
    query =
      from j in Oban.Job,
        where:
          j.queue == "spotify_recorder" and j.state in ["scheduled", "available", "executing"] and
            fragment("meta ->> 'user_id' = ?", ^user.id)

    Repo.all(query)
  end

  def get_job(user, job_id) do
    query =
      from j in Oban.Job,
        where:
          j.queue == "spotify_recorder" and j.id == ^job_id and
            fragment("meta ->> 'user_id' = ?", ^user.id)

    Repo.one(query)
  end

  def list_sessions(user) do
    Recorder.Session
    |> where([s], s.user_id == ^user.id)
    |> Repo.all()
  end

  @spec save_session(Toniex.Accounts.User.t(), [{map, Plug.Upload.t()}]) ::
          {:ok, Recorder.Session.t()} | {:error, binary}
  def save_session(user, uploads) do
    # TODO: check for mime type somehow (plug.upload strut type is user-generated and potentially unsafe)
    build_save_path = fn {info, file} ->
      extension = Path.extname(file.filename)
      id = String.slice(Ecto.UUID.generate(), 0..7)
      filename = "#{info["key"]}_#{id}#{extension}"
      Path.join([Path.expand(@upload_dir), user.id, filename])
    end

    save_file = fn {info, file} = upload ->
      path = build_save_path.(upload)
      File.mkdir_p!(Path.dirname(path))
      :ok = File.cp(file.path, path)
      {info, path}
    end

    files = Enum.map(uploads, save_file)

    tracks =
      files
      |> Enum.map(fn {info, path} ->
        %{title: info["title"], artist: info["artist"], duration: info["duration"], uri: path}
      end)

    changeset =
      %Recorder.Session{}
      |> Recorder.Session.changeset(%{tracks: tracks, user_id: user.id})

    case Repo.insert(changeset) do
      {:error, changeset} ->
        Enum.each(files, fn {_info, path} -> File.rm!(path) end)
        {:error, changeset}

      other ->
        other
    end
  end

  def delete_session(%Session{} = session) do
    Repo.delete(session)
  end

  defp spotify_uri_valid?(uri_or_url) do
    case Spotify.parse_uri(uri_or_url) do
      m when is_map(m) -> true
      _ -> false
    end
  end

  defp spotify_validate_duration(client, uri) do
    case Spotify.total_duration(client, uri) do
      {:ok, duration_ms} ->
        duration_minutes =
          duration_ms
          |> Duration.from_milliseconds()
          |> Duration.to_minutes()

        if duration_minutes <= 89 do
          :ok
        else
          {:error, :max_duration_exceeded}
        end

      {:error, %{"error" => %{"status" => 404}}} ->
        {:error, :not_found}

      other ->
        other
    end
  end
end
