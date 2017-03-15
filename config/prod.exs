use Mix.Config

config :chat, Chat.Endpoint,
  http: [port: System.get_env("PORT") || 4000]
  url: [host: "bcachat.com"]

config :logger, level: :info

import_config "prod.secret.exs"
