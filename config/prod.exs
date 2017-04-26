use Mix.Config

config :chat, Chat.Endpoint,
  http: [port: 4001],
  root: ".",
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  version: Mix.Project.config[:version]

config :logger, level: :info

import_config "prod.secret.exs"
