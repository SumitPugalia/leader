defmodule Leader.MixProject do
  use Mix.Project

  def project do
    [
      app: :leader,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :postgrex, :ecto],
      mod: {Leader.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, "~> 0.14.1"},
      {:ecto_sql, "~> 3.0"},
      {:ecto, "~> 3.0"},
      {:distillery, "~> 2.0", runtime: false}
    ]
  end
end
