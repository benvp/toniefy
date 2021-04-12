import Config

config :toniex_recorder,
  toniex_host: System.get_env("TONIEX_HOST"),
  record_token: System.get_env("RECORD_TOKEN"),
  job_id: System.get_env("TONIEX_JOB_ID"),
  queue: System.get_env("TONIEX_QUEUE")

config :tesla, adapter: Tesla.Adapter.Hackney, recv_timeout: 30_000

config :wallaby,
  driver: Wallaby.Chrome,
  screenshot_on_failure: true,
  chromedriver: [
    headless: false,
    capabilities: %{
      javascriptEnabled: true,
      loadImages: true,
      version: "",
      rotatable: false,
      takesScreenshot: true,
      cssSelectorsEnabled: true,
      nativeEvents: true,
      platform: "ANY",
      unhandledPromptBehavior: "accept",
      loggingPrefs: %{
        browser: "DEBUG"
      },
      chromeOptions: %{
        args: [
          "window-size=1280,800",
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--no-default-browser-check",
          "--disable-gpu",
          "--fullscreen",
          "--no-first-run",
          "--autoplay-policy=no-user-gesture-required",
          "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
        ]
      }
    }
  ],
  otp_app: :toniex_recorder

driver_path =
  case(:os.type()) do
    {_, :darwin} -> Path.expand("./bin/goon-darwin")
    {_, :linux} -> Path.expand("./bin/goon-linux")
  end

# Goon Driver somehoe doesn't work with run.sh. Dunno why
# but we fall back to the Basic Driver. Does work fine in our case
# ...Maybe we find some better approach instead of using Porcelain
config :porcelain, :driver, Porcelain.Driver.Basic
config :porcelain, goon_driver_path: driver_path

import_config "#{config_env()}.exs"
