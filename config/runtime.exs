import Config

if config_env() == :prod do
  config :arxiv_explorer, ArxivExplorerWeb.Endpoint,
    url: [host: System.get_env("PHX_HOST") || "example.com", port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  if System.get_env("SECRET_KEY_BASE") == nil do
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """
  end
end
