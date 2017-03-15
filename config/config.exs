use Mix.Config

config :chat, Chat.Endpoint,
  url: [host: "bcachat.com"],
  root: Path.expand("..", __DIR__),
  secret_key_base: "xxx",
  debug_errors: false,
  pubsub: [name: Chat.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
