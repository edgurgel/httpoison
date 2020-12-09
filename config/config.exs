use Mix.Config

if Mix.env() == :test do
  config :httparrot,
    http_port: 8080,
    ssl: true,
    https_port: 8433
end
