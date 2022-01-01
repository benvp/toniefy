defmodule ToniexRecorder.MixProject do
  use Mix.Project

  def project do
    [
      app: :toniex_recorder,
      version: "1.0.4",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2.2"},
      {:porcelain, "~> 2.0.3"},
      {:hackney, "~> 1.17.0"},
      {:tesla, "~> 1.4.0", override: true},
      {:wallaby, "~> 0.29.1", runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
