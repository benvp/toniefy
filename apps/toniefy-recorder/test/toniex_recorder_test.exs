defmodule ToniexRecorderTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query

  test "records something" do
    System.cmd("pactl", ["load-module", "module-null-sink", "sink_name=toniex"])
    System.cmd("pactl", ["set-default-sink", "toniex"])

    record_proc =
      Porcelain.spawn_shell(
        "./bin/run.sh parec -d toniex.monitor --format=s16le | lame -r --quiet --preset extreme - \"test_recording.mp3\""
      )

    # TODO: refactor into a proper module (see docs why this shouldn't be used)
    Process.sleep(1_000)

    assert File.exists?(Path.expand("test_recording.mp3"))

    File.rm!(Path.expand("test_recording.wav"))
  end

  feature "plays a track", %{session: session} do
    host = Application.get_env(:toniex_recorder, :toniex_host)
    token = Application.get_env(:toniex_recorder, :record_token)
    url = URI.merge(URI.parse(host), "/record?t=#{token}") |> to_string()

    session
    |> visit(url)
    |> find(Query.css("#player-info", visible: false))
  end
end
