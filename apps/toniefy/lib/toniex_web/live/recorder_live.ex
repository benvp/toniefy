defmodule ToniexWeb.RecorderLive do
  use ToniexWeb, :live_view

  alias Toniex.{Accounts, Recorder, Library}

  @max_playlists 5

  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)

    has_active_jobs = Recorder.active_jobs(socket.assigns.current_user) |> Enum.count() > 0

    has_recording_sessions =
      Recorder.list_sessions(socket.assigns.current_user)
      |> Enum.count() > 0

    spotify_connected =
      !!Accounts.get_credential_by_provider(socket.assigns.current_user, :spotify)

    max_playlists_reached =
      Library.list_playlists(socket.assigns.current_user) |> Enum.count() >= @max_playlists

    cond do
      spotify_connected && has_active_jobs ->
        socket =
          socket
          |> put_flash(
            :info,
            "Bitte füge deine aktuelle Aufnahme zu deiner Bibliothek hinzu, bevor du eine neue Aufnahme startest."
          )
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:ok, socket}

      spotify_connected && has_recording_sessions ->
        socket =
          socket
          |> put_flash(
            :info,
            "Bitte warte bis deine aktuelle Aufnahme beendet wurde bevor du eine neue Aufnahme startest."
          )
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:ok, socket}

      !spotify_connected ->
        socket =
          socket
          |> put_flash(
            :info,
            "Bitte verbinde zuerst deinen Spotify account um eine Aufnahme zu starten."
          )
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:ok, socket}

      max_playlists_reached ->
        socket =
          socket
          |> put_flash(
            :info,
            "Du hat das Maximum von 5 Playlisten erreicht. Bitte lösche zunächst eine Playlist."
          )
          |> push_redirect(to: Routes.library_index_path(socket, :index))

        {:ok, socket}

      true ->
        {:ok, socket}
    end
  end

  def handle_event("record", %{"recorder" => %{"uri" => uri}}, socket) do
    user = socket.assigns.current_user

    case Recorder.enqueue(user, uri) do
      {:ok, _job} ->
        socket = push_redirect(socket, to: Routes.library_index_path(socket, :index))
        {:noreply, socket}

      {:error, reason} ->
        IO.inspect(reason)

        socket =
          put_flash(
            socket,
            :error,
            get_error_message(reason)
          )

        {:noreply, socket}
    end
  end

  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  def render(assigns) do
    ~L"""
      <%= live_patch to: Routes.library_index_path(@socket, :index), class: "mb-4 link link__back" do %>
        <i class="fas fa-arrow-left"></i>
      <% end %>

      <div class="card">
        <h2 class="card__title">Neue Aufnahme starten</h2>
        <div class="card__body">
          <p>Bitte gib eine Spotify URL oder URI in das Textfeld ein. Dies kann der Link zu einem einzelnen Lied, einer Playlist oder einem Album sein.</p>
          <div class="mt-6">
            <%= f = form_for :recorder, "#", [phx_submit: :record] %>
              <%= text_input f, :uri, required: true, class: "input w-full text-xl py-3", placeholder: "spotify:awesome-track" %>

              <p class="mt-2">
                <%= link "Wo finde ich die Spotify URL?", to: Routes.static_path(@socket, "/images/how-to-get-spotify-uri.gif"), target: "_blank", class: "link" %>
              </p>
              <div class="text-right mt-6">
                <%= submit "Aufnahme starten", phx_disable_with: "Aufnahme starten...", class: "btn btn-primary" %>
              </div>
            </form>
          </div>
        </div>
      </div>
    """
  end

  defp get_error_message(:invalid_uri), do: "Bitte gib eine gültige Spotify URI ein."

  defp get_error_message(:max_duration_exceeded),
    do: "Das Album oder die Playlist darf maximal 89 Minuten lang sein."

  defp get_error_message(:not_found), do: "Die URI konnte nicht gefunden werden."

  defp get_error_message(_reason),
    do: "Oh nein. Es ist ein Fehler aufgetreten. Bitte versuche es nochmal."
end
