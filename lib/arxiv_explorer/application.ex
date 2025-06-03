defmodule ArxivExplorer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ArxivExplorerWeb.Telemetry,
      {Phoenix.PubSub, name: ArxivExplorer.PubSub},
      ArxivExplorer.LLM.Server,
      ArxivExplorerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ArxivExplorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ArxivExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
