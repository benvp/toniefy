defmodule Toniex.Accounts.Credential.Helpers do
  alias Ueberauth.Auth

  def credential_from_auth(user, %Auth{provider: :spotify} = auth) do
    %{
      username: auth.info.nickname,
      email: auth.info.email,
      provider: :spotify,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      scopes: List.first(auth.credentials.scopes),
      expires_at: DateTime.from_unix!(auth.credentials.expires_at),
      user_id: user.id
    }
  end

  def credential_from_auth(user, %Auth{provider: :tonies} = auth) do
    %{
      username: auth.info.email,
      email: auth.info.email,
      provider: :tonies,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      scopes: Enum.join(auth.credentials.scopes, " "),
      expires_at: DateTime.from_unix!(auth.credentials.expires_at),
      refresh_expires_at:
        DateTime.utc_now()
        |> DateTime.add(auth.credentials.other.refresh_expires_in, :second),
      user_id: user.id
    }
  end

  def credential_from_auth(_user, _auth) do
    {:error, :provider_not_supported}
  end
end
