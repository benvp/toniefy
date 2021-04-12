defmodule Toniex.Accounts.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  alias Toniex.Accounts

  schema "credentials" do
    field :username, :string
    field :email, :string
    field :access_token, :string
    field :refresh_token, :string
    field :scopes, :string
    field :expires_at, :utc_datetime
    field :refresh_expires_at, :utc_datetime
    field :provider, Ecto.Enum, values: [:spotify, :tonies]

    belongs_to :user, Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [
      :username,
      :email,
      :provider,
      :access_token,
      :refresh_token,
      :scopes,
      :expires_at,
      :refresh_expires_at,
      :user_id
    ])
    |> validate_required([
      :username,
      :email,
      :provider,
      :access_token,
      :refresh_token,
      :scopes,
      :expires_at,
      :user_id
    ])

    # Currently commented-out because we rely on database constraints for upserting.
    # |> unique_constraint(:credentials, name: :unique_credentials_index)
  end
end
