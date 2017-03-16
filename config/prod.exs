use Mix.Config

config :chat, Chat.Endpoint,
  http: [port: System.get_env("PORT")],
  url: [host: Application.get_env(:chat, Chat.Endpoint)[:host]]

config :logger, level: :info

import_config "prod.secret.exs"
