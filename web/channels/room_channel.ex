defmodule Chat.RoomChannel do
  use Phoenix.Channel
  use Chat.Web, :channel
  require Logger

  def join("rooms:lobby", message, socket) do
    Process.flag(:trap_exit, true)
    send(self(), {:after_join, message})
    {:ok, socket}
  end

  def join("rooms:" <> _private_subtopic, _message, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

  def handle_info({:after_join, _msg}, socket) do
    {:ok, history} = Redis.command(~w(ZRANGE zset -100 -1))
    push socket, "history:msgs", %{ history: history }
    push socket, "join", %{status: "connected"}
    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    [name, sub, adi, body, csrf] = [msg["user"], msg["sub"], msg["adi"], msg["body"], msg["csrf"]]
    {:ok, role} = Redis.command(~w(get #{sub}:role))
    if role == nil do
      role = ""
    end
    {:ok, redis_user_name} = Redis.command(~w(GET #{csrf}))
    if adi == "true" && (String.contains? body, "X:" || "K:" || "G:" || "V:") do
      [_cmd, blocksub, min] = String.split(body, ":")
      cond do
        String.contains? body, "X" ->
          Redis.command(~w(SET #{blocksub} #{1}))
          Redis.command(~w(EXPIRE #{blocksub} #{String.to_integer(min)*60}))
          if String.to_integer(min) == 0 do
            broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, role: role, body: "用户***##{blocksub} 已被 #{name} 解禁"}
          else
            broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, role: role, body: "用户***##{blocksub} 被 #{name} 禁言 #{min} 分钟"}
          end
        String.contains? body, "K" ->
          Redis.command(~w(SET #{blocksub}:role normal_believer))
          Redis.command(~w(EXPIRE #{blocksub}:role #{String.to_integer(min)*60}))
          broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, role: role, body: "用户***##{blocksub} 被 #{name} 设为普通可信用户"}
        String.contains? body, "G" ->
          Redis.command(~w(SET #{blocksub}:role advanced_believer))
          Redis.command(~w(EXPIRE #{blocksub}:role #{String.to_integer(min)*60}))
          broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, role: role, body: "用户***##{blocksub} 被 #{name} 设为高级可信用户"}
        String.contains? body, "V" ->
          Redis.command(~w(SET #{blocksub}:role true_name))
          Redis.command(~w(EXPIRE #{blocksub}:role #{String.to_integer(min)*60}))
          broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, role: role, body: "用户***##{blocksub} 被 #{name} 设为实名验证用户"}
      end
    else
      {:ok, blocktime} = Redis.command(~w(TTL #{sub}))
      {:ok, deusername} = Base.decode64(redis_user_name)
      if deusername == name and blocktime < 0 do
        if name == "Member" || name == "用户" do
          push socket, "new:msg", %{user: name, sub: sub, adi: adi, body: "请修改昵称后再发言", role: role}
          {:error, %{reason: "init nickname"}}
        else
          if is_tag() do
            broadcast! socket, "new:msg", %{user: "SYSTEM",sub: "", adi: "", body: timestamp(), role: role}
            value = "#{timestamp()}~SYSTEM~sub~adi~#{timestamp()}~#{role}"
            Redis.command(~w(ZADD zset #{timestamp()} #{Base.encode64(value)}))
          end
          broadcast! socket, "new:msg", %{user: name, sub: sub, adi: adi, body: body, role: role}
          value = "#{timestamp()}~#{name}~#{sub}~#{adi}~#{body}~#{role}"
          Redis.command(~w(ZADD zset #{timestamp()} #{Base.encode64(value)}))
        end
      else
        Logger.debug "-- cache #{deusername} block #{name}##{sub} #{blocktime} sec"
        push socket, "new:msg", %{user: name, sub: sub, adi: adi, body: "您在#{blocktime}秒后才可以发言", role: role}
        {:error, %{reason: "unauthorized"}}
      end
    end
    {:reply, {:ok, %{msg: body}}, assign(socket, :user, name)}
  end

  #show timestamp
  def is_tag do
    case Redis.command(~w(ZRANGE zset -2 -1)) do
      {:ok, []} -> false
      {:ok, [_last]} -> false
      {:ok, [first, last]} ->
        {:ok, defirst} = Base.decode64(first)
        {:ok, delast} = Base.decode64(last)
        ftime = String.split(defirst, "~")
        ltime = String.split(delast, "~")
        [first_time] = Enum.take(ftime, 1)
        [last_time] = Enum.take(ltime, 1)
        String.to_integer(last_time) - String.to_integer(first_time) > 120
    end
  end

  def datetime do
    {:ok, dt} = DateTime.from_unix(timestamp())
    DateTime.to_iso8601(dt)
  end

  def timestamp do
    :os.system_time(:seconds)
  end

end
