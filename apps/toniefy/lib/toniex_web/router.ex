defmodule ToniexWeb.Router do
  use ToniexWeb, :router

  import ToniexWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ToniexWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ToniexWeb do
    pipe_through :browser

    live "/", PageLive, :index

    get "/record", RecordController, :index
    get "/privacy", PageController, :privacy
    get "/piggy-bank", PageController, :donate
    get "/piggy-bank/thank-you", PageController, :donate_success
  end

  scope "/", ToniexWeb do
    pipe_through :api

    post "/record", RecordController, :upload
    put "/record/status", RecordController, :status
    get "/record/token", RecordController, :token
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    forward "/sent_emails", Bamboo.SentEmailViewerPlug

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ToniexWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", ToniexWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    # we disable registration for now
    get "/register", UserRegistrationController, :new
    post "/register", UserRegistrationController, :create

    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/reset-password", UserResetPasswordController, :new
    post "/reset-password", UserResetPasswordController, :create
    get "/reset-password/:token", UserResetPasswordController, :edit
    put "/reset-password/:token", UserResetPasswordController, :update
  end

  scope "/", ToniexWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/me", UserSettingsController, :edit
    put "/me/change-password", UserSettingsController, :update
    put "/me/change-email", UserSettingsController, :update
    get "/me/confirm-email/:token", UserSettingsController, :confirm_email
    delete "/me/disconnect-service", UserSettingsController, :disconnect_service

    live "/library", LibraryLive.Index, :index
    live "/library/record", RecorderLive
    live "/library/record/review", ReviewSessionLive
    live "/library/:id", LibraryLive.Index, :show
  end

  scope "/", ToniexWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  scope "/auth", ToniexWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/:provider", UserSessionController, :request
    get "/:provider/callback", UserSessionController, :callback
    post "/:provider/callback", UserSessionController, :callback
  end
end
