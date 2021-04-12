defmodule ToniexWeb.RecordController do
  use ToniexWeb, :controller

  alias Toniex.{Accounts, JobStatus, Recorder, Token}

  plug :verify_token, type: :recorder

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(%{assigns: %{rec_data: data}} = conn, _params) do
    user = Accounts.get_user!(data.user_id)

    player_info = %{
      uri: data.uri,
      token: Token.sign(:recorder, uri: data.uri, user_id: user.id)
    }

    render(conn, "index.html", player_info: Jason.encode!(player_info))
  end

  def index(conn, _params), do: send_resp(conn, :bad_request, "Bad request")

  def token(%{assigns: %{rec_data: data}} = conn, _params) do
    user = Accounts.get_user!(data.user_id)

    case Accounts.get_session(user, :spotify) do
      nil ->
        conn
        |> put_status(500)
        |> json(%{status: 500, error: "INTERNAL_SERVER_ERROR", message: "Internal server error"})

      service_token ->
        json(conn, %{
          token: Token.sign(:recorder, uri: data.uri, user_id: user.id),
          service_token: service_token
        })
    end
  end

  def upload(%{assigns: %{rec_data: data}} = conn, %{"recorder" => record_params}) do
    user = Accounts.get_user!(data.user_id)

    uploads =
      Jason.decode!(record_params["data"])
      |> Enum.map(fn {key, value} ->
        {value, record_params["files"][key]}
      end)
      |> Enum.sort_by(fn {value, _params} -> value["key"] end)

    case Toniex.Recorder.save_session(user, uploads) do
      {:ok, _session} ->
        send_resp(conn, :accepted, "")

      {:error, _changeset} ->
        send_resp(conn, 500, "Internal Server Error")
    end
  end

  def upload(conn, _params), do: send_resp(conn, :bad_request, "Bad request")

  def status(%{assigns: %{rec_data: data}} = conn, %{
        "job_id" => job_id,
        "message" => message,
        "status" => status,
        "queue" => queue
      })
      when status in ["idle", "executing", "completed", "error"] do
    user = Accounts.get_user!(data.user_id)

    case Recorder.get_job(user, job_id) do
      %Oban.Job{} = job ->
        JobStatus.put(job.id, %{status: String.to_atom(status), queue: queue, message: message})
        |> JobStatus.broadcast(user.id)

        conn
        |> put_status(:accepted)
        |> json(%{status: 202})

      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: 400, error: "NOT_FOUND", message: "Job does not exit"})
    end
  end

  def status(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: 400, error: "BAD_REQUEST", message: "Bad request"})
  end

  def verify_token(conn, type: type) do
    token_from_header = get_req_header(conn, "authorization") |> List.first()
    token_from_params = conn.params["t"]

    token = token_from_header || token_from_params

    case Toniex.Token.verify(token, type) do
      {:ok, data} ->
        assign(conn, :rec_data, data)

      _ ->
        conn
        |> send_resp(:unauthorized, "Unauthorized")
        |> halt()
    end
  end
end
