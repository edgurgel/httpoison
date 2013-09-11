defmodule HTTPoison.Mixfile do
  use Mix.Project

  def project do
    [ app: :httpoison,
      version: "0.0.1",
      elixir: "~> 0.10.2",
      deps: deps ]
  end

  def application do
    [applications: [:ssl, :hackney]]
  end

  defp deps do
    [ {:hackney, tag: "0.4.4", github: "benoitc/hackney"} ]
  end
end
