defmodule ToniexWeb.LibraryLive.Index do
  use ToniexWeb, :live_view

  alias Toniex.{Accounts, Library, Recorder, Clients, JobStatus}
  alias ToniexWeb.LibraryLive.PlaylistComponent

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    current_user = socket.assigns.current_user

    playlists = Library.list_playlists(current_user)
    sessions = Recorder.list_sessions(current_user)

    upload_job = Library.active_upload_jobs(current_user) |> List.first()
    upload_job_status = if upload_job, do: JobStatus.get(upload_job.id), else: nil

    if upload_job do
      JobStatus.subscribe(upload_job.id, current_user.id)
    end

    job = Recorder.active_jobs(current_user) |> List.first()
    job_status = if job, do: JobStatus.get(job.id), else: nil

    if job do
      JobStatus.subscribe(job.id, current_user.id)
    end

    socket =
      assign(socket,
        current_job: job,
        job_status: job_status,
        upload_job_status: upload_job_status,
        playlists: playlists,
        creative_tonies: creative_tonies(current_user),
        has_completed_sessions: Enum.count(sessions) > 0
      )

    {:ok, socket}
  end

  defp creative_tonies(current_user) do
    case Accounts.get_session(current_user, :tonies) do
      nil ->
        nil

      token ->
        {:ok, tonies} =
          Clients.Tonies.client(token)
          |> Clients.Tonies.get_main_household_creative_tonies()

        tonies
    end
  end

  @impl true
  def handle_event("save_to_tonie", %{"upload_to" => %{"id" => tonie_id}}, socket) do
    tonie = Enum.find(socket.assigns.creative_tonies, &(&1["id"] == tonie_id))

    Library.enqueue_tonie_upload(socket.assigns.current_user,
      playlist_id: socket.assigns.playlist.id,
      household_id: tonie["householdId"],
      tonie_id: tonie["id"]
    )

    socket =
      socket
      |> put_flash(:info, "Übertragung wird gestartet.")
      |> push_redirect(to: Routes.library_index_path(socket, :index))

    {:noreply, socket}
  end

  def handle_event("delete-playlist", _params, socket) do
    case Library.delete_playlist(socket.assigns.playlist) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Playlist wurde gelöscht.")
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash(
            :error,
            "Playlist konnte nicht gelöscht werden. Verusche es bitte noch einmal."
          )
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:noreply, socket}
    end
  end

  def handle_event("cancel-recording", _params, socket) do
    job = socket.assigns.current_job
    if job, do: Recorder.cancel_recording(job)
    {:noreply, assign(socket, job: nil, job_status: nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, uri, socket) do
    playlist = Library.get_playlist!(socket.assigns.current_user, id)
    socket = assign(socket, playlist: playlist, uri: URI.parse(uri))

    {:noreply, socket}
  end

  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  def handle_info({:job_status_updated, %{queue: "tonies_upload"} = status}, socket) do
    {:noreply, assign(socket, upload_job_status: status)}
  end

  @impl true
  def handle_info({:job_status_updated, %{queue: "spotify_recorder"} = status}, socket) do
    socket = assign(socket, job_status: status)

    case status.status do
      :completed ->
        sessions = Recorder.list_sessions(socket.assigns.current_user)

        {:noreply,
         assign(socket, job_status: status, has_completed_sessions: Enum.count(sessions) > 0)}

      _ ->
        {:noreply, assign(socket, job_status: status)}
    end
  end
end
