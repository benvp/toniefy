defmodule ToniexWeb.PageLive do
  use ToniexWeb, :live_view

  alias Toniex.Waitlist

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign_defaults(session, socket)
      |> assign(
        message: nil,
        waitlist_changeset: Waitlist.change_entry(%Waitlist.Entry{})
      )

    if socket.assigns.current_user do
      socket = push_redirect(socket, to: Routes.library_index_path(socket, :index))
      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  @impl true
  def handle_event("join_waitlist", %{"entry" => %{"email" => email}}, socket) do
    case Waitlist.join(email) do
      {:ok, _entry} ->
        {:noreply,
         assign(socket,
           message: "Prima. Wir kontaktieren dich, sobald dein Zugang freigeschaltet wurde."
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, waitlist_changeset: changeset)}
    end
  end
end
