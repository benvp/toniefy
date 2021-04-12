defmodule Toniex.LibraryTest do
  use Toniex.DataCase

  alias Toniex.Library

  describe "playlists" do
    alias Toniex.Library.Playlist

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def playlist_fixture(attrs \\ %{}) do
      {:ok, playlist} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Library.create_playlist()

      playlist
    end

    test "list_playlists/0 returns all playlists" do
      playlist = playlist_fixture()
      assert Library.list_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given id" do
      playlist = playlist_fixture()
      assert Library.get_playlist!(playlist.id) == playlist
    end

    test "create_playlist/1 with valid data creates a playlist" do
      assert {:ok, %Playlist{} = playlist} = Library.create_playlist(@valid_attrs)
      assert playlist.title == "some title"
    end

    test "create_playlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_playlist(@invalid_attrs)
    end

    test "update_playlist/2 with valid data updates the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{} = playlist} = Library.update_playlist(playlist, @update_attrs)
      assert playlist.title == "some updated title"
    end

    test "update_playlist/2 with invalid data returns error changeset" do
      playlist = playlist_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_playlist(playlist, @invalid_attrs)
      assert playlist == Library.get_playlist!(playlist.id)
    end

    test "delete_playlist/1 deletes the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{}} = Library.delete_playlist(playlist)
      assert_raise Ecto.NoResultsError, fn -> Library.get_playlist!(playlist.id) end
    end

    test "change_playlist/1 returns a playlist changeset" do
      playlist = playlist_fixture()
      assert %Ecto.Changeset{} = Library.change_playlist(playlist)
    end
  end
end
