defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [
      app: :httpoison,
      version: "1.3.1",
      elixir: "~> 1.5",
      name: "HTTPoison",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/edgurgel/httpoison",
      docs: [
        main: "readme",
        logo: "logo.png",
        extras: [
          "README.md",
          "CHANGELOG.md"
        ]
      ]
    ]
  end

  def application do
    [applications: [:hackney]]
  end

  defp deps do
    [
      {:hackney, "~> 1.8"},
      {:mimic, "~> 0.1", only: :test},
      {:exjsx, "~> 3.1", only: :test},
      {:httparrot, "~> 1.0", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://github.com/edgurgel/httpoison/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/edgurgel/httpoison"
      }
    ]
  end
end
