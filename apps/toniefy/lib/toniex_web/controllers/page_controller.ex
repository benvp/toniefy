defmodule ToniexWeb.PageController do
  use ToniexWeb, :controller

  def privacy(conn, _params) do
    render(conn, "privacy.html")
  end

  def donate(conn, _params) do
    render(conn, "donate.html")
  end

  def donate_success(conn, _params) do
    render(conn, "donate_success.html")
  end
end
