defmodule Toniex.Waitlist.Entry do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          email: binary()
        }

  schema "waitlist_entries" do
    field :email, :string
    field :invite_code, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_email()
  end

  def invite_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:invite_code])
    |> validate_required([:invite_code])
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "muss ein @ Zeichen beinhalten und darf keine Leerzeichen haben"
    )
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Toniex.Repo)
    |> unique_constraint(:email)
  end
end
