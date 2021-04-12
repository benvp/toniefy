defmodule Toniex.Clients.Spotify do
  def get_token(refresh_token) do
    res =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded,
        {Tesla.Middleware.Headers, [{"Authorization", "Basic #{base64_credentials()}"}]},
        Tesla.Middleware.JSON
      ])
      |> Tesla.post!(
        "https://accounts.spotify.com/api/token",
        %{
          grant_type: "refresh_token",
          refresh_token: refresh_token
        }
      )

    %{
      access_token: res.body["access_token"],
      expires_in: res.body["expires_in"],
      token_type: res.body["token_type"],
      scope: res.body["scope"]
    }
  end

  def client(token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middlewares)
  end

  defp base64_credentials() do
    config = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Spotify.OAuth)

    client_id = Keyword.fetch!(config, :client_id)
    client_secret = Keyword.fetch!(config, :client_secret)

    Base.encode64("#{client_id}:#{client_secret}")
  end
end
