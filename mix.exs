defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description "Yet Another HTTP client for Elixir powered by hackney"
  @source_url "https://github.com/edgurgel/httpoison"

  def project do
    [
      app: :httpoison,
      version: "2.3.0",
      elixir: "~> 1.11",
      name: "HTTPoison",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: @source_url,
      docs: [
        main: "readme",
        logo: "logo.png",
        extras: [
          "README.md",
          "CHANGELOG.md"
        ]
      ],
      dialyzer: [
        plt_add_deps: :transitive,
        flags: [
          :unmatched_returns,
          :underspecs
          # :overspecs,
          # :specdiffs
        ]
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:hackney, "~> 1.21"},
      {:mimic, "~> 1.0", only: :test},
      {:jason, "~> 1.2", only: :test},
      {:httparrot, "~> 1.2", only: :test},
      {:cowboy, "~> 2.8", only: :test, override: true},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Eduardo Gurgel Pinho"],
      licenses: ["MIT"],
      links: %{
        Changelog: @source_url <> "/blob/master/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end
end
