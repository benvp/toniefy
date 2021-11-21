defmodule ToniexWeb.ReviewSessionLive do
  use ToniexWeb, :live_view

  alias Toniex.{Library, Recorder}
  alias ToniexWeb.LibraryLive.PlaylistComponent

  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    current_user = socket.assigns.current_user

    session =
      current_user
      |> Recorder.list_sessions()
      |> List.first()

    playlists = Library.list_playlists(current_user)

    {:ok, assign(socket, session: session, playlists: playlists)}
  end

  def handle_event("assign", %{"playlist" => %{"id" => id}}, socket) do
    %{current_user: current_user, session: session} = socket.assigns

    playlist = Library.get_playlist!(current_user, id)
    {:ok, _changes} = add_tracks_to_playlist(playlist, session.tracks)
    Recorder.delete_session(session)

    socket =
      socket
      |> put_flash(
        :success,
        "#{Enum.count(socket.assigns.session.tracks)} songs have been added to playlist \"#{playlist.title}\"."
      )
      |> push_redirect(to: Routes.library_index_path(socket, :index))

    {:noreply, socket}
  end

  def handle_event("create_and_assign", %{"playlist" => %{"title" => title}}, socket) do
    %{current_user: current_user, session: session} = socket.assigns

    {:ok, playlist} = Library.create_playlist(current_user, %{title: title})
    {:ok, _changes} = add_tracks_to_playlist(playlist, session.tracks)
    Recorder.delete_session(session)

    socket =
      socket
      |> put_flash(
        :success,
        "Playlist \"#{playlist.title}\" with #{Enum.count(session.tracks)} songs has been created."
      )
      |> push_redirect(to: Routes.library_index_path(socket, :index))

    {:noreply, socket}
  end

  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, uri: URI.parse(uri))}
  end

  def render(assigns) do
    ~L"""
    <div>
      <%= live_patch to: Routes.library_index_path(@socket, :index), class: "link link__back" do %>
        <i class="fas fa-arrow-left"></i>
      <% end %>

      <p class="mt-6">
        Die folgenden Songs wurden aufgenommen. Erstelle nun eine neue Playlist oder füge Sie einer vorhandenen Playlist hinzu.
      </p>

      <div class="mt-4">
        <%= live_component PlaylistComponent, tracks: @session.tracks %>
      </div>

      <div class="card mt-12">
      <h2 class="card__title">In Bibliothek aufnehmen</h2>
        <div class="card__body">
          <div class="md:flex md:justify-between md:space-x-4">
            <div class="md:flex-1">
              <%= f = form_for :playlist, "#", [phx_submit: :assign] %>
                <%= label f, :id, class: "label" do %>
                  Zur Playlist hinzufügen
                <% end %>

                <%= select f, :id, Enum.map(@playlists, &{"#{&1.title} (#{Enum.count(&1.tracks)} songs)", &1.id}), required: true, class: "select w-full" %>

                <div class="flex justify-end">
                  <%= submit "Hinzufügen", phx_disable_with: "Hinzufügen...", class: "btn btn-primary mt-4" %>
                </div>
              </form>
            </div>

            <div class="sm:mt-4 md:mt-0 md:flex-1">
              <%= f = form_for :playlist, "#", [phx_submit: :create_and_assign] %>
                <%= label f, :title, class: "label" do %>
                  oder neue Playlist erstellen
                <% end %>

                <%= text_input f, :title, required: true, class: "select w-full" %>

                <div class="flex justify-end">
                  <%= submit "Erstellen", phx_disable_with: "Erstelle...", class: "mt-4 btn btn-primary" %>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp add_tracks_to_playlist(playlist, tracks) do
    tracks
    |> Enum.map(&Map.from_struct/1)
    |> Enum.map(fn m -> Map.put(m, :playlist_id, playlist.id) end)
    |> Library.create_tracks()
  end
end
