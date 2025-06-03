defmodule ArxivExplorer.LLM.Server do
  use GenServer
  require Logger

  # We'll keep using T5-small (it has a Rust tokenizer included).
  @model_name "t5-small"

  # Truncate abstracts to 1000 characters to ensure tokenized length < 1024 tokens
  @max_abstract_chars 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    Logger.info("▶️  Starting LLM Server with Bumblebee 0.6.0 (#{@model_name})…")
    send(self(), :load_model)
    {:ok, %{serving: nil, status: :loading}}
  end

  @impl true
  def handle_info(:load_model, state) do
    Logger.info("📥 Downloading T5-small model/tokenizer/config from Hugging Face…")

    try do
      # 1) Force EXLA backend (CUDA if available, else CPU)
      Application.put_env(:nx, :default_backend, EXLA.Backend)
      System.put_env("XLA_PYTHON_CLIENT_MEM_FRACTION", "0.4")

      # 2) Load T5-small model_info and tokenizer (Rust tokenizer included)
      {:ok, model_info} = Bumblebee.load_model({:hf, @model_name})
      {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @model_name})
      {:ok, generation_config} = Bumblebee.load_generation_config({:hf, @model_name})

      # 3) Configure generation for T5 properly - remove min_new_tokens to fix arithmetic error
      generation_config = %Bumblebee.Text.GenerationConfig{
        generation_config |
        max_new_tokens: 80,
        temperature: 0.7
      }

      # 4) Use generation/4 with simpler compile options for T5
      serving = Bumblebee.Text.generation(
        model_info,
        tokenizer,
        generation_config,
        compile: [batch_size: 1, sequence_length: 512],
        defn_options: [compiler: EXLA]
      )

      Logger.info("✅ T5-small is ready for summarization!")
      {:noreply, %{state | serving: serving, status: :ready}}
    rescue
      error ->
        Logger.error("❌ Failed to load T5-small: #{inspect(error)}")
        {:noreply, %{state | status: :failed}}
    end
  end

  @doc """
  Public API: summarize or extract keywords from a given `paper`.

  - If `analysis_type == :summary`, we feed "summarize: " plus a truncated abstract.
  - If `analysis_type == :keywords`, we feed "extract keywords: " plus title + truncated abstract.
  """
  def analyze_paper(paper, analysis_type) do
    GenServer.call(__MODULE__, {:analyze, paper, analysis_type}, 60_000)
  end

  @impl true
  # If loading failed, immediately return an error
  def handle_call({:analyze, _paper, _type}, _from, %{status: :failed} = state) do
    {:reply, {:error, "LLM model failed to load"}, state}
  end

  @impl true
  # If still loading, inform the caller
  def handle_call({:analyze, _paper, _type}, _from, %{status: :loading} = state) do
    {:reply, {:error, "LLM still loading, please try again shortly"}, state}
  end

  @impl true
  # When model is ready, run generation
  def handle_call({:analyze, paper, analysis_type}, _from, %{status: :ready, serving: serving} = state) do
    try do
      # 1) Truncate the abstract to 1000 characters
      truncated_abstract = truncate(paper.summary, @max_abstract_chars)

      # 2) Build the prompt (summary or keywords) using the truncated abstract
      prompt = build_prompt(paper.title, truncated_abstract, analysis_type)

      # Debug logging
      Logger.debug("Prompt: #{inspect(prompt)}")
      Logger.debug("Prompt length: #{String.length(prompt)}")

      # 3) Run the Nx.Serving with proper input validation
      # Ensure prompt is valid before running inference
      if String.trim(prompt) == "" do
        raise ArgumentError, "Empty prompt"
      end

      result = Nx.Serving.run(serving, prompt)

      Logger.debug("Raw result: #{inspect(result)}")

      # 4) Extract and clean the output
      response = case result do
        %{results: [%{text: generated_text} | _]} ->
          clean_response(generated_text, prompt)
        %{text: generated_text} ->
          clean_response(generated_text, prompt)
        other ->
          Logger.error("Unexpected result format: #{inspect(other)}")
          "Generation failed"
      end

      {:reply, {:ok, response}, state}
    rescue
      error ->
        Logger.error("❌ Inference failed: #{inspect(error)}")
        Logger.error("Error module: #{error.__struct__}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
        fallback = fallback_analysis(paper, analysis_type)
        {:reply, {:ok, fallback}, state}
    end
  end

  # Helper to truncate a string to at most `n` characters without splitting codepoints
  defp truncate(string, n) when is_binary(string) and byte_size(string) > n do
    string
    |> String.slice(0, n)
    |> String.trim_trailing()
  end

  defp truncate(string, _n), do: string

  # Build the input for T5 based on summary vs. keywords
  defp build_prompt(_title, truncated_abstract, :summary) do
    # T5 summarization convention: prefix "summarize: "
    # Fix: Ensure the abstract is not empty to avoid tensor shape issues
    abstract = if String.trim(truncated_abstract) == "", do: "research paper", else: truncated_abstract
    "summarize: #{abstract}"
  end

  defp build_prompt(title, truncated_abstract, :keywords) do
    # Alternative: Use T5's question-answering format
    content = String.trim("#{title} #{truncated_abstract}")
    content = if content == "", do: "research paper", else: content
    "question: What are the main topics? context: #{content}"
  end

  # Remove the prompt, split at newline, take the first line, and limit to 500 chars
  defp clean_response(generated_text, prompt) do
    generated_text
    |> String.replace(prompt, "")
    |> String.trim()
    |> String.split("\n")
    |> List.first()
    |> case do
      nil -> "No response generated"
      "" -> "Empty response"
      x -> String.slice(x, 0, 500)
    end
  end

  # Fallback if summarization fails: first two sentences of the full abstract
  defp fallback_analysis(paper, :summary) do
    paper.summary
    |> String.split(~r/[.!?]+/)
    |> Enum.filter(&(&1 != ""))
    |> Enum.take(2)
    |> Enum.join(". ")
    |> case do
      "" -> "No summary available"
      s -> s <> "."
    end
  end

  # Fallback if keyword extraction fails: take 5–7 longest words from title + full abstract
  defp fallback_analysis(paper, :keywords) do
    tokens =
      (paper.title <> " " <> paper.summary)
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s]/, " ")
      |> String.split()

    tokens
    |> Enum.uniq()
    |> Enum.filter(fn w -> String.length(w) > 4 end)
    |> Enum.take(7)
    |> Enum.join(", ")
    |> case do
      "" -> "machine learning, research, analysis"
      kws -> kws
    end
  end
end
