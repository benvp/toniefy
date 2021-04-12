defmodule ToniexRecorder.WebPlayer do
  @moduledoc """
  Handles the Spotify web player info and the current state.
  Allows subscribing for updates on the player.
  """
  @broadcast_interval 100

  use GenServer
  use Wallaby.DSL

  require Logger

  # public API

  @spec start_link(Wallaby.Session.t()) :: GenServer.on_start()
  def start_link(session) do
    GenServer.start_link(__MODULE__, session)
  end

  def get_player(pid) do
    GenServer.call(pid, :get_player)
  end

  def subscribe(pid, subscriber_pid) do
    GenServer.cast(pid, {:subscribe, subscriber_pid})
  end

  def unsubscribe(pid, subscriber_pid) do
    GenServer.cast(pid, {:unsubscribe, subscriber_pid})
  end

  # GenServer callbacks

  def init(session) do
    schedule_update_player()

    state = %{
      subscribers: [],
      session: session,
      player_info: player_info(session),
      player_state: player_state(session),
      player_error: player_error(session)
    }

    {:ok, state}
  end

  def handle_call(:get_player, _from, state) do
    {:reply, player(state), state}
  end

  def handle_cast({:subscribe, pid}, state) do
    {:noreply, %{state | subscribers: [pid | state.subscribers]}}
  end

  def handle_cast({:broadcast, {:player_updated, prev_state}}, state) do
    Enum.each(state.subscribers, fn pid ->
      send(pid, {:player_updated, player(state), player(prev_state)})
    end)

    {:noreply, state}
  end

  def handle_cast({:broadcast, {:track_changed, prev_state}}, state) do
    Enum.each(state.subscribers, fn pid ->
      send(pid, {:track_changed, current_track(state), current_track(prev_state)})
    end)

    {:noreply, state}
  end

  def handle_cast({:broadcast, :player_error}, state) do
    Enum.each(state.subscribers, fn pid ->
      send(pid, {:player_error, state[:player_error]})
    end)

    {:noreply, state}
  end

  def handle_cast({:unsubscribe, pid}, state) do
    state = Map.update!(state, :subscribers, &List.delete(&1, pid))
    {:noreply, state}
  end

  def handle_info(:update_player, state) do
    new_state = update_player(state)

    if player(state) !== player(new_state) do
      GenServer.cast(self(), {:broadcast, {:player_updated, state}})
    end

    if current_track(state)["id"] !== current_track(new_state)["id"] do
      GenServer.cast(self(), {:broadcast, {:track_changed, state}})
    end

    if new_state.player_error do
      GenServer.cast(self(), {:broadcast, :player_error})
    end

    schedule_update_player()
    {:noreply, new_state}
  end

  # private

  defp schedule_update_player do
    Process.send_after(self(), :update_player, @broadcast_interval)
  end

  defp update_player(state) do
    %{
      state
      | player_info: player_info(state.session),
        player_state: player_state(state.session),
        player_error: player_error(state.session)
    }
  end

  defp player(state) do
    Map.take(state, [:player_info, :player_state])
  end

  defp current_track(state) do
    state
    |> player()
    |> get_in([:player_state, "currentTrack"])
  end

  defp player_info(session) do
    session
    |> find(Query.css("#player-info", visible: false))
    |> Element.attr("data-info")
    |> case do
      "" -> nil
      val -> Jason.decode!(val)
    end
  end

  defp player_state(session) do
    session
    |> find(Query.css("#player-state", visible: false))
    |> Element.attr("data-state")
    |> case do
      "" -> nil
      val -> Jason.decode!(val)
    end
  end

  defp player_error(session) do
    session
    |> find(Query.css("#player-error", visible: false))
    |> Element.attr("data-error")
    |> case do
      "" -> nil
      val -> Jason.decode!(val)
    end
  end
end
