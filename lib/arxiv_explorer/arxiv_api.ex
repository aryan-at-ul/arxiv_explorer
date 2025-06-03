# defmodule ArxivExplorer.ArxivAPI do
#   @moduledoc """
#   Client for ArXiv API to fetch papers
#   """

#   import SweetXml
#   require Logger

#   @base_url "http://export.arxiv.org/api/query"

#   @doc """
#   Search ArXiv for `keywords`. You can adjust timeouts here.
#   """
#   def search_papers(keywords, max_results \\ 20) do
#     query = build_query(keywords, max_results)

#     # Increase timeouts: 5s connect, 15s receive
#     opts = [timeout: 5_000, recv_timeout: 15_000]

#     case HTTPoison.get(query, [], opts) do
#       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
#         parse_arxiv_response(body)

#       {:ok, %HTTPoison.Response{status_code: status_code}} ->
#         {:error, "ArXiv API returned status code: #{status_code}"}

#       {:error, %HTTPoison.Error{reason: :timeout}} ->
#         {:error, "HTTP request timed out after #{opts[:recv_timeout]}ms"}

#       {:error, %HTTPoison.Error{reason: reason}} ->
#         {:error, "HTTP request failed: #{inspect(reason)}"}
#     end
#   end

#   defp build_query(keywords, max_results) do
#     formatted_keywords =
#       keywords
#       |> String.trim()
#       |> String.replace(~r/\s+/, " ")
#       |> URI.encode()

#     query_params = [
#       "search_query=all:\"#{formatted_keywords}\"",
#       "sortBy=submittedDate",
#       "sortOrder=descending",
#       "max_results=#{max_results}"
#     ]

#     "#{@base_url}?" <> Enum.join(query_params, "&")
#   end

#   defp parse_arxiv_response(xml_body) do
#     try do
#       papers =
#         xml_body
#         |> xpath(
#           ~x"//*[local-name() = 'entry']"l,
#           id: ~x"./*[local-name() = 'id']/text()"s,
#           title: ~x"./*[local-name() = 'title']/text()"s,
#           summary: ~x"./*[local-name() = 'summary']/text()"s,
#           authors: ~x"./*[local-name() = 'author']/*[local-name() = 'name']/text()"ls,
#           published: ~x"./*[local-name() = 'published']/text()"s,
#           updated: ~x"./*[local-name() = 'updated']/text()"s,
#           pdf_url: ~x"./*[local-name() = 'link'][@title='pdf']/@href"s,
#           abs_url: ~x"./*[local-name() = 'link'][@rel='alternate']/@href"s,
#           categories: ~x"./*[local-name() = 'category']/@term"ls,
#           primary_category: ~x"./*[local-name() = 'primary_category']/@term"s
#         )
#         |> Enum.map(&clean_paper/1)

#       {:ok, papers}
#     rescue
#       error ->
#         Logger.error("Failed to parse ArXiv XML: #{inspect(error)}")
#         {:error, "Failed to parse ArXiv response"}
#     end
#   end

#   defp clean_paper(paper) do
#     %{
#       id: extract_arxiv_id(paper.id),
#       title: String.trim(paper.title) |> String.replace(~r/\s+/, " "),
#       summary: String.trim(paper.summary) |> String.replace(~r/\s+/, " "),
#       authors: paper.authors |> Enum.map(&String.trim/1),
#       published: parse_date(paper.published),
#       updated: parse_date(paper.updated),
#       pdf_url: paper.pdf_url,
#       abstract_url: paper.abs_url,
#       categories: paper.categories,
#       primary_category: paper.primary_category
#     }
#   end

#   defp extract_arxiv_id(full_url) do
#     full_url
#     |> String.split("/")
#     |> List.last()
#     |> String.replace(~r/v\d+$/, "")
#   end

#   defp parse_date(date_string) do
#     case DateTime.from_iso8601(date_string) do
#       {:ok, datetime, _} -> datetime
#       {:error, _} -> nil
#     end
#   end
# end


defmodule ArxivExplorer.ArxivAPI do
  @moduledoc """
  Client for ArXiv API to fetch papers
  """

  import SweetXml
  require Logger

  @base_url "http://export.arxiv.org/api/query"

  def search_papers(keywords, max_results \\ 20) do
    query = build_query(keywords, max_results)

    Logger.info("Searching ArXiv with: #{query}")

    # ArXiv can be slow, so use longer timeouts
    options = [
      timeout: 60_000,        # 60 seconds for connection
      recv_timeout: 60_000,   # 60 seconds to receive response
      follow_redirect: true,
      hackney: [pool: false]  # Don't use connection pooling for reliability
    ]

    case HTTPoison.get(query, [], options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("✅ Successfully fetched #{byte_size(body)} bytes from ArXiv")
        parse_arxiv_response(body)
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("ArXiv API returned status #{status_code}: #{String.slice(body, 0, 200)}")
        {:error, "ArXiv API returned status code: #{status_code}"}
      {:error, %HTTPoison.Error{reason: :timeout}} ->
        Logger.error("Request timed out - ArXiv is taking longer than 60 seconds")
        {:error, "ArXiv is currently slow - please try again in a moment"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  defp build_query(keywords, max_results) do
    # Build URL exactly like the working browser version
    formatted_keywords = keywords
    |> String.trim()
    |> String.replace(~r/\s+/, " ")  # Normalize spaces

    # Create the search query with proper quotes and encoding
    search_query = "all:\"#{formatted_keywords}\""
    |> URI.encode_www_form()  # This will encode quotes as %22 and spaces as %20

    query_params = [
      "search_query=#{search_query}",
      "sortBy=submittedDate",
      "sortOrder=descending",
      "max_results=#{max_results}"
    ]

    full_url = "#{@base_url}?" <> Enum.join(query_params, "&")
    Logger.info("Built ArXiv URL: #{full_url}")
    full_url
  end

  defp parse_arxiv_response(xml_body) do
    try do
      papers = xml_body
      |> xpath(~x"//entry"l,
          id: ~x"./id/text()"s,
          title: ~x"./title/text()"s,
          summary: ~x"./summary/text()"s,
          authors: ~x"./author/name/text()"ls,
          published: ~x"./published/text()"s,
          updated: ~x"./updated/text()"s,
          pdf_url: ~x"./link[@title='pdf']/@href"s,
          abs_url: ~x"./link[@rel='alternate']/@href"s,
          categories: ~x"./category/@term"ls,
          primary_category: ~x"./arxiv:primary_category/@term"s |> add_namespace("arxiv", "http://arxiv.org/schemas/atom")
        )
      |> Enum.map(&clean_paper/1)
      |> Enum.reject(&is_nil/1)

      Logger.info("Successfully parsed #{length(papers)} papers")
      {:ok, papers}
    rescue
      error ->
        Logger.error("Failed to parse ArXiv XML: #{inspect(error)}")
        {:error, "Failed to parse ArXiv response"}
    end
  end

  defp clean_paper(paper) do
    try do
      %{
        id: extract_arxiv_id(paper.id),
        title: clean_text(paper.title),
        summary: clean_text(paper.summary),
        authors: paper.authors |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")),
        published: parse_date(paper.published),
        updated: parse_date(paper.updated),
        pdf_url: paper.pdf_url,
        abstract_url: paper.abs_url,
        categories: paper.categories,
        primary_category: paper.primary_category || "Unknown"
      }
    rescue
      _ -> nil
    end
  end

  defp clean_text(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
  defp clean_text(_), do: ""

  defp extract_arxiv_id(full_url) when is_binary(full_url) do
    full_url
    |> String.split("/")
    |> List.last()
    |> String.replace(~r/v\d+$/, "")
  end
  defp extract_arxiv_id(_), do: "unknown"

  defp parse_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> datetime
      {:error, _} -> nil
    end
  end
  defp parse_date(_), do: nil
end
