defmodule ToniexWeb.UserSessionController do
  use ToniexWeb, :controller

  plug Ueberauth

  alias Toniex.Accounts
  alias ToniexWeb.UserAuth
  alias Ueberauth.Strategy.Helpers

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, "new.html",
        error_message: "Der eingebene Benutzername oder das Passwort ist ungültig."
      )
    end
  end

  @spec delete(Plug.Conn.t(), any) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Erfolgreich abgemeldet. Bis bald!")
    |> UserAuth.log_out_user()
  end

  def request(conn, %{"provider" => "tonies"}) do
    conn
    |> render("tonies.html", callback_url: Helpers.callback_url(conn), error_message: nil)
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :tonies} = auth}} = conn, _params) do
    case Accounts.get_or_create_credential_from_auth(conn.assigns.current_user, auth) do
      {:ok, _credential} ->
        conn
        |> put_flash(:info, "Account erfolgreich verbunden.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, _changeset} ->
        render(conn, "tonies.html",
          callback_url: Helpers.callback_url(conn),
          error_message: "Es ist ein Fehler aufgetreten. Bitte versuche es erneut."
        )
    end
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :spotify} = auth}} = conn, _params) do
    case Accounts.get_or_create_credential_from_auth(conn.assigns.current_user, auth) do
      {:ok, _credential} ->
        conn
        |> put_flash(:info, "Account erfolgreich verbunden.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Es ist ein Fehler aufgetreten. Bitte versuche es erneut.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def callback(%{assigns: %{ueberauth_failure: %{provider: :tonies}}} = conn, _params) do
    render(conn, "tonies.html",
      callback_url: Helpers.callback_url(conn),
      error_message: "Der eingebene Benutzername oder das Passwort ist ungültig."
    )
  end

  def callback(%{assigns: %{ueberauth_failure: _fail}} = conn, _params) do
    conn
    |> put_flash(:error, "Unable to connect account.")
    |> redirect(to: "/")
  end
end
