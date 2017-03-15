use Mix.Config

config :chat, Chat.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "bcachat.com"]

config :logger, level: :info

import_config "prod.secret.exs"
