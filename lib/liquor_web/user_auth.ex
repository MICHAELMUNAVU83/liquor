defmodule LiquorWeb.UserAuth do
  @moduledoc """
  Session-based authentication helpers for admin routes.
  Works as both a Plug (controller pipelines) and a LiveView on_mount hook.
  """
  import Plug.Conn
  import Phoenix.Controller

  use Phoenix.VerifiedRoutes,
    endpoint: LiquorWeb.Endpoint,
    router: LiquorWeb.Router,
    statics: LiquorWeb.static_paths()

  alias Liquor.Accounts

  # ---------------------------------------------------------------------------
  # Plug callbacks (used in router pipelines)
  # ---------------------------------------------------------------------------

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :admin_user_id)
    user    = user_id && Accounts.get_user(user_id)
    assign(conn, :current_user, user)
  end

  def require_admin_user(conn, _opts) do
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        conn
        |> put_flash(:error, "Please sign in to access the admin panel.")
        |> redirect(to: ~p"/admin/login")
        |> halt()

      not user.is_admin ->
        conn
        |> put_flash(:error, "You don't have admin access.")
        |> redirect(to: ~p"/admin/login")
        |> halt()

      true ->
        conn
    end
  end

  # ---------------------------------------------------------------------------
  # Session management
  # ---------------------------------------------------------------------------

  def log_in_admin(conn, user) do
    conn
    |> renew_session()
    |> put_session(:admin_user_id, user.id)
    |> redirect(to: ~p"/admin")
  end

  def log_out_admin(conn) do
    conn
    |> renew_session()
    |> redirect(to: ~p"/")
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  # ---------------------------------------------------------------------------
  # LiveView on_mount hooks
  # ---------------------------------------------------------------------------

  def on_mount(:require_admin, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user && socket.assigns.current_user.is_admin do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "Please sign in to access the admin panel.")

      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/admin/login")}
    end
  end

  def on_mount(:fetch_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["admin_user_id"] do
        Accounts.get_user(user_id)
      end
    end)
  end
end
