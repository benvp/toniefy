defmodule ToniexWeb.LiveHelpers do
  import Phoenix.LiveView

  alias Toniex.Accounts

  def assign_defaults(session, socket) do
    fetch_current_user(socket, session)
  end

  def fetch_current_user(socket, session) do
    if user_token = session["user_token"] do
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)
    else
      assign(socket, current_user: nil)
    end
  end

  def active_class(expected_path, path, class, active) do
    if expected_path == path, do: class <> " " <> active, else: class
  end
end
