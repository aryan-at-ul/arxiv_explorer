# defmodule ArxivExplorerWeb.SearchLive do
#   use ArxivExplorerWeb, :live_view
#   alias ArxivExplorer.ArxivAPI
#   alias ArxivExplorer.LLM.Server

#   def mount(_params, _session, socket) do
#     {:ok,
#      assign(socket,
#        keywords: "",
#        papers: [],
#        loading: false,
#        error: nil,
#        analyzed_papers: %{}
#      )}
#   end

#   def render(assigns) do
#     ~H"""
#     <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50">
#       <!-- Header -->
#       <div class="bg-white shadow-sm border-b">
#         <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
#           <div class="text-center">
#             <h1 class="text-4xl font-bold text-gray-900 mb-2">
#               📚 ArXiv Explorer
#             </h1>
#             <p class="text-lg text-gray-600">
#               Discover and analyze research papers with AI-powered insights
#             </p>
#           </div>
#         </div>
#       </div>

#       <!-- Search Section -->
#       <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
#         <form phx-submit="search" class="space-y-4">
#           <div class="flex flex-col sm:flex-row gap-4">
#             <div class="flex-1">
#               <input
#                 type="text"
#                 name="keywords"
#                 value={@keywords}
#                 phx-change="update_keywords"
#                 placeholder="Enter keywords (e.g., 'machine learning', 'neural networks', 'computer vision')"
#                 class="w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
#                 required
#               />
#             </div>
#             <button
#               type="submit"
#               disabled={@loading or String.trim(@keywords) == ""}
#               class="px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
#             >
#               <%= if @loading do %>
#                 🔍 Searching...
#               <% else %>
#                 🚀 Search Papers
#               <% end %>
#             </button>
#           </div>
#         </form>

#         <!-- Error Display -->
#         <%= if @error do %>
#           <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
#             <p class="text-red-800">❌ <%= @error %></p>
#           </div>
#         <% end %>

#         <!-- Loading State -->
#         <%= if @loading do %>
#           <div class="mt-8 text-center">
#             <div class="inline-flex items-center space-x-2">
#               <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
#               <span class="text-gray-600">Fetching papers from ArXiv...</span>
#             </div>
#           </div>
#         <% end %>

#         <!-- Results -->
#         <%= if length(@papers) > 0 do %>
#           <div class="mt-8">
#             <h2 class="text-2xl font-bold text-gray-900 mb-6">
#               📄 Found <%= length(@papers) %> papers
#             </h2>

#             <div class="space-y-6">
#               <%= for paper <- @papers do %>
#                 <div class="bg-white rounded-lg shadow-md border border-gray-200 overflow-hidden">
#                   <div class="p-6">
#                     <div class="flex items-start justify-between">
#                       <div class="flex-1">
#                         <h3 class="text-xl font-semibold text-gray-900 mb-2">
#                           <%= paper.title %>
#                         </h3>
#                         <div class="flex flex-wrap items-center text-sm text-gray-600 mb-3 space-x-4">
#                           <span>📅 <%= format_date(paper.published) %></span>
#                           <span>🏷️ <%= paper.primary_category %></span>
#                           <span>👥 <%= format_authors(paper.authors) %></span>
#                         </div>
#                       </div>
#                     </div>

#                     <div class="mb-4">
#                       <p class="text-gray-700 leading-relaxed">
#                         <%= String.slice(paper.summary, 0, 400) %><%= if String.length(paper.summary) > 400, do: "..." %>
#                       </p>
#                     </div>

#                     <div class="flex flex-wrap gap-3 mb-4">
#                       <a
#                         href={paper.pdf_url}
#                         target="_blank"
#                         class="inline-flex items-center px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 transition-colors"
#                       >
#                         📄 Download PDF
#                       </a>

#                       <a
#                         href={paper.abstract_url}
#                         target="_blank"
#                         class="inline-flex items-center px-4 py-2 bg-gray-600 text-white text-sm font-medium rounded-md hover:bg-gray-700 transition-colors"
#                       >
#                         🔗 View Abstract
#                       </a>

#                       <button
#                         phx-click="analyze_paper"
#                         phx-value-paper-id={paper.id}
#                         phx-value-type="summary"
#                         class="inline-flex items-center px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-md hover:bg-green-700 transition-colors"
#                       >
#                         🤖 AI Summary
#                       </button>

#                       <button
#                         phx-click="analyze_paper"
#                         phx-value-paper-id={paper.id}
#                         phx-value-type="keywords"
#                         class="inline-flex items-center px-4 py-2 bg-purple-600 text-white text-sm font-medium rounded-md hover:bg-purple-700 transition-colors"
#                       >
#                         🔑 Extract Keywords
#                       </button>
#                     </div>

#                     <%= if analysis = @analyzed_papers[paper.id] do %>
#                       <div class="border-t pt-4 space-y-3">
#                         <%= if analysis.summary do %>
#                           <div class="bg-green-50 border border-green-200 rounded-lg p-4">
#                             <h4 class="font-semibold text-green-800 mb-2">🤖 AI Summary</h4>
#                             <p class="text-green-700"><%= analysis.summary %></p>
#                           </div>
#                         <% end %>

#                         <%= if analysis.keywords do %>
#                           <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
#                             <h4 class="font-semibold text-purple-800 mb-2">🔑 Key Terms</h4>
#                             <p class="text-purple-700"><%= analysis.keywords %></p>
#                           </div>
#                         <% end %>
#                       </div>
#                     <% end %>
#                   </div>
#                 </div>
#               <% end %>
#             </div>
#           </div>
#         <% end %>
#       </div>
#     </div>
#     """
#   end

#   def handle_event("update_keywords", params, socket) do
#     keywords =
#       case params do
#         %{"keywords" => kw} -> kw
#         %{"value" => kw} -> kw
#         %{"_target" => ["keywords"], "keywords" => kw} -> kw
#         _ -> ""
#       end

#     {:noreply, assign(socket, keywords: keywords)}
#   end

#   def handle_event("search", %{"keywords" => keywords}, socket) do
#     keywords = String.trim(keywords)

#     if keywords != "" do
#       pid = self()

#       Task.start(fn ->
#         case ArxivAPI.search_papers(keywords, 10) do
#           {:ok, papers} ->
#             send(pid, {:search_complete, papers})

#           {:error, error} ->
#             send(pid, {:search_error, error})
#         end
#       end)

#       {:noreply, assign(socket, loading: true, error: nil, papers: [], analyzed_papers: %{})}
#     else
#       {:noreply, socket}
#     end
#   end

#   def handle_event("analyze_paper", %{"paper-id" => paper_id, "type" => type}, socket) do
#     paper = Enum.find(socket.assigns.papers, &(&1.id == paper_id))

#     if paper do
#       pid = self()
#       analysis_type = String.to_atom(type)

#       Task.start(fn ->
#         case Server.analyze_paper(paper, analysis_type) do
#           {:ok, result} ->
#             send(pid, {:analysis_complete, paper_id, analysis_type, result})

#           {:error, error} ->
#             send(pid, {:analysis_error, paper_id, error})
#         end
#       end)
#     end

#     {:noreply, socket}
#   end

#   def handle_info({:search_complete, papers}, socket) do
#     {:noreply, assign(socket, papers: papers, loading: false)}
#   end

#   def handle_info({:search_error, error}, socket) do
#     {:noreply, assign(socket, error: error, loading: false)}
#   end

#   def handle_info({:analysis_complete, paper_id, type, result}, socket) do
#     analyzed_papers = socket.assigns.analyzed_papers
#     existing_analysis = Map.get(analyzed_papers, paper_id, %{})
#     updated_analysis = Map.put(existing_analysis, type, result)

#     {:noreply,
#      assign(socket,
#        analyzed_papers: Map.put(analyzed_papers, paper_id, updated_analysis)
#      )}
#   end

#   def handle_info({:analysis_error, _paper_id, _error}, socket) do
#     {:noreply, socket}
#   end

#   defp format_date(%DateTime{} = datetime) do
#     Calendar.strftime(datetime, "%Y-%m-%d")
#   end

#   defp format_date(_), do: "Unknown"

#   defp format_authors(authors) when length(authors) <= 3 do
#     Enum.join(authors, ", ")
#   end

#   defp format_authors(authors) do
#     first_three = Enum.take(authors, 3)
#     Enum.join(first_three, ", ") <> " et al."
#   end
# end


defmodule ArxivExplorerWeb.SearchLive do
  use ArxivExplorerWeb, :live_view
  alias ArxivExplorer.ArxivAPI
  alias ArxivExplorer.LLM.Server

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       keywords: "",
       papers: [],
       loading: false,
       error: nil,
       analyzed_papers: %{}
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50">
      <!-- Header -->
      <div class="bg-white shadow-sm border-b">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div class="text-center">
            <h1 class="text-4xl font-bold text-gray-900 mb-2">
              📚 ArXiv Explorer
            </h1>
            <p class="text-lg text-gray-600">
              Discover and analyze research papers with AI-powered insights
            </p>
          </div>
        </div>
      </div>

      <!-- Search Section -->
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <form phx-submit="search" class="space-y-4">
          <div class="flex flex-col sm:flex-row gap-4">
            <div class="flex-1">
              <input
                type="text"
                name="keywords"
                value={@keywords}
                phx-change="update_keywords"
                placeholder="Enter keywords (e.g., 'machine learning', 'neural networks', 'computer vision')"
                class="w-full px-4 py-3 text-lg border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
            <button
              type="submit"
              disabled={@loading or String.trim(@keywords) == ""}
              class="px-6 py-3 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <%= if @loading do %>
                🔍 Searching...
              <% else %>
                🚀 Search Papers
              <% end %>
            </button>
          </div>
        </form>

        <!-- Error Display -->
        <%= if @error do %>
          <div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p class="text-red-800">❌ <%= @error %></p>
          </div>
        <% end %>

        <!-- Loading State -->
        <%= if @loading do %>
          <div class="mt-8 text-center">
            <div class="inline-flex items-center space-x-2">
              <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
              <span class="text-gray-600">Fetching papers from ArXiv...</span>
            </div>
          </div>
        <% end %>

        <!-- Results -->
        <%= if length(@papers) > 0 do %>
          <div class="mt-8">
            <h2 class="text-2xl font-bold text-gray-900 mb-6">
              📄 Found <%= length(@papers) %> papers
            </h2>

            <div class="space-y-6">
              <%= for paper <- @papers do %>
                <div class="bg-white rounded-lg shadow-md border border-gray-200 overflow-hidden">
                  <div class="p-6">
                    <div class="flex items-start justify-between">
                      <div class="flex-1">
                        <h3 class="text-xl font-semibold text-gray-900 mb-2">
                          <%= paper.title %>
                        </h3>
                        <div class="flex flex-wrap items-center text-sm text-gray-600 mb-3 space-x-4">
                          <span>📅 <%= format_date(paper.published) %></span>
                          <span>🏷️ <%= paper.primary_category %></span>
                          <span>👥 <%= format_authors(paper.authors) %></span>
                        </div>
                      </div>
                    </div>

                    <div class="mb-4">
                      <p class="text-gray-700 leading-relaxed">
                        <%= String.slice(paper.summary, 0, 400) %><%= if String.length(paper.summary) > 400, do: "..." %>
                      </p>
                    </div>

                    <div class="flex flex-wrap gap-3 mb-4">
                      <a
                        href={paper.pdf_url}
                        target="_blank"
                        class="inline-flex items-center px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 transition-colors"
                      >
                        📄 Download PDF
                      </a>

                      <a
                        href={paper.abstract_url}
                        target="_blank"
                        class="inline-flex items-center px-4 py-2 bg-gray-600 text-white text-sm font-medium rounded-md hover:bg-gray-700 transition-colors"
                      >
                        🔗 View Abstract
                      </a>

                      <button
                        phx-click="analyze_paper"
                        phx-value-paper-id={paper.id}
                        phx-value-type="summary"
                        class="inline-flex items-center px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-md hover:bg-green-700 transition-colors"
                      >
                        🤖 AI Summary
                      </button>

                      <button
                        phx-click="analyze_paper"
                        phx-value-paper-id={paper.id}
                        phx-value-type="keywords"
                        class="inline-flex items-center px-4 py-2 bg-purple-600 text-white text-sm font-medium rounded-md hover:bg-purple-700 transition-colors"
                      >
                        🔑 Extract Keywords
                      </button>
                    </div>

                    <!-- Analysis Results -->
                    <%= if analysis = @analyzed_papers[paper.id] do %>
                      <div class="border-t pt-4 space-y-3">
                        <!-- Summary block (if present) -->
                        <%= if summary_text = Map.get(analysis, :summary) do %>
                          <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                            <h4 class="font-semibold text-green-800 mb-2">🤖 AI Summary</h4>
                            <p class="text-green-700"><%= summary_text %></p>
                          </div>
                        <% end %>

                        <!-- Keywords block (if present) -->
                        <%= if keywords_text = Map.get(analysis, :keywords) do %>
                          <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                            <h4 class="font-semibold text-purple-800 mb-2">🔑 Key Terms</h4>
                            <p class="text-purple-700"><%= keywords_text %></p>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("update_keywords", params, socket) do
    keywords =
      case params do
        %{"keywords" => kw} -> kw
        %{"value" => kw} -> kw
        %{"_target" => ["keywords"], "keywords" => kw} -> kw
        _ -> ""
      end

    {:noreply, assign(socket, keywords: keywords)}
  end

  def handle_event("search", %{"keywords" => keywords}, socket) do
    keywords = String.trim(keywords)

    if keywords != "" do
      pid = self()

      Task.start(fn ->
        case ArxivAPI.search_papers(keywords, 10) do
          {:ok, papers} ->
            send(pid, {:search_complete, papers})

          {:error, error} ->
            send(pid, {:search_error, error})
        end
      end)

      {:noreply, assign(socket, loading: true, error: nil, papers: [], analyzed_papers: %{})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("analyze_paper", %{"paper-id" => paper_id, "type" => type}, socket) do
    paper = Enum.find(socket.assigns.papers, &(&1.id == paper_id))

    if paper do
      pid = self()
      analysis_type = String.to_atom(type)

      Task.start(fn ->
        case Server.analyze_paper(paper, analysis_type) do
          {:ok, result} ->
            send(pid, {:analysis_complete, paper_id, analysis_type, result})

          {:error, error} ->
            send(pid, {:analysis_error, paper_id, error})
        end
      end)
    end

    {:noreply, socket}
  end

  def handle_info({:search_complete, papers}, socket) do
    {:noreply, assign(socket, papers: papers, loading: false)}
  end

  def handle_info({:search_error, error}, socket) do
    {:noreply, assign(socket, error: error, loading: false)}
  end

  def handle_info({:analysis_complete, paper_id, type, result}, socket) do
    analyzed_papers = socket.assigns.analyzed_papers
    existing_analysis = Map.get(analyzed_papers, paper_id, %{})
    updated_analysis = Map.put(existing_analysis, type, result)

    {:noreply,
     assign(socket,
       analyzed_papers: Map.put(analyzed_papers, paper_id, updated_analysis)
     )}
  end

  def handle_info({:analysis_error, _paper_id, _error}, socket) do
    {:noreply, socket}
  end

  defp format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d")
  end

  defp format_date(_), do: "Unknown"

  defp format_authors(authors) when length(authors) <= 3 do
    Enum.join(authors, ", ")
  end

  defp format_authors(authors) do
    first_three = Enum.take(authors, 3)
    Enum.join(first_three, ", ") <> " et al."
  end
end
