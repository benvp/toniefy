defmodule Mix.Tasks.Record do
  @dialyzer {:no_return, add_tracks_to_multipart: 2}

  @shortdoc "Record a track from Spotify."

  use Mix.Task
  use Wallaby.DSL

  require Logger

  alias ToniexRecorder.WebPlayer
  alias Tesla.Multipart

  # 90 minutes is maximum time on a tonie.
  # we default to 89 minutes here to have some tolerance
  # TODO: fail early and don't record until the max time
  @max_record_time 89 * 60 * 1000
  @recording_filename "recording.mp3"
  @recording_trimmed_filename "recording_trimmed.mp3"

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:wallaby)
    {:ok, _} = Application.ensure_all_started(:porcelain)

    {:ok, session} = Wallaby.start_session(window_size: [width: 1280, height: 720])

    host = Application.fetch_env!(:toniex_recorder, :toniex_host)
    token = Application.fetch_env!(:toniex_recorder, :record_token)
    url = host |> URI.merge("/record?t=#{token}") |> URI.to_string()

    Mix.shell().info("""
    > Toniex Recorder
    >
    > --------------------------------
    > HOST: #{host}
    > URL: #{url}
    > --------------------------------
    >
    """)

    Mix.shell().info("Setting up audio...")

    System.cmd("pactl", ["load-module", "module-null-sink", "sink_name=toniex"])
    System.cmd("pactl", ["set-default-sink", "toniex"])

    Mix.shell().info("Starting stream...")

    maybe_report_status(:executing, "Starte Aufnahme")

    page = visit(session, url)

    {:ok, web_player} = WebPlayer.start_link(page)
    WebPlayer.subscribe(web_player, self())

    with {:ok, _player} <- wait_until_playing(),
         {:ok, tracks} <- record(),
         {:ok, trimmed_file_path} <-
           trim_recording(
             Path.expand(@recording_filename),
             Path.join([
               Path.expand(Path.dirname(@recording_filename)),
               @recording_trimmed_filename
             ])
           ),
         splitted_tracks = split_tracks!(trimmed_file_path, tracks) do
      Mix.shell().info("☁️ Uploading tracks...")

      case upload(splitted_tracks) do
        %{status: 202} ->
          maybe_report_status(:executing, "Fertigstellen")
          Mix.shell().info("✅ Tracks have been uploaded.")
          Wallaby.end_session(session)
          :ok

        res ->
          maybe_report_status(:error, "Es ist ein Fehler aufgetreten.")
          Wallaby.end_session(session)
          Mix.raise("An error occurred: #{res.status}")
          {:error, :upload_error}
      end
    else
      {:error, reason} ->
        maybe_report_status(:error, "Es ist ein Fehler aufgetreten.")
        Mix.raise("An error occurred: #{reason}")
    end
  end

  defp wait_until_playing(timeout \\ 10_000) do
    receive do
      {:player_updated, player, _prev_player} ->
        Logger.info("wait_until_playing: received player_state=#{inspect(player.player_state)}")

        if !player.player_state || player.player_state["paused"] do
          Logger.info("Player is not ready (paused or no state). Waiting a bit longer...")
          wait_until_playing()
        else
          Logger.info("Player is now playing. Proceeding with recording.")
          {:ok, player}
        end

      {:player_error, error} ->
        {:error, error["message"]}
    after
      timeout ->
        maybe_report_status(:error, "Es ist ein Fehler aufgetreten.")
        {:error, :timeout}
    end
  end

  defp record() do
    {:ok, tracks_pid} = ToniexRecorder.Tracks.start_link([])

    Mix.shell().info("Recording...")
    maybe_report_status(:executing, "Aufnahme beginnen")

    record_proc = start_recording()

    case wait_until_record_finished(tracks_pid, _playback_started = false) do
      :ok ->
        # record a bit longer, just to make sure the split
        # later does not exceed the full length of the track
        Process.sleep(1_000)

        stop_recording(record_proc)

        tracks =
          ToniexRecorder.Tracks.get(tracks_pid)
          |> Enum.reverse()

        {:ok, tracks}

      other ->
        other
    end
  end

  defp start_recording() do
    Porcelain.spawn_shell(
      "./bin/run.sh parec -d toniex.monitor --format=s16le | lame -r --quiet --preset standard - \"#{
        @recording_filename
      }\""
    )
  end

  defp wait_until_record_finished(tracks_pid, playback_started) do
    receive do
      {:track_changed, track, _prev_track} ->
        Mix.shell().info("Recording song: #{track["name"]}.")
        maybe_report_status(:executing, track["name"])

        case ToniexRecorder.Tracks.get(tracks_pid) |> List.first() do
          {_m, t} -> ToniexRecorder.Tracks.put(tracks_pid, build_track(t.key + 1, track))
          nil -> ToniexRecorder.Tracks.put(tracks_pid, build_track(1, track))
        end

        wait_until_record_finished(tracks_pid, playback_started)

      {:player_updated,
       %{player_state: %{"paused" => paused, "duration" => duration, "position" => position}},
       _prev_player} ->
        Logger.info(
          "Player state update: paused=#{paused}, position=#{position}, duration=#{duration}, playback_started=#{playback_started}"
        )

        # Track whether playback has actually started (position > 0 means audio is playing)
        playback_started = playback_started || position > 0

        # Detect unexpected stop by comparing the current position
        # with the track duration. Anyway, this is not perfectly accurate
        # as sometimes the tracks pauses a few ms before and then sets
        # the position again to zero - therefore we add a threshold.
        threshold = 300

        cond do
          # Only consider recording finished if playback actually started and now position is 0
          paused && position == 0 && playback_started ->
            Logger.info("Playback finished (paused with position=0 after playback started)")
            :ok

          # Ignore paused && position == 0 if playback hasn't started yet (SDK initialization)
          paused && position == 0 && !playback_started ->
            Logger.info("Ignoring paused state with position=0 - playback hasn't started yet")
            wait_until_record_finished(tracks_pid, playback_started)

          paused && position + threshold <= duration ->
            maybe_report_status(
              :error,
              "Wiedergabe wurde beendet. Vielleicht wurde Spotify angehalten?"
            )

            {:error, :playback_stopped_unexpectedly}

          true ->
            wait_until_record_finished(tracks_pid, playback_started)
        end

      {:player_error, error} ->
        {:error, error["message"]}
    after
      @max_record_time ->
        maybe_report_status(:error, "Maximale Aufnahmelänge von 90 Minuten erreicht.")
        {:error, :max_record_time_exceeded}
    end
  end

  defp stop_recording(proc), do: Porcelain.Process.stop(proc)

  defp upload(tracks) do
    data =
      Enum.reduce(tracks, %{}, fn track, acc ->
        Map.put(acc, track.key, track)
      end)

    mp =
      Multipart.new()
      |> Multipart.add_content_type_param("charset=utf-8")
      |> add_tracks_to_multipart(tracks)
      |> Multipart.add_field("recorder[data]", Jason.encode!(data))

    host = Application.fetch_env!(:toniex_recorder, :toniex_host)
    token = Application.fetch_env!(:toniex_recorder, :record_token)
    url = host |> URI.merge("/record") |> URI.to_string()

    Tesla.post!(url, mp, headers: [{"authorization", token}])
  end

  defp add_tracks_to_multipart(mp, tracks) do
    # no idea why dialyzer complains here. This should certainly work
    Enum.reduce(tracks, mp, fn track, acc ->
      Multipart.add_file(acc, track.path, name: "recorder[files][#{track.key}]")
    end)
  end

  defp build_track(key, spotify_track) do
    %{
      key: key,
      title: spotify_track["name"],
      artist:
        spotify_track["artists"]
        |> Enum.map(& &1["name"])
        |> Enum.join(", "),
      duration: spotify_track["duration_ms"]
    }
  end

  defp trim_recording(input_path, output_path) do
    maybe_report_status(:executing, "Verarbeite Songs. Dies kann ein paar Minuten dauern.")

    %Porcelain.Result{status: 0} =
      Porcelain.shell("sox '#{input_path}' '#{output_path}' silence 1 0.1 1%")

    {:ok, output_path}
  end

  @spec split_tracks!(binary(), list({integer(), map()})) :: list(map())
  defp split_tracks!(file_path, track_markers) do
    Mix.shell().info("Splitting tracks...")

    track_markers
    |> Enum.map(fn {m, t} ->
      output = Path.join([Path.expand("output"), "#{t.key}.mp3"])

      # convert to float and seconds as sox requires a float value when specifying time
      from = m / 1000
      to = t.duration / 1000

      Logger.debug("Splitting track #{t.key} from #{from} to #{to}.")

      # ensure exit code is 0
      %Porcelain.Result{status: 0} =
        Porcelain.shell("sox '#{file_path}' '#{output}' trim #{from} #{to}")

      Map.put(t, :path, output)
    end)
  end

  defp maybe_report_status(status, message) do
    host = Application.fetch_env!(:toniex_recorder, :toniex_host)
    token = Application.fetch_env!(:toniex_recorder, :record_token)
    job_id = Application.fetch_env!(:toniex_recorder, :job_id)
    queue = Application.fetch_env!(:toniex_recorder, :queue)

    url = host |> URI.merge("/record/status") |> to_string()

    Tesla.client([
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"authorization", token}]}
    ])
    |> Tesla.put(url, %{job_id: job_id, queue: queue, status: status, message: message})

    :ok
  end
end
