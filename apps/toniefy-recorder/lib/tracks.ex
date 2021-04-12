defmodule ToniexRecorder.Tracks do
  use Agent

  @type track_tuple() :: {integer(), map()}

  def start_link(_opts) do
    Agent.start_link(fn -> [] end)
  end

  @spec get(pid) :: list(track_tuple)
  def get(pid) do
    Agent.get(pid, fn t -> t end)
  end

  @spec put(pid, map) :: :ok
  def put(pid, track) do
    Agent.update(pid, fn
      [] ->
        [{0, track}]

      [{m, t} | _tail] = list ->
        entry = {t.duration + m, track}
        [entry | list]
    end)
  end
end
