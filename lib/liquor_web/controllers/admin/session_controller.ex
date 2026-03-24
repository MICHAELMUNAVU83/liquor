defmodule LiquorWeb.Admin.SessionController do
  use LiquorWeb, :controller

  alias Liquor.Accounts
  alias LiquorWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil, layout: false)
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, %{role: role} = user} when not is_nil(role) ->
        conn
        |> put_flash(:info, "Welcome back, #{user.first_name}!")
        |> UserAuth.log_in_admin(user)

      {:ok, _user} ->
        render(conn, :new,
          error_message: "Your account does not have admin access.",
          layout: false
        )

      {:error, _} ->
        render(conn, :new,
          error_message: "Invalid email or password. Please try again.",
          layout: false
        )
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been signed out.")
    |> UserAuth.log_out_admin()
  end
end
