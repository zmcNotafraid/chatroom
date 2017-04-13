defmodule Chat.PageView do
  use Chat.Web, :view

  def top_notice do
    {:ok, content} = Redis.command(~w(GET chatroom:top:notice))
    content
  end
end
