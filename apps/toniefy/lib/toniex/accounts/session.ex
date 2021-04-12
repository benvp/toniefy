defmodule Toniex.Accounts.Session do
  @moduledoc """
  Provides sessions for third party services.

  Also makes sure that the token is valid for usage.
  We currently use a quite naive approach by refreshing the session
  whenever the token is about to expire in the next 30 minutes.
  """

  alias Toniex.Accounts
  alias Toniex.Accounts.Credential
  alias Toniex.Clients.{Spotify, Tonies}
  alias Toniex.Repo

  def get_session_token(user, service) when service in [:spotify, :tonies] do
    credential = Accounts.get_credential_by_provider(user, service)

    if credential do
      expires_in = DateTime.diff(credential.expires_at, DateTime.utc_now())

      credential =
        if expires_in < 1800, do: refresh_credential(credential, service), else: credential

      case credential do
        {:error, _} ->
          nil

        credential ->
          credential.access_token
      end
    else
      nil
    end
  end

  defp refresh_credential(%Credential{} = credential, :spotify) do
    token = Spotify.get_token(credential.refresh_token)

    expires_at = DateTime.utc_now() |> DateTime.add(token.expires_in, :second)

    update_credential(credential, %{
      access_token: token.access_token,
      expires_at: expires_at,
      scopes: token.scope
    })
  end

  defp refresh_credential(%Credential{} = credential, :tonies) do
    case Tonies.get_token(credential.refresh_token) do
      {:error, _} ->
        {:error, :unknown}

      token ->
        expires_at = DateTime.utc_now() |> DateTime.add(token.expires_in, :second)
        refresh_expires_at = DateTime.utc_now() |> DateTime.add(token.refresh_expires_in, :second)

        update_credential(credential, %{
          access_token: token.access_token,
          expires_at: expires_at,
          refresh_token: token.refresh_token,
          refresh_expires_at: refresh_expires_at,
          scopes: token.scope
        })
    end
  end

  defp update_credential(%Credential{} = credential, attrs) do
    credential
    |> Credential.changeset(attrs)
    |> Repo.update!()
  end
end
