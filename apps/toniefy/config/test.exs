import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir,
  t_cost: 1,
  m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :toniex, Toniex.Repo,
  username: "postgres",
  password: "postgres",
  database: "toniex_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :toniex, ToniexWeb.Endpoint,
  http: [port: 4002],
  server: false

config :toniex, Toniex.Recorder,
  url: "https://toniex.loca.lt",
  docker_image_name: "toniex_test"

config :toniex, Oban, queues: false, plugins: false

# Print only warnings and errors during test
config :logger, level: :warn

config :ueberauth, Ueberauth.Strategy.Spotify.OAuth,
  client_id: "your-spotify-client-id",
  client_secret: "your-spotify-client-secret"
