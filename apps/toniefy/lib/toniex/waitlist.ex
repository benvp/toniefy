defmodule Toniex.Waitlist do
  @moduledoc """
  The Waitlist context.
  """

  alias Toniex.{Repo, Waitlist}
  alias Toniex.Waitlist.{Entry, InviteNotifier}

  @doc """
  Joins the waitlist

  ## Examples

      iex> join(email)
      {:ok, %Waitlist.Entry{}}

      iex> join(email)
      {:error, %Ecto.Changeset{}}

  """
  @spec join(String.t()) :: {:ok, Waitlist.Entry.t()} | {:error, Ecto.Changeset.t()}
  def join(email) do
    %Waitlist.Entry{}
    |> Waitlist.Entry.changeset(%{email: email})
    |> Repo.insert()
  end

  def change_entry(%Waitlist.Entry{} = entry, attrs \\ %{}),
    do: Waitlist.Entry.changeset(entry, attrs)

  def invite(email, register_url_fun) do
    entry =
      Repo.get_by!(Entry, email: email)
      |> Entry.invite_changeset(%{invite_code: build_invite_code()})
      |> Repo.update!()

    InviteNotifier.deliver_invite_instructions(
      email,
      register_url_fun.(entry.invite_code),
      entry.invite_code
    )
  end

  def validate_invite_code(email, code) do
    case Repo.get_by(Entry, email: email, invite_code: code) do
      %Entry{} = entry ->
        entry

      _ ->
        nil
    end
  end

  defp build_invite_code() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end
end
