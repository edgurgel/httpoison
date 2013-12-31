defmodule HTTPoison.Mixfile do
  use Mix.Project

  def project do
    [ app: :httpoison,
      version: "0.0.1",
      elixir: "~> 0.12.0",
      deps: deps ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [ {:hackney, tag: "0.10.0", github: "benoitc/hackney"} ]
  end
end
