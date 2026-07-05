# Query Flow Diagram: Frontend to Backend

## Complete Request-Response Cycle

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                   FRONTEND (Browser)                                 │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ User Types: "How do I solve quadratic equations?"                            │   │
│  │ [Send Button]                                                                │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│                           sendMessage() (script.js)                                 │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ POST /api/query                                                              │   │
│  │ {                                                                            │   │
│  │   query: "How do I solve quadratic equations?",                             │   │
│  │   session_id: "abc123"                                                       │   │
│  │ }                                                                            │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
                          🌐 HTTP Request (JSON)
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND (FastAPI)                                      │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ @app.post("/api/query")                                                      │   │
│  │ query_documents(request: QueryRequest)                                       │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ 1. Check/Create Session                                                      │   │
│  │    session_id = session_manager.create_session() or retrieve existing        │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ 2. Call RAGSystem.query()                                                    │   │
│  │    answer, sources = rag_system.query(query, session_id)                    │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         RAG SYSTEM ORCHESTRATION                                    │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ RAGSystem.query()                                                            │   │
│  │                                                                              │   │
│  │ • Get conversation history from session_manager                             │   │
│  │   history = session_manager.get_conversation_history(session_id)            │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Call AIGenerator.generate_response()                                         │   │
│  │   response = ai_generator.generate_response(                                │   │
│  │       query="How do I solve quadratic equations?",                          │   │
│  │       conversation_history=history,                                         │   │
│  │       tools=[CourseSearchTool],                                             │   │
│  │       tool_manager=tool_manager                                             │   │
│  │   )                                                                          │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         AI GENERATOR & CLAUDE API                                   │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ AIGenerator.generate_response()                                              │   │
│  │                                                                              │   │
│  │ Build API call:                                                              │   │
│  │ • model: "claude-sonnet-4-20250514"                                         │   │
│  │ • system: SYSTEM_PROMPT + conversation_history                             │   │
│  │ • messages: [user query]                                                    │   │
│  │ • tools: [CourseSearchTool definition]                                      │   │
│  │ • tool_choice: "auto"  ← Let Claude decide                                 │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│                        anthropic.Anthropic().messages.create()                     │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Claude Analysis:                                                             │   │
│  │ "This is a course-specific question about quadratic equations.              │   │
│  │  I should search the course materials first."                               │   │
│  │                                                                              │   │
│  │ Response includes: tool_use block with CourseSearchTool                    │   │
│  │ stop_reason: "tool_use"  ← Indicates tool will be called                  │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ _handle_tool_execution()                                                     │   │
│  │ Tool call detected!                                                          │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        TOOL EXECUTION: VECTOR SEARCH                                │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ CourseSearchTool.execute()                                                   │   │
│  │                                                                              │   │
│  │ Input: {"query": "How do I solve quadratic equations?"}                      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 1: Convert Query to Vector (Embedding)                                │   │
│  │                                                                              │   │
│  │   Sentence Transformer (all-MiniLM-L6-v2)                                   │   │
│  │   "How do I solve quadratic equations?"                                      │   │
│  │        ↓                                                                    │   │
│  │   [0.25, -0.48, 0.82, 0.15, -0.33, 0.71, 0.09, ... 384 more numbers]    │   │
│  │                                                                              │   │
│  │   ← This vector represents the MEANING of the question                      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 2: Search ChromaDB for Similar Vectors                                │   │
│  │                                                                              │   │
│  │   Query vector: [0.25, -0.48, 0.82, ...]                                   │   │
│  │        ↓                                                                    │   │
│  │   ChromaDB: "Which stored vectors are closest to this?"                     │   │
│  │        ↓                                                                    │   │
│  │   Cosine similarity search: Find top 5 similar vectors                      │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 3: Retrieve Top 5 Matching Chunks                                     │   │
│  │                                                                              │   │
│  │ ✓ Match 1 (similarity: 0.92):                                               │   │
│  │   "Lesson 3: Quadratic Formula. To solve ax² + bx + c = 0,                 │   │
│  │    use x = (-b ± √(b² - 4ac)) / 2a"                                        │   │
│  │                                                                              │   │
│  │ ✓ Match 2 (similarity: 0.88):                                               │   │
│  │   "The discriminant (b² - 4ac) tells you how many real solutions..."        │   │
│  │                                                                              │   │
│  │ ✓ Match 3 (similarity: 0.85):                                               │   │
│  │   "Factoring Method: Break the equation into (x-r)(x-s) = 0"                │   │
│  │                                                                              │   │
│  │ ✓ Match 4 (similarity: 0.83):                                               │   │
│  │   "Completing the Square: Rewrite as (x + p)² = q"                          │   │
│  │                                                                              │   │
│  │ ✓ Match 5 (similarity: 0.81):                                               │   │
│  │   "Graphing Method: Find where the parabola crosses the x-axis"             │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 4: Return Search Results to Claude                                    │   │
│  │                                                                              │   │
│  │ tool_result = [                                                              │   │
│  │   "Lesson 3: Quadratic Formula...",                                         │   │
│  │   "The discriminant tells you...",                                          │   │
│  │   "Factoring Method: ...",                                                  │   │
│  │   "Completing the Square: ...",                                             │   │
│  │   "Graphing Method: ..."                                                    │   │
│  │ ]                                                                            │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    CLAUDE SYNTHESIZES FINAL ANSWER                                  │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Claude.messages.create() [SECOND CALL]                                      │   │
│  │                                                                              │   │
│  │ Messages:                                                                    │   │
│  │ 1. [User]: "How do I solve quadratic equations?"                            │   │
│  │ 2. [Assistant]: (tool use request)                                          │   │
│  │ 3. [User]: Tool results: [5 matching course chunks]                         │   │
│  │                                                                              │   │
│  │ → Claude reads all 5 search results and synthesizes answer                  │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                              │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Final Answer:                                                                │   │
│  │                                                                              │   │
│  │ "There are several methods to solve quadratic equations:                     │   │
│  │                                                                              │   │
│  │ 1. **Quadratic Formula**: For ax² + bx + c = 0, use:                       │   │
│  │    x = (-b ± √(b² - 4ac)) / 2a                                             │   │
│  │                                                                              │   │
│  │ 2. **Factoring**: Break into (x - r)(x - s) = 0                             │   │
│  │                                                                              │   │
│  │ 3. **Completing the Square**: Rewrite as (x + p)² = q                       │   │
│  │                                                                              │   │
│  │ 4. **Graphing**: Find where the parabola crosses the x-axis                 │   │
│  │                                                                              │   │
│  │ The discriminant (b² - 4ac) tells you how many real solutions exist."       │   │
│  │                                                                              │   │
│  │ Sources: [5 matched lessons from course materials]                          │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Update Conversation History                                                 │   │
│  │ session_manager.add_exchange(session_id, query, response)                  │   │
│  │                                                                              │   │
│  │ ← Session now remembers this exchange for future queries                   │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                      RESPONSE SENT BACK TO FRONTEND                                 │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ QueryResponse (JSON):                                                        │   │
│  │ {                                                                            │   │
│  │   "answer": "There are several methods to solve quadratic equations...",    │   │
│  │   "sources": [                                                               │   │
│  │     "Lesson 3: Quadratic Formula. To solve ax² + bx + c = 0...",           │   │
│  │     "The discriminant (b² - 4ac) tells you...",                            │   │
│  │     "Factoring Method: Break the equation...",                             │   │
│  │     "Completing the Square: Rewrite as...",                                │   │
│  │     "Graphing Method: Find where the parabola..."                          │   │
│  │   ],                                                                         │   │
│  │   "session_id": "abc123"                                                     │   │
│  │ }                                                                            │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                      ↓
                          🌐 HTTP Response (JSON)
                                      ↓
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            FRONTEND DISPLAYS RESULT                                 │
│                                                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐   │
│  │ Chat Window:                                                                 │   │
│  │                                                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐    │   │
│  │  │ User: How do I solve quadratic equations?                           │    │   │
│  │  └─────────────────────────────────────────────────────────────────────┘    │   │
│  │                                                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────────────┐    │   │
│  │  │ Assistant: There are several methods to solve quadratic equations:  │    │   │
│  │  │                                                                     │    │   │
│  │  │ 1. **Quadratic Formula**: For ax² + bx + c = 0, use:              │    │   │
│  │  │    x = (-b ± √(b² - 4ac)) / 2a                                    │    │   │
│  │  │                                                                     │    │   │
│  │  │ 2. **Factoring**: Break into (x - r)(x - s) = 0                   │    │   │
│  │  │ 3. **Completing the Square**: Rewrite as (x + p)² = q             │    │   │
│  │  │ 4. **Graphing**: Find where the parabola crosses x-axis           │    │   │
│  │  │                                                                     │    │   │
│  │  │ The discriminant (b² - 4ac) tells you how many solutions exist.  │    │   │
│  │  │                                                                     │    │   │
│  │  │ <Details>                                                           │    │   │
│  │  │   Sources                                                           │    │   │
│  │  │   ├─ Lesson 3: Quadratic Formula. To solve ax² + bx + c = 0...  │    │   │
│  │  │   ├─ The discriminant (b² - 4ac) tells you...                    │    │   │
│  │  │   ├─ Factoring Method: Break the equation...                     │    │   │
│  │  │   ├─ Completing the Square: Rewrite as...                        │    │   │
│  │  │   └─ Graphing Method: Find where the parabola...                 │    │   │
│  │  │ </Details>                                                          │    │   │
│  │  └─────────────────────────────────────────────────────────────────────┘    │   │
│  │                                                                              │   │
│  │  [Chat input ready for next question...]                                   │   │
│  └──────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Side-by-Side: Two Query Paths

### Path A: General Knowledge Question
```
User: "What is photosynthesis?"
           ↓
Claude Analysis: "This is general knowledge, no search needed"
           ↓
Claude: Returns answer directly (no tool call)
           ↓
Response: Answer sent immediately
```

### Path B: Course-Specific Question (Actual Flow)
```
User: "How do I solve quadratic equations?"
           ↓
Claude Analysis: "This is course-specific, I should search"
           ↓
Claude: Calls CourseSearchTool
           ↓
Tool: Converts query → vector → searches ChromaDB → returns 5 results
           ↓
Claude: Reads search results + synthesizes answer
           ↓
Response: Answer + sources sent
```

---

## Data Flow Within ChromaDB Search

```
Query Text
    ↓
┌─────────────────────────────────────┐
│  Sentence Transformer Embedding      │
│  (all-MiniLM-L6-v2)                 │
│                                      │
│  Input:  "How do I solve quadratic  │
│           equations?"               │
│                                      │
│  Output: [0.25, -0.48, 0.82, ...]   │
│          (384-dimensional vector)   │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  ChromaDB Vector Index               │
│                                      │
│  Find similar vectors using:         │
│  • Cosine Similarity                 │
│  • Approximate Nearest Neighbor      │
│                                      │
│  (Very fast: ~milliseconds)          │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  Return Top 5 Chunks                 │
│                                      │
│  ✓ Vector: [0.24, -0.49, 0.81, ...] │
│    Text: "Lesson 3: Quadratic..."    │
│    Score: 0.92                       │
│                                      │
│  ✓ Vector: [0.26, -0.47, 0.83, ...] │
│    Text: "The discriminant..."       │
│    Score: 0.88                       │
│                                      │
│  ✓ (3 more matches)                  │
└─────────────────────────────────────┘
    ↓
Return to Claude for synthesis
```

---

## Component Interaction Map

```
┌────────────┐
│ Frontend   │──→ HTTP POST /api/query
└────────────┘
     ↑
     │ HTTP Response
     │
┌────────────────────────────────────────┐
│         FastAPI (app.py)               │
├────────────────────────────────────────┤
│                                        │
│  RAGSystem                             │
│  ├─ SessionManager                     │
│  ├─ AIGenerator ────→ Claude API       │
│  ├─ ToolManager                        │
│  │  └─ CourseSearchTool                │
│  └─ VectorStore (ChromaDB)             │
│     ├─ DocumentProcessor               │
│     └─ Embeddings (Sentence Transformer)
│                                        │
└────────────────────────────────────────┘
```

Does this help visualize the entire flow?
