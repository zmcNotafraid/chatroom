defmodule Chat.PageController do
  use Chat.Web, :controller
  require Logger

  def index(conn, %{"xtoken" => json_web_token}) do
    if json_web_token != String.trim("") do
      case JsonWebToken.verify(json_web_token, %{key: Application.get_env(:chat, Chat.Endpoint)[:private_key]}) do
        {:ok, verified_token} ->  
          Redis.command(["SET", "#{verified_token[:jti]}:name", "#{verified_token[:iss]}"])
          conn
          |> assign(:username, verified_token[:iss])
          |> assign(:is_admin, verified_token[:adi])
          |> render("index.html",  %{channel_token: Phoenix.Token.sign(conn, "user", json_web_token), is_signin: true})
        {:error, "invalid"} ->
          conn
          |> assign(:username, "")
          |> assign(:is_admin, "")
          |> render("index.html",  %{channel_token: Phoenix.Token.sign(conn, "user", json_web_token), is_signin: false})
      end
    else
      conn
      |> assign(:username, "")
      |> assign(:is_admin, "")
      |> render("index.html",  %{channel_token: Phoenix.Token.sign(conn, "user", json_web_token), is_signin: false})
    end
  end

end
