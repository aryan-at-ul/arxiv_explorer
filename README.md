# ArXiv Explorer

A Phoenix LiveView application for exploring ArXiv research papers with AI-powered analysis.

## Features

🔍 **Smart Paper Search**
- Search ArXiv papers by keywords
- Real-time results from ArXiv API
- Sort by submission date (newest first)

🤖 **AI-Powered Analysis**
- LLM-generated summaries of research papers
- Automatic keyword extraction
- Intelligent fallback for when LLM is unavailable

📚 **Rich Paper Information**
- Full paper metadata (authors, categories, dates)
- Direct links to PDF downloads
- Links to ArXiv abstract pages
- Clean, responsive interface

## Quick Start

```bash
# 1. Run the setup script
python3 setup_arxiv_explorer.py

# 2. Navigate to project
cd arxiv_explorer

# 3. Install dependencies
mix deps.get
mix assets.setup

# 4. Start the server
mix phx.server
```

Visit http://localhost:4000 and start exploring!

## Usage

1. **Search Papers**: Enter keywords like "machine learning", "neural networks", "computer vision"
2. **Browse Results**: View paper titles, abstracts, authors, and metadata
3. **AI Analysis**: Click "AI Summary" or "Extract Keywords" for LLM insights
4. **Access Papers**: Download PDFs or view full abstracts on ArXiv

## Architecture

- **Frontend**: Phoenix LiveView with Tailwind CSS
- **ArXiv Integration**: HTTP client with XML parsing
- **LLM Processing**: Bumblebee with EXLA acceleration
- **Fallback Analysis**: Rule-based analysis when LLM unavailable

## Dependencies

- Elixir 1.14+
- Phoenix 1.7+
- Bumblebee for LLM processing
- HTTPoison for ArXiv API calls
- SweetXML for parsing ArXiv responses

## Configuration

The app automatically:
- Tries GPU acceleration (EXLA) if available
- Falls back to CPU processing if needed
- Uses intelligent rule-based analysis as fallback
- Handles ArXiv API rate limiting gracefully

Built with ❤️ using Phoenix LiveView and Elixir
