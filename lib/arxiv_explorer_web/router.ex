defmodule ArxivExplorerWeb.Router do
  use ArxivExplorerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArxivExplorerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ArxivExplorerWeb do
    pipe_through :browser

    live "/", SearchLive
  end
end
