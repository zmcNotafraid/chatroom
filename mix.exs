defmodule Chat.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: ["lib", "web"],
     compilers: [:phoenix] ++ Mix.compilers,
     deps: deps()]
  end

  def application do
    [mod: {Chat, []},
     applications: [:phoenix, :phoenix_html, :phoenix_pubsub, :cowboy, :logger,
                   :redix, :ecto, :gettext, :secure_random,
                   :json_web_token]]
  end

  defp deps do
    [{:phoenix, "~> 1.2"},
     {:ecto, "~> 2.0.4"},
     {:phoenix_html, "~> 2.6.2"},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:redix, "~> 0.4.0"},
     {:secure_random, "~> 0.5"},
     {:json_web_token, "~> 0.2.6"},
     {:distillery, "~> 1.0"}]
  end


end
