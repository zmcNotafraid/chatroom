defmodule Chat.PageController do
  use Chat.Web, :controller
  require Logger

  def index(conn, %{"xtoken" => jwt}) do
    if jwt != String.trim("") do
      csrf = SecureRandom.urlsafe_base64
      {:ok, claims} = JsonWebToken.verify(jwt, %{key: Application.get_env(:chat, Chat.Endpoint)[:private_key]})
      enusername = Base.encode64(claims[:iss])
      Redis.command(~w(SET #{csrf} #{enusername}))
      {:ok, role} = Redis.command(~w(GET #{claims[:sub]}:role))
      if role == nil || (Redis.command(~w(TTL #{claims[:sub]}:role)) < 1) do
        role = ""
      end
      Logger.info(role)
      {:ok, deusername} = Base.decode64(enusername)
      render conn, "index.html", userid: claims[:jti], username: deusername, usersub: claims[:sub], adi: claims[:adi], tag: claims[:tag], csrf: csrf, role: role
    else
      render conn, "index.html", userid: "", username: "", usersub: "", adi: "", tag: "", csrf: "", role: ""
    end
  end

end
