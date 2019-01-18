defmodule HTTPoison.Mixfile do
  use Mix.Project

  @description """
    Yet Another HTTP client for Elixir powered by hackney
  """

  def project do
    [
      app: :httpoison,
      version: "1.5.0",
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
      ],
      dialyzer: [
        plt_add_deps: :apps_direct,
        flags: [
          :error_handling,
          # :overspecs,
          :race_conditions,
          # :specdiffs,
          # :underspecs,
          :unmatched_returns
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
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false}
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
