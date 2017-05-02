defmodule Chat.UserSocket do
  use Phoenix.Socket
  require Logger

  channel "rooms:*", Chat.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket
  transport :longpoll, Phoenix.Transports.LongPoll

  def connect(params, socket) do
    case Phoenix.Token.verify(socket, "user", params["token"], max_age: 1209600) do
      {:ok, json_web_token} ->
        if String.length(json_web_token) == 0 do
          {:ok, socket}
        else
          case JsonWebToken.verify(json_web_token, %{key: Application.get_env(:chat, Chat.Endpoint)[:private_key]}) do
            {:ok, verified_token} ->
              {:ok, 
                assign(socket, :user_number, verified_token[:jti]) |>
                assign(:username, verified_token[:iss]) |>
                assign(:is_admin, verified_token[:adi])
              }
            {:error, "invalid"} ->
              {:ok, socket}
          end
        end
      {:error, reason} ->
        reason
    end
  end

  def id(_socket), do: nil
end
