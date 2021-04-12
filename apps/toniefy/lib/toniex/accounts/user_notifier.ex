defmodule Toniex.Accounts.UserNotifier do
  import Bamboo.Email

  alias Toniex.Mailer

  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  defp deliver(to, subject, body) do
    new_email()
    |> from("noreply@toniefy.me")
    |> to(to)
    |> subject(subject)
    |> text_body(body)
    |> Mailer.deliver_later()
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Bitte bestätige deine E-Mail Adresse", """
    Hi #{user.email},

    willkommen bei toniefy! Bitte bestätige deinen Account, indem
    du auf den folgenden Link klickst.

    #{url}

    Falls du keinen Account bei toniefy erstellt hast, kannst du
    diese E-Mail einfach ignorieren.

    Liebe Grüße

    Henri
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Dein Passwort zurücksetzen", """
    Hi #{user.email},

    du erhälst diese E-Mail, weil wir die Anfrage erhalten haben,
    dein Passwort zurückzusetzen. Um dein Passwort zurückzusetzen,
    klicke bitte auf den folgenden Link:

    #{url}

    Falls du kein neues Passwort von toniefy angefordert hast, kannst du
    diese E-Mail einfach ignorieren.

    Liebe Grüße

    Henri
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "E-Mail Adresse aktualisieren", """
    Hi #{user.email},

    du erhälst diese E-Mail, weil wir die Anfrage erhalten haben,
    deine E-Mail Adresse zu aktualisieren zurückzusetzen.

    Bitte bestätige deine Änderung, indem du auf folgenden Link klickst:

    #{url}

    Falls du keine Aktualisierung der E-Mail Adresse angefordert hast, kannst du
    diese E-Mail einfach ignorieren.

    Liebe Grüße

    Henri
    """)
  end
end
