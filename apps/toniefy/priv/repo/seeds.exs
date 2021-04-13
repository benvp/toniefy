# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Toniex.Repo.insert!(%Toniex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Toniex.Accounts
alias Toniex.Library

{:ok, user} =
  Accounts.register_user(%{
    email: "test@yourdomain.com",
    password: "test1234"
  })

{:ok, playlist} =
  Library.create_playlist(user, %{
    title: "Sample playlist"
  })

[
  %{
    artist: "Micky Krause",
    title: "Finger weg von Sachen ohne Alkohol",
    duration: "120",
    playlist_id: playlist.id
  },
  %{
    artist: "Geier Sturzflug",
    title: "Bruttosozialprodukt",
    duration: "180",
    playlist_id: playlist.id
  },
  %{artist: "Die doofen", title: "Mief", duration: "145", playlist_id: playlist.id}
]
|> Enum.each(&Library.create_track(&1))
