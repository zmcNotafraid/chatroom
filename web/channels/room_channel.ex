defmodule Chat.RoomChannel do
  use Phoenix.Channel
  use Chat.Web, :channel
  require Logger

  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_info(:after_join, socket) do
    {:ok, history} = Redis.command(~w(ZRANGE history -30 -1))
    push socket, "history:msgs", %{ history: history }
    push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end

  defp set_role(role, user_number) do
    Redis.command(~w(SET #{user_number}:role #{role}))
  end

  def handle_in("update:top:notice", msg, socket) do
    Redis.command(["SET","chatroom:top:notice","#{msg["notice"]}"])
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "update_top_notice"}
    {:noreply, socket}
  end

  def handle_in("reset:role", msg, socket) do
    Redis.command(~w(DEL #{msg["userNumber"]}:role ))
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "reset_role"}
    {:noreply, socket}
  end

  def handle_in("auth:beginner", msg, socket) do
    set_role("beginner", msg["userNumber"])
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "auth_beginner"}
    {:noreply, socket}
  end

  def handle_in("auth:helpful_user", msg, socket) do
    set_role("helpful_user", msg["userNumber"])
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "auth_helpful_user"}
    {:noreply, socket}
  end

  def handle_in("auth:advanced_user", msg, socket) do
    set_role("advanced_user", msg["userNumber"])
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "auth_advanced_user" }
    {:noreply, socket}
  end

  def handle_in("auth:certified_guest", msg, socket) do
    set_role("certified_guest", msg["userNumber"])
    push socket, "new:msg", %{name: socket.assigns[:username],is_admin: socket.assigns[:is_admin], action: "auth_certified_guest" }
    {:noreply, socket}
  end

  def handle_in("ban", msg, socket) do
    {:ok, ban_name} = Redis.command(~w(GET #{msg["userNumber"]}:name))
    Redis.command(~w(SET #{msg["userNumber"]}:ban #{msg["reason"]} ))
    Redis.command(~w(EXPIRE #{msg["userNumber"]}:ban #{String.to_integer(msg["minutes"])*60}))
    broadcast! socket, "new:msg", %{name: socket.assigns[:username], is_admin: socket.assigns[:is_admin], action: "ban", ban_name: ban_name }
    {:noreply, socket}
  end

  def handle_in("remove:ban", msg, socket) do
    {:ok, ban_name} = Redis.command(~w(GET #{msg["userNumber"]}:name))
    Redis.command(~w(EXPIRE #{msg["userNumber"]}:ban 0))
    push socket, "new:msg", %{name: socket.assigns[:username], is_admin: socket.assigns[:is_admin], action: "remove_ban", ban_name: ban_name }
    {:noreply, socket}
  end

  def handle_in("view:ban_reason", msg, socket) do
    {:ok, reason} = Redis.command(~w(GET #{msg["userNumber"]}:ban ))
    broadcast! socket, "new:msg", %{name: socket.assigns[:username], is_admin: socket.assigns[:is_admin], body: reason}
    {:noreply, socket}
  end

  def handle_in("update:name", msg, socket) do
    push socket, "new:msg", %{name: "管理员",is_admin: "true", action: "update_name"}
    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    {:ok, role} = Redis.command(~w(get #{socket.assigns[:user_number]}:role))
    {:ok, ban_time} = Redis.command(~w(TTL #{socket.assigns[:user_number]}:ban ))
    if ban_time < 0 do
      if is_tag() do
        value = "{'name':'SYSTEM','timestamp':#{timestamp()-1}}"
        Redis.command(~w(ZADD history #{timestamp()-1} #{Base.encode64(value)}))
        broadcast! socket, "new:msg", %{name: "SYSTEM",timestamp: timestamp()-1}
      end
      value = "{'name':'#{socket.assigns[:username]}','number':'#{socket.assigns[:user_number]}','role':'#{role}','is_admin':#{socket.assigns[:is_admin]},'body':'#{msg["body"]}','timestamp':#{timestamp()}}"
      Redis.command(~w(ZADD history #{timestamp()} #{Base.encode64(value)}))
      broadcast! socket, "new:msg", %{name: socket.assigns[:username], number: socket.assigns[:user_number], is_admin: socket.assigns[:is_admin], body: msg["body"], role: role, timestamp: timestamp()}
      {:reply, :ok, socket}   
    else
      push socket, "new:msg", %{name: "管理员", is_admin: "true", body: "您在#{Float.round(ban_time/3600, 1)}小时后才可以发言"}
      {:stop, %{reason: "have been ban"}, :ok, socket}
    end
  end

  #show timestamp
  def is_tag do
    case Redis.command(~w(ZRANGE history -2 -1 WITHSCORES)) do
      {:ok, []} -> false
      {:ok, [_last_score, _last_member]} -> false
      {:ok, [_last_but_one_member, last_but_one_score, _last_member, last_score]} ->
        String.to_integer(last_score) - String.to_integer(last_but_one_score) > 120   
    end
  end

  def timestamp do
    :os.system_time(:seconds)
  end

end
