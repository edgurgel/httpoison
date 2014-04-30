defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [ app: :httpoison,
      version: "0.1.1",
      elixir: "~> 0.13.1",
      name: "HTTPoison",
      description: @description,
      package: package,
      deps: deps(Mix.env) ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps(:prod) do
    [ { :hackney, github: "benoitc/hackney", ref: "cf90543f9cc21ffea34d71035521b0102b8555cf" } ]
  end

  defp deps(:test) do
    deps(:prod) ++ [ { :httparrot, github: "edgurgel/httparrot", tag: "0.0.4" },
                     { :meck, github: "eproxus/meck", ref: "69f02255a8219185bf55da303981d86886b3c24b" } ]
  end

  defp deps(_), do: deps(:prod)

  defp package do
    [ contributors: ["Eduardo Gurgel Pinho"],
      licenses: ["WTFPL"],
      links: [ { "Github", "https://github.com/edgurgel/httpoison" } ] ]
  end
end
