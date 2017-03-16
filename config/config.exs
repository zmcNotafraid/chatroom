use Mix.Config

config :chat, Chat.Endpoint,
  url: [host: Application.get_env(:chat, Chat.Endpoint)[:host]],
  root: Path.expand("..", __DIR__),
  debug_errors: false,
  pubsub: [name: Chat.PubSub, adapter: Phoenix.PubSub.PG2],
  check_origin: false

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
