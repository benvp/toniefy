# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :toniex,
  upload_dir: "",
  ecto_repos: [Toniex.Repo]

config :toniex, ToniexWeb.Gettext, default_locale: "de"

# Configures the endpoint
config :toniex, ToniexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "69x1su421qQtM1XsWNfxuo/kirtb9caSQ5Elm9hzNv4aiH12r3PVFBKaFjEN+Tjv",
  render_errors: [view: ToniexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Toniex.PubSub,
  live_view: [signing_salt: "fhG+jTDQ"]

# Configures Oban job queues
config :toniex, Oban,
  repo: Toniex.Repo,
  # 1 week
  plugins: [{Oban.Plugins.Pruner, max_age: 604_800}],
  queues: [spotify_recorder: 1, tonies_upload: 1]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    spotify:
      {Ueberauth.Strategy.Spotify, [default_scope: "user-read-email,user-read-private,streaming"]},
    tonies: {Ueberauth.Strategy.Tonies, [callback_methods: ["POST"]]}
  ]

config :tesla, adapter: Tesla.Adapter.Hackney

config :toniex, Toniex.Mailer, adapter: Bamboo.LocalAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
