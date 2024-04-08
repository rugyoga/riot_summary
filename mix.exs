defmodule RiotSummary.MixProject do
  use Mix.Project

  def project do
    [
      app: :riot_summary,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RiotApp, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7.5", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev], runtime: false},
      {:hammer, "~> 6.1"},
      {:req, "~> 0.3.0"}
    ]
  end
end
