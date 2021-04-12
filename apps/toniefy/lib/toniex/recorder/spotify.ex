defmodule Toniex.Recorder.Spotify do
  use Oban.Worker,
    queue: :spotify_recorder,
    max_attempts: 3

  require Logger

  alias Toniex.{Accounts, JobStatus}

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: job_id,
        queue: queue,
        args: %{"id" => id, "user_id" => user_id, "uri" => uri}
      }) do
    user = Accounts.get_user!(user_id)
    token = Toniex.Token.sign(:recorder, uri: uri, user_id: user_id)

    JobStatus.put(job_id, %{
      status: :executing,
      queue: queue,
      message: "Vorbereiten"
    })
    |> JobStatus.broadcast(user.id)

    docker_image_name = Application.fetch_env!(:toniex, Toniex.Recorder)[:docker_image_name]
    url = Application.fetch_env!(:toniex, Toniex.Recorder)[:url]

    run_script_path = Path.join([File.cwd!(), "bin/run"])

    {out, exit_code} =
      System.cmd("docker", [
        # run_script_path,
        # "docker",
        "run",
        "--init",
        "--rm",
        "--network",
        "host",
        "--name",
        id,
        "--env",
        "TONIEX_JOB_ID=#{job_id}",
        "--env",
        "TONIEX_QUEUE=#{queue}",
        "--env",
        "TONIEX_HOST=#{url}",
        "--env",
        "RECORD_TOKEN=#{token}",
        docker_image_name
      ])

    case exit_code do
      0 ->
        JobStatus.put(job_id, %{
          status: :completed,
          queue: queue,
          message: "Aufnahme erfolgreich beendet."
        })
        |> JobStatus.broadcast(user.id)

        :ok

      code ->
        JobStatus.put(job_id, %{
          status: :error,
          queue: queue,
          message: "Es ist ein Fehler aufgetreten."
        })
        |> JobStatus.broadcast(user.id)

        Logger.error(out, exit_code: exit_code)
        {:error, non_zero_exit_code: code}
    end
  end
end
