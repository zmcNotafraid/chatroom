defmodule Chat.PageController do
  use Chat.Web, :controller

  def index(conn, %{"xtoken" => jwt}) do
    if jwt != String.trim("") do
      csrf = SecureRandom.urlsafe_base64
      {:ok, claims} = JsonWebToken.verify(jwt, %{key: "gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr9C"})
      enusername = Base.encode64(claims[:iss])
      Redis.command(~w(SET #{csrf} #{enusername}))
      {:ok, deusername} = Base.decode64(enusername)
      render conn, "index.html", userid: claims[:jti], username: deusername, usersub: claims[:sub], adi: claims[:adi], tag: claims[:tag], csrf: csrf, verified: claims[:verified], reputational: claims[:reputational]
    else
      render conn, "index.html", userid: "", username: "", usersub: "", adi: "", tag: "", csrf: ""
    end
  end

end
