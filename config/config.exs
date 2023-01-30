import Config

if config_env() == :test do
  config :httparrot,
    https_port: 8433,
    http_port: 4002,
    ssl: true
end
