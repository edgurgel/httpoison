defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [ app: :httpoison,
      version: "0.11.2",
      elixir: "~> 1.2",
      name: "HTTPoison",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/edgurgel/httpoison" ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [
      {:hackney, "~> 1.8.0"},
      {:exjsx, "~> 3.1", only: :test},
      {:httparrot, "~> 0.5", only: :test},
      {:meck, "~> 0.8.2", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14.3", only: :dev},
    ]
  end

  defp package do
    [ maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edgurgel/httpoison"} ]
  end
end
