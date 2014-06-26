defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [ app: :httpoison,
      version: "0.3.1",
      elixir: "~> 0.14.1",
      name: "HTTPoison",
      description: @description,
      package: package,
      deps: deps ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [ { :hackney, github: "benoitc/hackney", ref: "cf90543f9cc21ffea34d71035521b0102b8555cf" },
      { :httparrot, github: "edgurgel/httparrot", tag: "0.3.0", only: :test },
      { :meck, github: "eproxus/meck", tag: "0.8.2", only: :test } ]
  end

  defp package do
    [ contributors: ["Eduardo Gurgel Pinho"],
      licenses: ["WTFPL"],
      links: [ { "Github", "https://github.com/edgurgel/httpoison" } ] ]
  end
end
