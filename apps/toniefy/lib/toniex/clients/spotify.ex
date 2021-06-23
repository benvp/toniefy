defmodule Toniex.Clients.Spotify do
  @spotify_uri_regex ~r/^spotify:(?<type>(playlist|album|track)):(?<id>[\w\d]+)$/
  @spotify_url_regex ~r/\/(?<type>(playlist|album|track))\/(?<id>[\w\d]+)/

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
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middlewares)
  end

  @doc """
  Get the total duration of a Spotify URI or URL. Returns

  Returns `{:ok, duration_ms}` or an error tuple `{:error, any()}`.

  ## Parameters

    - client: The Spotify client
    - uri: A Spotify URI. Supported URI types are: `track`, `album`, `playlist`.

  """
  @spec total_duration(Tesla.Client.t(), String.t()) ::
          {:ok, integer()} | {:error, :uri_not_supported | any()}
  def total_duration(client, uri_or_url) do
    %{type: type, id: id} = parse_uri(uri_or_url)

    case type do
      "track" ->
        case get_track(client, id) do
          {:ok, track} -> {:ok, track["duration_ms"]}
          other -> other
        end

      "album" ->
        case get_all_tracks(client, uri_or_url) do
          {:ok, tracks} ->
            duration =
              Enum.reduce(tracks, 0, fn track, duration ->
                duration + Map.get(track, "duration_ms")
              end)

            {:ok, duration}

          other ->
            other
        end

      "playlist" ->
        case get_all_tracks(client, uri_or_url) do
          {:ok, tracks} ->
            duration =
              Enum.reduce(tracks, 0, fn track, duration ->
                duration + get_in(track, ["track", "duration_ms"])
              end)

            {:ok, duration}

          other ->
            other
        end

      _ ->
        {:error, :uri_not_supported}
    end
  end

  @doc """
  Get a single track.
  """
  def get_track(client, id) do
    client
    |> Tesla.get("/tracks/#{id}")
    |> handle_response()
  end

  @doc """
  Get all tracks of a Spotify URI.

  ## Parameters

    - client: The Spotify client
    - uri: A Spotify URI. Supported URI types are: `track`, `album`, `playlist`.
  """
  @spec get_all_tracks(Tesla.Client.t(), String.t(), list, String.t()) ::
          {:ok, list()} | {:error, any()}
  def get_all_tracks(
        client,
        uri_or_url,
        tracks \\ [],
        page_url \\ ""
      )

  def get_all_tracks(
        _client,
        _uri,
        tracks,
        nil
      ),
      do: {:ok, tracks}

  def get_all_tracks(
        client,
        uri_or_url,
        tracks,
        page_url
      ) do
    %{id: id, type: type} = parse_uri(uri_or_url)

    url =
      case type do
        "playlist" -> "/playlists/#{id}/tracks"
        "album" -> "/albums/#{id}/tracks"
        true -> raise("Invalid URI type.")
      end

    url = if page_url == "", do: url, else: page_url

    result =
      client
      |> Tesla.get(url)
      |> handle_response()

    case result do
      {:ok, %{"items" => items, "next" => next}} ->
        {:ok, page_tracks} = get_all_tracks(client, uri_or_url, items, next)
        {:ok, page_tracks ++ tracks}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parse a spotify URI or URL.
  """
  def parse_uri(uri_or_url) do
    cond do
      String.match?(uri_or_url, @spotify_uri_regex) ->
        %{"id" => id, "type" => type} = Regex.named_captures(@spotify_uri_regex, uri_or_url)
        %{id: id, type: type}

      String.match?(uri_or_url, @spotify_url_regex) ->
        %{"id" => id, "type" => type} = Regex.named_captures(@spotify_url_regex, uri_or_url)
        %{id: id, type: type}

      true ->
        {:error, :invalid_uri_or_url}
    end
  end

  @doc """
  Converts a Spotify URL to an URI
  """
  def to_uri(url) do
    cond do
      String.match?(url, @spotify_uri_regex) ->
        url

      String.match?(url, @spotify_url_regex) ->
        %{"id" => id, "type" => type} = Regex.named_captures(@spotify_url_regex, url)
        "spotify:#{type}:#{id}"

      true ->
        {:error, :invalid_url}
    end
  end

  defp base64_credentials() do
    config = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Spotify.OAuth)

    client_id = Keyword.fetch!(config, :client_id)
    client_secret = Keyword.fetch!(config, :client_secret)

    Base.encode64("#{client_id}:#{client_secret}")
  end

  @spec handle_response(Tesla.Env.result()) :: {:ok, any()} | {:error, any()}
  defp handle_response(response) do
    case response do
      {:ok, %Tesla.Env{status: status, body: body}} when status in 400..499 ->
        {:error, body}

      {:ok, %Tesla.Env{status: status, body: body}} when status in 500..599 ->
        {:error, body}

      {:ok, %Tesla.Env{body: body}} ->
        {:ok, body}

      other ->
        other
    end
  end
end
