defmodule Toniex.Repo do
  use Ecto.Repo,
    otp_app: :toniex,
    adapter: Ecto.Adapters.Postgres
end
