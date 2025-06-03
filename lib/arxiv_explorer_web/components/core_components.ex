defmodule ArxivExplorerWeb.CoreComponents do
  use Phoenix.Component

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Info" flash={@flash} />
    <.flash kind={:error} title="Error" flash={@flash} />
    """
  end

  attr :kind, :atom, values: [:info, :error], doc: "info or error"
  attr :title, :string, default: nil
  attr :flash, :map, required: true

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id="flash"
      class={[
        "fixed top-2 right-2 z-50 p-3 rounded-lg shadow-lg",
        @kind == :info && "bg-blue-50 text-blue-900 border border-blue-200",
        @kind == :error && "bg-red-50 text-red-900 border border-red-200"
      ]}
    >
      <p :if={@title} class="font-semibold"><%= @title %></p>
      <p><%= msg %></p>
    </div>
    """
  end
end
