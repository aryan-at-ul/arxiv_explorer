import Config

config :arxiv_explorer,
  ecto_repos: []

config :arxiv_explorer, ArxivExplorerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: ArxivExplorerWeb.ErrorHTML, json: ArxivExplorerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ArxivExplorer.PubSub,
  live_view: [signing_salt: "arxiv_secret"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason


config :nx, :default_backend, EXLA.Backend

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.0",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

import_config "#{config_env()}.exs"

config :exla, :clients,
  cuda: [memory_fraction: 0.5, preallocate: false],
  host: [lazy: false]

config :nx, :default_backend, EXLA.Backend

config :httpoison,
  timeout: 60_000,
  recv_timeout: 60_000
