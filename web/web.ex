defmodule Chat.Web do

  def view do
    quote do
      use Phoenix.View, root: "web/templates"
      import Chat.Router.Helpers
      use Phoenix.HTML
      alias Chat.RedixPool, as: Redis
      import Chat.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller
      import Chat.Router.Helpers
      alias Chat.RedixPool, as: Redis
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      alias Chat.Repo
      alias Chat.RedixPool, as: Redis
      import Chat.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
