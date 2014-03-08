defmodule HTTPoison.Mixfile do
  use Mix.Project

  def project do
    [ app: :httpoison,
      version: "0.0.3",
      elixir: "~> 0.13.1",
      deps: deps(Mix.env) ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps(:prod) do
    [ { :hackney, github: "benoitc/hackney", tag: "0.10.1" } ]
  end

  defp deps(:test) do
    deps(:prod) ++ [ { :httparrot, github: "edgurgel/httparrot", tag: "0.0.4" },
                     { :meck, github: "eproxus/meck", tag: "0.8.1" } ]
  end

  defp deps(_), do: deps(:prod)
end
