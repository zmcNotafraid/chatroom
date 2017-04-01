defmodule Chat.PageController do
  use Chat.Web, :controller
  require Logger

  def index(conn, %{"xtoken" => jwt}) do
    if jwt != String.trim("") do
      csrf = SecureRandom.urlsafe_base64
      {:ok, claims} = JsonWebToken.verify(jwt, %{key: Application.get_env(:chat, Chat.Endpoint)[:private_key]})
      enusername = Base.encode64(claims[:iss])
      Redis.command(~w(SET #{csrf} #{enusername}))
      render conn, "index.html", userid: claims[:jti], username: claims[:iss], usersub: claims[:sub], adi: claims[:adi], csrf: csrf
    else
      render conn, "index.html", userid: "", username: "", usersub: "", adi: "", csrf: ""
    end
  end

end
