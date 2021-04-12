defmodule Toniex.Token do
  @spec sign(:recorder, [{:uri, binary()} | {:user_id, binary()}]) ::
          Phoenix.Token.t()
  def sign(:recorder, data) do
    Phoenix.Token.sign(ToniexWeb.Endpoint, "toniex_recorder", Enum.into(data, %{}))
  end

  def sign(_type, _data) do
    raise "Invalid token type."
  end

  @spec verify(nil | binary, :recorder) :: {:error, :expired | :invalid | :missing} | {:ok, any}
  def verify(token, :recorder) do
    Phoenix.Token.verify(ToniexWeb.Endpoint, "toniex_recorder", token, max_age: 2 * 60 * 60)
  end

  def verify(_token, _type) do
    raise "Invalid token type."
  end
end
