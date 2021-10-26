# toniefy - Spotify® on your toniebox

This is the main repository for toniefy - a simple and seamless
way to transfer songs from your Spotify premium account to your [toniebox](https://tonies.com).

Please keep in mind that depending on your region this might violate the Terms of Spotify® and/or of tonies®.
I'm whether related to either Spotify® or tonies® and just a fan who thought sharing a way to transfer some songs
could help some people.

Consider it as open-source but don't expect the quality of a well-managed open source project.
I just don't see any point of hiding the source code as it's a somewhat fancy, creative architecture
which you won't see a lot. Consider it a tech demo 😊.

## Architecture

### 1. Web App

This is a mostly standard web app using Elixir, the Phoenix Framework, Ecto and LiveView.
Job handling is done via the awesome [Oban](https://github.com/sorentwo/oban) library.

### 2. Recorder

This is the task where the somewhat fancy architecture comes in. It consists of

* a docker image (which is far from optimised in size - but hey, this doesn't matter here).
* a custom mix task.

The docker image is an Ubuntu based image with a virtual framebuffer `xfvb` and a `pulseaudio` server.
This way we are able to run a headful chrome (headless does not work in our case), pipe
the sound output into a null-sink and record it from there via `parec`. The output is then directly
encoded to mp3 via the `lame` encoder.

After the recording - or if something unexpected happened - we just kill and delete the container.

The mix task uses [Wallaby](https://github.com/elixir-wallaby/wallaby) for browser automation.
As soon a it's started it opens up a page from our web app `/record` with a short lived token.
Upon load the Spotify Web playback SDK takes over and starts the playback of the URI encoded inside of the
token. Player state updates are propagated in the DOM (via data attributes) and picked up
by a GenServer which periodically checks for changes in the data attributes.

This way we can easily send messages whenever playback finished, tracks change or the user
interrupts the playback unexpectedly (which could be the case if the user changes the playback
device so something else or hits stop in the spotify client).

Status updates are being pushed via a simple `PUT /record/status` call. These are then propagated
via LiveView to the UI. This enables live updates over the current recording state.

Whenever a track changes, a split mark is being added to be able to split the recorded mp3 file
into separate songs so that they can be controlled via next/prev options on the toniebox later on.

If everything went well, the songs will be uploaded and from there on handled by the web app.

## Running on you machine

### Prerequisites

1. Docker
2. Erlang / Elixir
3. A registered Spotify app.

Fetch the dependencies:

```bash
mix deps.get
```

Setup the db

```bash
mix ecto.setup
```

Build the docker file

```bash
cd toniefy-recorder
mix deps.get
mix compile
docker build -t toniex-recorder:1.0.2 .
```

### Configuration

In `config/dev.exs` configure the URL where your system is hosted.

```elixir
config :toniex, Toniex.Recorder,
  url: "https://f5f6db8b4967.eu.ngrok.io", # the public url of the phoenix server
  docker_image_name: "toniex-recorder:1.0.2" # the docker image name you built

config :ueberauth, Ueberauth.Strategy.Spotify.OAuth,
  client_id: "your-spotify-client-id",
  client_secret: "your-spotify-client-secret"
```

**You need a HTTPS connection, otherwise Spotify Web SDK does not work.**

### Running

```bash
iex -S mix phx.server
```

## Contributing

I'm happy if you like to contribute. Just open up a PR or an issue and let's discuss your ideas.

## LICENSE

See [LICENSE](https://github.com/benvp/toniefy/blob/main/LICENSE)
