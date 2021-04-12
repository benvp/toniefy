defmodule Toniex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Toniex.Repo,
      # Start the Telemetry supervisor
      ToniexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Toniex.PubSub},
      # Start the Endpoint (http/https)
      ToniexWeb.Endpoint,
      # Start a worker by calling: Toniex.Worker.start_link(arg)
      # {Toniex.Worker, arg},
      # Start Oban
      {Oban, oban_config()},
      Toniex.JobStatus
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Toniex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ToniexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.get_env(:toniex, Oban)
  end
end
