defmodule Toniex.Library.ToniesUpload do
  use Oban.Worker,
    queue: :tonies_upload,
    max_attempts: 3

  require Logger

  alias Toniex.{Accounts, Clients, Library, JobStatus}

  def perform(%Oban.Job{
        id: job_id,
        queue: queue,
        args: %{
          "user_id" => user_id,
          "playlist_id" => playlist_id,
          "household_id" => household_id,
          "tonie_id" => tonie_id
        }
      }) do
    Logger.debug("Starting ToniesUpload job for user #{user_id}.")

    user = Accounts.get_user!(user_id)
    playlist = Library.get_playlist!(user, playlist_id)

    JobStatus.put(job_id, %{
      status: :executing,
      queue: queue,
      message: "Starte übertragung"
    })
    |> JobStatus.broadcast(user.id)

    client =
      Accounts.get_session(user, :tonies)
      |> Clients.Tonies.client()

    Logger.debug("Uploading tracks to tonies...")

    JobStatus.put(job_id, %{
      status: :executing,
      queue: queue,
      message: "Songs hochladen"
    })
    |> JobStatus.broadcast(user.id)

    uploads = upload_tracks(client, playlist.tracks)
    {:ok, _} = update_creative_tonie(client, household_id, tonie_id, uploads)

    Logger.debug("Waiting to finish transcoding...")

    JobStatus.put(job_id, %{
      status: :executing,
      queue: queue,
      message: "Warte auf Verarbeitung"
    })
    |> JobStatus.broadcast(user.id)

    task = Task.async(fn -> start_polling(client, household_id, tonie_id) end)

    case Task.await(task, :infinity) do
      {:ok, _count} ->
        JobStatus.put(job_id, %{
          status: :completed,
          queue: queue,
          message:
            "Übertragung erfolgreich. Du kannst die Songs jetzt auf deinem Tonie abspielen."
        })
        |> JobStatus.broadcast(user.id)

        Logger.debug("Transcoding finished. Creative tonie is ready.")
        :ok

      {:error, reason} ->
        JobStatus.put(job_id, %{
          status: :error,
          queue: queue,
          message:
            "Keine Rückmeldung bei der Verarbeitung. Bitte überprüfe, ob die Songs auf deinem Tonie angekommen sind."
        })
        |> JobStatus.broadcast(user.id)

        Logger.warn(
          "Transcoding did not finish due to timeout. This doesn't mean that it won't finish eventually."
        )

        {:discard, reason}
    end
  end

  defp upload_tracks(client, tracks) do
    Enum.map(tracks, fn t ->
      {:ok, id} = Clients.Tonies.upload_file(client, t.uri)
      %{id: id, track: t}
    end)
  end

  defp update_creative_tonie(client, household_id, tonie_id, uploads) do
    chapters = Enum.map(uploads, &%{id: &1.id, file: &1.id, title: &1.track.title})
    Clients.Tonies.update_chapters(client, household_id, tonie_id, chapters)
  end

  defp start_polling(client, household_id, tonie_id, max_attempts \\ 60) do
    {:ok, result} = Clients.Tonies.get_chapters(client, household_id, tonie_id)

    transcoding_count =
      result
      |> Map.fetch!("chapters")
      |> Enum.count(& &1["transcoding"])

    cond do
      transcoding_count === 0 ->
        {:ok, transcoding_count}

      transcoding_count > 0 && max_attempts > 0 ->
        receive do
        after
          5_000 ->
            start_polling(client, household_id, tonie_id, max_attempts - 1)
        end

      true ->
        {:error, :timeout}
    end
  end
end
