defmodule Chat.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "1.3.0",
     elixir: "~> 1.2",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     deps: deps()]
  end

  def application do
    [mod: {Chat, []},
     applications: [:phoenix, :phoenix_html, :phoenix_pubsub, :cowboy, :logger,
                   :redix, :phoenix_ecto, :gettext, :secure_random,
                   :json_web_token, :edeliver]]
  end

  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_ecto, "~> 3.0"},
     {:phoenix_html, "~> 2.6.2"},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:redix, "~> 0.6.0"},
     {:secure_random, "~> 0.5"},
     {:json_web_token, "~> 0.2.6"},
     {:edeliver, "~> 1.4.2"},
     {:distillery, "~> 1.0", warn_missing: false}]
  end


end
