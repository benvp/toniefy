defmodule ToniexWeb.UserRegistrationController do
  use ToniexWeb, :controller

  alias Toniex.Accounts
  alias Toniex.Accounts.User
  alias Toniex.Waitlist
  alias ToniexWeb.UserAuth

  def new(conn, params) do
    changeset = Accounts.change_user_registration(%User{})

    render(conn, "new.html",
      changeset: changeset,
      invite_code: params["code"]
    )
  end

  def create(conn, %{"user" => user_params}) do
    with %Waitlist.Entry{} <-
           Waitlist.validate_invite_code(user_params["email"], user_params["invite_code"]),
         {:ok, user} <- Accounts.register_user(user_params) do
      {:ok, _} =
        Accounts.deliver_user_confirmation_instructions(
          user,
          &Routes.user_confirmation_url(conn, :confirm, &1)
        )

      conn
      |> put_flash(:info, "Registrierung erfolgreich. Viel Spaß mit toniefy!")
      |> UserAuth.log_in_user(user)
    else
      nil ->
        conn
        |> put_flash(:error, "Leider ist die E-Mail Adresse oder der Einladungscode ungültig.")
        |> render("new.html",
          changeset: Accounts.change_user_registration(%User{}),
          invite_code: user_params["invite_code"]
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, invite_code: conn.assigns[:invite_code])
    end
  end
end
