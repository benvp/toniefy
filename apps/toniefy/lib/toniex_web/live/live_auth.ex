defmodule ToniexWeb.LiveAuth do
  import Phoenix.LiveView

  alias Toniex.Accounts

  def on_mount(:default, _params, session, socket) do
    {:cont, fetch_current_user(socket, session)}
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = fetch_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, socket}
    end
  end

  defp fetch_current_user(socket, session) do
    if user_token = session["user_token"] do
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)
    else
      assign(socket, current_user: nil)
    end
  end
end
