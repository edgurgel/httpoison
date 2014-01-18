defmodule HTTPoison.Mixfile do
  use Mix.Project

  def project do
    [ app: :httpoison,
      version: "0.0.2",
      elixir: "~> 0.12.2",
      deps: deps ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [ { :hackney, github: "benoitc/hackney", tag: "0.10.1" } ]
  end
end
