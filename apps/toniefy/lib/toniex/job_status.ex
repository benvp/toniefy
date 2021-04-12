defmodule Toniex.JobStatus do
  @moduledoc """
  Stores state of recent jobs for tracking the job state at any time.

  One example usage would be to broadcast the state of the current running
  spotify recording session to the user.
  """
  import Ecto.Query, warn: false

  use GenServer

  require Logger

  alias Toniex.Repo

  @type status :: :idle | :executing | :completed | :error
  @type job_status :: %{status: status(), message: String.t(), queue: atom() | binary()}

  @spec start_link(any) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec get(integer) :: job_status | nil
  def get(job_id) do
    GenServer.call(__MODULE__, {:get, job_id})
  end

  @spec put(integer, job_status) :: integer
  def put(job_id, value) when is_integer(job_id) and is_map(value) do
    GenServer.call(__MODULE__, {:put, {job_id, value}})
    job_id
  end

  @spec delete(integer) :: integer()
  def delete(job_id) when is_integer(job_id) do
    GenServer.call(__MODULE__, {:delete, job_id})
    job_id
  end

  @spec broadcast(integer, binary()) :: :ok
  def broadcast(job_id, user_id) when is_integer(job_id) do
    GenServer.cast(__MODULE__, {:broadcast, {job_id, user_id}})
  end

  @spec subscribe(integer, binary()) :: :ok | {:error, term}
  def subscribe(job_id, user_id) when is_integer(job_id) do
    Phoenix.PubSub.subscribe(Toniex.PubSub, topic(job_id, user_id))
  end

  @spec unsubscribe(integer, binary()) :: :ok
  def unsubscribe(job_id, user_id) when is_integer(job_id) do
    Phoenix.PubSub.unsubscribe(Toniex.PubSub, topic(job_id, user_id))
  end

  # Server

  def init(:ok) do
    schedule_cleanup()
    {:ok, %{}}
  end

  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state, id), state}
  end

  def handle_call({:put, {id, value}}, _from, state) do
    state = Map.put(state, id, value)
    {:reply, Map.get(state, id), state}
  end

  def handle_call({:delete, job_id}, _from, state) do
    {value, state} = Map.pop(state, job_id)
    {:reply, value, state}
  end

  def handle_cast({:broadcast, {job_id, user_id}}, state) do
    Phoenix.PubSub.broadcast(
      Toniex.PubSub,
      topic(job_id, user_id),
      {:job_status_updated, Map.get(state, job_id)}
    )

    {:noreply, state}
  end

  def handle_info(:cleanup, state) do
    Logger.debug("Cleanup JobStatus entries...")
    # remove all jobs which are not in the db anymore
    job_ids = Repo.all(from j in Oban.Job, select: j.id)

    state =
      state
      |> Map.keys()
      |> Enum.filter(&(!Enum.member?(job_ids, &1)))
      |> Enum.reduce(state, &Map.delete(&2, &1))

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup() do
    one_hour = 60 * 60 * 1000
    Process.send_after(self(), :cleanup, one_hour)
  end

  defp topic(job_id, user_id), do: "job_status:#{user_id}:#{job_id}"
end
