defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [ app: :httpoison,
      version: "0.4.3",
      elixir: "~> 0.15.0 or ~> 1.0",
      name: "HTTPoison",
      description: @description,
      package: package,
      deps: deps ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [ { :hackney, "~> 0.14.1" },
      { :httparrot, "~> 0.3.2", only: :test },
      { :meck, "~> 0.8.2", only: :test } ]
  end

  defp package do
    [ contributors: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edgurgel/httpoison"} ]
  end
end
