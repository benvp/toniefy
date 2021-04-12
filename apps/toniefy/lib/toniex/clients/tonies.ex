defmodule Toniex.Clients.Tonies do
  @client_id "my-tonies"
  @token_url "https://login.tonies.com/auth/realms/tonies/protocol/openid-connect/token"
  @api_url "https://api.tonie.cloud/v2"

  def get_token(refresh_token) do
    res =
      Tesla.client([
        Tesla.Middleware.FormUrlencoded,
        Tesla.Middleware.JSON
      ])
      |> Tesla.post!(
        @token_url,
        %{
          scope: "openid",
          client_id: @client_id,
          grant_type: "refresh_token",
          refresh_token: refresh_token
        }
      )

    case res.status do
      200 ->
        %{
          access_token: res.body["access_token"],
          expires_in: res.body["expires_in"],
          refresh_token: res.body["refresh_token"],
          refresh_expires_in: res.body["refresh_expires_in"],
          token_type: res.body["token_type"],
          scope: res.body["scope"]
        }

      _ ->
        {:error, res}
    end
  end

  def client(token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, @api_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{token}"}]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middlewares)
  end

  def get_main_household_creative_tonies(client) do
    household_id =
      client
      |> get_households()
      |> elem(1)
      |> Enum.find(fn x -> x["access"] == "owner" end)
      |> Map.fetch!("id")

    get_creative_tonies(client, household_id)
  end

  def get_creative_tonies(client, household_id) do
    client
    |> Tesla.get!("/households/#{household_id}/creativetonies")
    |> handle_result()
  end

  def get_households(client) do
    client
    |> Tesla.get!("/households")
    |> handle_result()
  end

  def upload_file(client, path) do
    {:ok,
     %{
       "fileId" => key,
       "request" => %{
         "url" => url,
         "fields" => fields
       }
     }} = get_upload_meta(client)

    # We use HTTPoison here instead of tesla as I have no
    # idea why the multipart transfer via Tesla fails.
    result =
      HTTPoison.post(
        url,
        {:multipart,
         [
           {"key", key},
           {"x-amz-algorithm", fields["x-amz-algorithm"]},
           {"x-amz-credential", fields["x-amz-credential"]},
           {"x-amz-date", fields["x-amz-date"]},
           {"x-amz-signature", fields["x-amz-signature"]},
           {"policy", fields["policy"]},
           {:file, Path.expand(path),
            {"form-data",
             [
               {"name", "file"},
               {"filename", key}
             ]},
            [
              {"Content-Type", MIME.from_path(Path.expand(path))}
            ]}
         ]}
      )

    case result do
      {:ok, %HTTPoison.Response{status_code: 204}} -> {:ok, key}
      {:ok, res} -> {:error, res}
      other -> other
    end
  end

  def get_chapters(client, household_id, tonie_id) do
    Tesla.get!(client, "/households/#{household_id}/creativetonies/#{tonie_id}")
    |> handle_result()
  end

  @doc """
  Updates the given chapters. Requires a list of chapters.
  If you add a new chapter, `file`, `id` and `title` are required.

  Note: Not sure if all existing chapters are required as it's a PATCH
  operation. I didn't test it, so include them, just in case.
  """
  def update_chapters(client, household_id, tonie_id, chapters) do
    Tesla.patch!(client, "/households/#{household_id}/creativetonies/#{tonie_id}", %{
      chapters: chapters
    })
    |> handle_result()
  end

  defp get_upload_meta(client) do
    client
    |> Tesla.post!("/file", %{headers: %{}})
    |> handle_result()
  end

  defp handle_result(result) do
    case result do
      %Tesla.Env{status: status, body: body} when status >= 200 and status <= 299 ->
        {:ok, body}

      other ->
        {:error, other}
    end
  end
end
