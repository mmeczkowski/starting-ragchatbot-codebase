# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key Requirements

- Always use `uv` to run Python scripts or the server — never use `python`, `python3`, or `pip` directly.
- Install packages with `uv add <package>`, run scripts with `uv run <script>`.

## Running the Application

Set these env vars once in `~/.zshrc` (required — workspace is a 9P mount):
```bash
export UV_PROJECT_ENVIRONMENT="$HOME/.venv"
export UV_LINK_MODE=copy
```

```bash
# Install dependencies into native venv at ~/.venv
uv sync

# Start the server (from project root)
./run.sh

# Or manually (from project root)
cd backend && uv run uvicorn app:app --reload --port 8000 --host ::
```

The venv lives at `~/.venv`, outside the project root. `run.sh` exports the uv vars itself so it works without sourcing `.zshrc` first.

App serves at `http://localhost:8000`. API docs at `http://localhost:8000/docs`.

**Required**: Create a `.env` file in the root with `ANTHROPIC_API_KEY=your-key`.

## Architecture Overview

This is a full-stack RAG (Retrieval-Augmented Generation) system for querying course materials. The backend is a FastAPI app that serves the frontend as static files.

**Request flow**: Frontend → `POST /api/query` → `RAGSystem.query()` → Claude API with tool use → `search_course_content` tool → ChromaDB → response

### Backend Components (`backend/`)

- **`app.py`** — FastAPI entrypoint. On startup loads all `.txt`/`.pdf`/`.docx` files from `../docs/` into ChromaDB. Serves the frontend from `../frontend/`.
- **`rag_system.py`** — Central orchestrator (`RAGSystem`). Wires together all components and is the only class that talks to all the others.
- **`ai_generator.py`** — Wraps the Anthropic SDK. Sends queries to Claude with tool definitions; handles the two-turn tool-use loop (query → tool_use stop → execute tool → final response).
- **`search_tools.py`** — Defines `CourseSearchTool` (the Claude tool) and `ToolManager` (registry). The tool definition is sent to Claude; Claude decides when to call it.
- **`vector_store.py`** — ChromaDB wrapper with two collections: `course_catalog` (course title/metadata) and `course_content` (chunked text). Course name resolution uses semantic search on `course_catalog` before filtering `course_content`.
- **`document_processor.py`** — Parses course `.txt` files into `Course`/`Lesson`/`CourseChunk` objects, then splits content into overlapping sentence-based chunks.
- **`session_manager.py`** — In-memory session store; keeps a rolling window of the last `MAX_HISTORY` (default: 2) exchanges per session.
- **`config.py`** — Single `Config` dataclass loaded from `.env`. Key settings: `ANTHROPIC_MODEL`, `EMBEDDING_MODEL` (`all-MiniLM-L6-v2`), `CHUNK_SIZE` (800), `CHUNK_OVERLAP` (100), `MAX_RESULTS` (5).
- **`models.py`** — Pydantic models: `Course`, `Lesson`, `CourseChunk`.

### Course Document Format (`docs/`)

Text files must follow this structure for the parser to extract metadata:
```
Course Title: <title>
Course Link: <url>
Course Instructor: <name>

Lesson 1: <title>
Lesson Link: <url>
<lesson content>

Lesson 2: <title>
...
```

Course `title` is used as the unique ID in ChromaDB — duplicate titles are skipped on re-load.

### Frontend (`frontend/`)

Vanilla HTML/CSS/JS. Communicates with the backend via `POST /api/query` and `GET /api/courses`. Session ID is maintained client-side and sent with each request.
