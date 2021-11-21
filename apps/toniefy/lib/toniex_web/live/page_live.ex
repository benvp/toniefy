defmodule ToniexWeb.PageLive do
  use ToniexWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)

    if socket.assigns.current_user do
      socket = push_redirect(socket, to: Routes.library_index_path(socket, :index))
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div></div>
    """
  end
end
