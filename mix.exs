defmodule Alembic.Mixfile do
  use Mix.Project

  def project do
    [app: :alembic,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [],
     mod: {Alembic, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    []
  end

  #defp package do
  #  [files: ~w(lib mix.exs README.md LICENSE UNLICENSE VERSION),
  #   contributors: ["Steven Rutkowski"],m
  #   licenses: ["Unlicense"],
  #   links: %{"GitHub" => "https://github.com/sr-ix/alembic"}]
  #end
end
