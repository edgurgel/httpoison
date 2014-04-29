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
    [ { :hackney, github: "benoitc/hackney", ref: "cf90543f9cc21ffea34d71035521b0102b8555cf" } ]
  end

  defp deps(:test) do
    deps(:prod) ++ [ { :httparrot, github: "edgurgel/httparrot", tag: "0.0.4" },
                     { :meck, github: "eproxus/meck", ref: "69f02255a8219185bf55da303981d86886b3c24b" } ]
  end

  defp deps(_), do: deps(:prod)
end
