defmodule ToniexWeb.UserSettingsController do
  use ToniexWeb, :controller

  alias Toniex.Accounts
  alias ToniexWeb.UserAuth

  plug :assign_email_and_password_changesets
  plug :assign_connected_services

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "Eine E-Mail mit einem Bestätigungslink wurde an dich versendet."
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password erfolgreich geändert.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Deine E-Mail Adresse wurde erfolgreich aktualisiert.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Dein Bestätigungslink ist abgelaufen oder ungültig.")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def disconnect_service(conn, %{"provider" => provider}) do
    conn.assigns.current_user
    |> Accounts.get_credential_by_provider(provider)
    |> Accounts.delete_credential()

    redirect(conn, to: Routes.user_settings_path(conn, :edit))
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end

  defp assign_connected_services(conn, _opts) do
    connected_services =
      if credential = Accounts.get_credential_by_provider(conn.assigns.current_user, :spotify),
        do: [%{provider: :spotify, username: credential.username}],
        else: []

    connected_services =
      if credential = Accounts.get_credential_by_provider(conn.assigns.current_user, :tonies),
        do: connected_services ++ [%{provider: :tonies, username: credential.username}],
        else: connected_services

    conn
    |> assign(:connected_services, connected_services)
  end
end
