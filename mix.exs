defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [ app: :httpoison,
      version: "0.8.2",
      elixir: "~> 1.0",
      name: "HTTPoison",
      description: @description,
      package: package,
      deps: deps,
      source_url: "https://github.com/edgurgel/httpoison" ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [
      {:hackney, "~> 1.5.2"},
      {:exjsx, "~> 3.1", only: :test},
      {:httparrot, "~> 0.3.4", only: :test},
      {:meck, "~> 0.8.2", only: :test},
      {:earmark, "~> 0.1.17", only: :docs},
      {:ex_doc, "~> 0.8.0", only: :docs},
    ]
  end

  defp package do
    [ maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edgurgel/httpoison"} ]
  end
end
