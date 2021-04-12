defmodule Toniex.Waitlist.InviteNotifier do
  import Bamboo.Email

  alias Toniex.Mailer

  defp deliver(to, subject, body) do
    new_email()
    |> from("noreply@toniefy.me")
    |> to(to)
    |> subject(subject)
    |> text_body(body)
    |> Mailer.deliver_later()
  end

  @doc """
  Deliver invitation with instructions on how to create an account.
  """
  def deliver_invite_instructions(email, register_url, invite_code) do
    deliver(email, "Deine Einladung zu toniefy.", """
    Hey du,

    es ist soweit. Mit dieser E-Mail erhälst du die Möglichkeit, deinen
    persönlichen toniefy Account zu erstellen. Gib hierzu auf der Registrierungsseite
    einfach den folgenden Code ein.

    Einladungscode: #{invite_code}

    Zur Registrierung geht es hier entlang: #{register_url}

    Ich freue mich, dass du ein Teil von toniefy wirst.

    Liebe Grüße

    Henri

    -----------------------

    Du erhälst diese E-Mail, da du dich in die Warteliste für toniefy
    eingetragen hast. Falls du dich nicht selbst eingetragen hast, kannst
    du diese E-Mail einfach ignorieren.
    """)
  end
end
