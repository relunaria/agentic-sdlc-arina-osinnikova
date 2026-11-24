# GAME-STORY-001: Create a new game

**Priority:** Core (Pareto 20%)
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§6.2 Game Initialization Flow](../../architecture/06-runtime-view.md)
- [§4.4 API Design](../../architecture/04-solution-strategy.md)
- [ADR-002 Modular Monolith](../../architecture/09-architecture-decisions.md)
- [ADR-003 Separate Frontend and Backend Deployment](../../architecture/09-architecture-decisions.md)
- [ADR-007 Board Persisted as JSON per Game Row](../../architecture/09-architecture-decisions.md)

---

## Original Story

AS A player
I WANT to start a new Minesweeper game by choosing a difficulty
SO THAT I get a fresh board sized for that difficulty and can begin playing

### SCENARIO 1: Successfully create a Beginner game

**Scenario ID:** GAME-STORY-001-S1

**GIVEN**
* the backend is running and reachable
* no game exists for the player yet

**WHEN**
* the player selects "Beginner" and confirms

**THEN**
* the frontend sends `POST /games` with body `{"difficulty": "Beginner"}`
* the backend returns HTTP 201
* the response body contains `status: "new"`, `difficulty: "Beginner"`, a non-empty `id`, and a board with 9 rows × 9 columns
* cells in the board contain only position and state; no `has_mine` or `adjacent` fields are present (§8.3, ADR-005)
* the frontend navigates to `/game/{id}` and renders a 9×9 grid with all cells unrevealed

### SCENARIO 2: Successfully create an Intermediate game

**Scenario ID:** GAME-STORY-001-S2

**GIVEN**
* the backend is running and reachable

**WHEN**
* the player selects "Intermediate" and confirms

**THEN**
* the frontend sends `POST /games` with body `{"difficulty": "Intermediate"}`
* the backend returns HTTP 201
* the response body contains `status: "new"`, `difficulty: "Intermediate"`, and a board with 16 rows × 16 columns
* the frontend renders a 16×16 grid with all cells unrevealed

### SCENARIO 3: Successfully create an Expert game

**Scenario ID:** GAME-STORY-001-S3

**GIVEN**
* the backend is running and reachable

**WHEN**
* the player selects "Expert" and confirms

**THEN**
* the frontend sends `POST /games` with body `{"difficulty": "Expert"}`
* the backend returns HTTP 201
* the response body contains `status: "new"`, `difficulty: "Expert"`, and a board with 16 rows × 30 columns
* the frontend renders a 16×30 grid with all cells unrevealed

### SCENARIO 4: Invalid difficulty value is rejected

**Scenario ID:** GAME-STORY-001-S4

**GIVEN**
* the backend is running and reachable

**WHEN**
* the frontend sends `POST /games` with body `{"difficulty": "Ultra"}`

**THEN**
* the backend returns HTTP 422
* the response body matches `{"detail": "<validation message>"}`
* no game row is written to the database

---

## INFRA Sub-Stories

### GAME-INFRA-001.1: Deploy backend Docker container with uvicorn and persistent SQLite volume

**Parent:** GAME-STORY-001
**Architecture references:**
- [§7.2 Runtime Environment](../../architecture/07-deployment-view.md)
- [§7.4 Deployment Scenarios](../../architecture/07-deployment-view.md)
- [ADR-001 Technology Stack](../../architecture/09-architecture-decisions.md)
- [ADR-003 Separate Frontend and Backend Deployment](../../architecture/09-architecture-decisions.md)

**Description:** The backend must run as a single Docker container serving FastAPI via uvicorn. A persistent volume is attached and `DATABASE_PATH` points to the SQLite file on that volume so game state survives container restarts.

#### SCENARIO 1: Backend container starts and serves requests

**Scenario ID:** GAME-INFRA-001.1-S1

**GIVEN**
* a Docker image is built from the backend source
* a persistent volume is mounted at the path referenced by `DATABASE_PATH`

**WHEN**
* the container starts

**THEN**
* uvicorn binds and accepts HTTP connections on the configured port
* `GET /health` returns HTTP 200 within 5 seconds of container start
* the SQLite file exists at `DATABASE_PATH` after the first request

#### SCENARIO 2: Game data survives a container restart

**Scenario ID:** GAME-INFRA-001.1-S2

**GIVEN**
* a game has been created (row exists in the SQLite file on the persistent volume)

**WHEN**
* the container is stopped and restarted

**THEN**
* `GET /games/{id}` for the previously created game returns HTTP 200 with the correct game state
* no data is lost

---

### GAME-INFRA-001.2: Deploy frontend static build with CORS configuration

**Parent:** GAME-STORY-001
**Architecture references:**
- [§7.2 Runtime Environment](../../architecture/07-deployment-view.md)
- [§7.4 Deployment Scenarios](../../architecture/07-deployment-view.md)
- [§8.7 Configuration](../../architecture/08-cross-cutting-concepts.md)
- [ADR-003 Separate Frontend and Backend Deployment](../../architecture/09-architecture-decisions.md)

**Description:** The React app is built to static assets and deployed to a static host (e.g., Netlify). The backend must have `CORS_ALLOWED_ORIGINS` set to the frontend's origin so the browser does not block API calls.

#### SCENARIO 1: Browser can call the backend from the deployed frontend origin

**Scenario ID:** GAME-INFRA-001.2-S1

**GIVEN**
* the frontend is deployed at `https://app.example.com`
* `CORS_ALLOWED_ORIGINS` is set to `https://app.example.com` on the backend

**WHEN**
* the browser sends a cross-origin `POST /games` request

**THEN**
* the backend response includes `Access-Control-Allow-Origin: https://app.example.com`
* the browser does not raise a CORS error
* the response body is accessible to the frontend JavaScript

#### SCENARIO 2: Request from an unlisted origin is blocked

**Scenario ID:** GAME-INFRA-001.2-S2

**GIVEN**
* `CORS_ALLOWED_ORIGINS` does not include `https://evil.example.com`

**WHEN**
* a cross-origin request arrives from `https://evil.example.com`

**THEN**
* the backend does not include `Access-Control-Allow-Origin` for that origin
* the browser blocks the response (CORS policy violation)

---

### GAME-INFRA-001.3: SQLite schema — games table

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§8.4 Domain Model & Serialization](../../architecture/08-cross-cutting-concepts.md)
- [ADR-007 Board Persisted as JSON per Game Row](../../architecture/09-architecture-decisions.md)

**Description:** The Persistence module must create a `games` table in SQLite with columns for `id`, `difficulty`, `status`, `created_at`, and `board` (JSON-serialized). The table is created on startup if it does not exist.

#### SCENARIO 1: Table is created on first startup

**Scenario ID:** GAME-INFRA-001.3-S1

**GIVEN**
* `DATABASE_PATH` points to a file that does not yet exist

**WHEN**
* the backend starts for the first time

**THEN**
* the SQLite file is created at `DATABASE_PATH`
* the `games` table exists with columns: `id TEXT PRIMARY KEY`, `difficulty TEXT`, `status TEXT`, `created_at TEXT`, `board TEXT`

#### SCENARIO 2: A new game row is persisted correctly

**Scenario ID:** GAME-INFRA-001.3-S2

**GIVEN**
* the `games` table exists

**WHEN**
* `POST /games` with `{"difficulty": "Beginner"}` is called

**THEN**
* exactly one row is inserted into `games`
* the row's `status` column equals `"new"`
* the row's `board` column is valid JSON representing a 9×9 grid with no mines placed

---

### GAME-INFRA-001.4: No event infrastructure required (synchronous REST)

**Parent:** GAME-STORY-001
**Architecture references:**
- [ADR-002 Modular Monolith](../../architecture/09-architecture-decisions.md)
- [§6.2 Game Initialization Flow](../../architecture/06-runtime-view.md)

**Description:** The architecture is a synchronous modular monolith with no message bus (ADR-002). Game creation is a direct in-process call from API Layer → Game Session → Board Management → Persistence. No queue, topic, or event infrastructure exists or is needed.

#### SCENARIO 1: Game creation completes synchronously within the request

**Scenario ID:** GAME-INFRA-001.4-S1

**GIVEN**
* the backend receives `POST /games`

**WHEN**
* the request is processed

**THEN**
* the response is returned in the same HTTP transaction
* no outbound message is published to any queue or topic
* the game row is readable in SQLite before the HTTP response reaches the client

---

### GAME-INFRA-001.5: Structured request logging and GET /health endpoint

**Parent:** GAME-STORY-001
**Architecture references:**
- [§8.6 Logging](../../architecture/08-cross-cutting-concepts.md)
- [§10.2 Quality Scenarios](../../architecture/10-quality-requirements.md)

**Description:** Every HTTP request is logged to stdout as a single structured line containing method, path, status code, and duration in milliseconds. A `GET /health` endpoint returns 200 so the deployment platform can verify liveness.

#### SCENARIO 1: POST /games produces a structured log line

**Scenario ID:** GAME-INFRA-001.5-S1

**GIVEN**
* the backend is running with logging enabled

**WHEN**
* `POST /games` with `{"difficulty": "Beginner"}` is called and returns 201

**THEN**
* stdout contains exactly one log line for this request
* the line includes `method=POST`, `path=/games`, `status=201`, and a `duration` value in milliseconds

#### SCENARIO 2: GET /health returns 200

**Scenario ID:** GAME-INFRA-001.5-S2

**GIVEN**
* the backend container is running

**WHEN**
* `GET /health` is called

**THEN**
* the response status is HTTP 200
* the response body is `{"status": "ok"}` or equivalent non-empty JSON

---

## BE Sub-Stories

### GAME-BE-001.1: POST /games endpoint — validate input and return 201 with initial game state

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§4.4 API Design](../../architecture/04-solution-strategy.md)
- [§6.2 Game Initialization Flow](../../architecture/06-runtime-view.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)
- [ADR-008 Error Mapping in API Layer](../../architecture/09-architecture-decisions.md)

**Description:** The `POST /games` FastAPI router validates the `difficulty` field, delegates to Game Session's `create_game()`, maps the returned `GameState` to a response DTO (no mine info), and returns HTTP 201.

#### SCENARIO 1: Valid difficulty returns 201 with DTO

**Scenario ID:** GAME-BE-001.1-S1

**GIVEN**
* the FastAPI router for `POST /games` is registered
* `Game Session.create_game` is callable

**WHEN**
* `POST /games` is called with `{"difficulty": "Beginner"}`

**THEN**
* the router calls `Game Session.create_game("Beginner")`
* the response status is 201
* the response body contains `id` (non-empty string), `difficulty: "Beginner"`, `status: "new"`, `board.rows: 9`, `board.cols: 9`
* cells in `board.cells` contain only position and state; no `has_mine` or `adjacent` fields are present (§8.3, ADR-005)

#### SCENARIO 2: Invalid difficulty returns 422

**Scenario ID:** GAME-BE-001.1-S2

**GIVEN**
* the FastAPI router for `POST /games` is registered

**WHEN**
* `POST /games` is called with `{"difficulty": "Ultra"}`

**THEN**
* the router returns HTTP 422
* the response body matches `{"detail": "<validation message>"}`
* `Game Session.create_game` is not called

---

### GAME-BE-001.2: Game Session — create_game() creates an empty board and persists it

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§6.2 Game Initialization Flow](../../architecture/06-runtime-view.md)
- [ADR-004 Mines Placed on First Reveal](../../architecture/09-architecture-decisions.md)

**Description:** `Game Session.create_game(difficulty)` calls `Board Management.create_empty(rows, cols)` to produce a mine-free board, constructs a `GameState` with `status="new"`, generates a UUID for `id`, and calls `Persistence.save(game)`.

#### SCENARIO 1: create_game("Beginner") produces correct GameState

**Scenario ID:** GAME-BE-001.2-S1

**GIVEN**
* `Board Management.create_empty` is available
* `Persistence.save` is available

**WHEN**
* `Game Session.create_game("Beginner")` is called

**THEN**
* the returned `GameState` has `status = "new"`
* `board.rows = 9`, `board.cols = 9`
* every cell in `board.cells` has `has_mine = False`
* `Persistence.save` is called exactly once with the new `GameState`
* the returned `id` is a non-empty string (UUID format)

#### SCENARIO 2: create_game("Expert") produces a 16×30 board

**Scenario ID:** GAME-BE-001.2-S2

**GIVEN**
* `Board Management.create_empty` is available

**WHEN**
* `Game Session.create_game("Expert")` is called

**THEN**
* the returned `GameState` has `board.rows = 16` and `board.cols = 30`
* `status = "new"`
* all 480 cells have `has_mine = False`

---

### GAME-BE-001.3: Board Management — create_empty() returns a mine-free grid

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

**Description:** `Board Management.create_empty(rows, cols)` is a pure function that returns a `Board` with the given dimensions and all cells in `hidden` state with `has_mine=False` and `adjacent=0`. It has no I/O.

#### SCENARIO 1: create_empty returns correct dimensions and cell defaults

**Scenario ID:** GAME-BE-001.3-S1

**GIVEN**
* no external dependencies (pure function)

**WHEN**
* `Board Management.create_empty(9, 9)` is called

**THEN**
* the returned `Board` has `rows = 9` and `cols = 9`
* `len(board.cells) = 81`
* every cell has `has_mine = False`, `adjacent = 0`, `state = "hidden"`

---

### GAME-BE-001.4: Persistence — save() writes a new game row to SQLite

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§8.4 Domain Model & Serialization](../../architecture/08-cross-cutting-concepts.md)
- [ADR-007 Board Persisted as JSON per Game Row](../../architecture/09-architecture-decisions.md)

**Description:** `Persistence.save(game)` serializes the `GameState` (including the board as JSON) and writes one row to the `games` table. `Persistence.load(id)` must return the identical `GameState` after a save.

#### SCENARIO 1: save then load round-trips the game state

**Scenario ID:** GAME-BE-001.4-S1

**GIVEN**
* a `GameState` with `id="abc"`, `difficulty="Beginner"`, `status="new"`, and a 9×9 empty board

**WHEN**
* `Persistence.save(game)` is called, then `Persistence.load("abc")` is called

**THEN**
* the loaded `GameState` has `id = "abc"`, `difficulty = "Beginner"`, `status = "new"`
* `board.rows = 9`, `board.cols = 9`
* all 81 cells have `has_mine = False`, `state = "hidden"`

#### SCENARIO 2: load() returns None for an unknown id

**Scenario ID:** GAME-BE-001.4-S2

**GIVEN**
* the `games` table is empty

**WHEN**
* `Persistence.load("unknown-id")` is called

**THEN**
* the return value is `None`
* no exception is raised

---

## FE Sub-Stories

### GAME-FE-001.1: Difficulty selection screen

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.2 API Layer — POST /games](../../architecture/05-building-block-view.md)
- [§1.1 Requirements Overview — difficulty presets](../../architecture/01-introduction-and-goals.md)
- [ADR-003 Separate Frontend and Backend Deployment](../../architecture/09-architecture-decisions.md)

**Description:** A `DifficultySelector` component renders three buttons (Beginner, Intermediate, Expert). On selection it calls `POST /games`, receives the 201 response, and navigates the browser to `/game/{id}`.

#### SCENARIO 1: Player selects Beginner and is navigated to the game

**Scenario ID:** GAME-FE-001.1-S1

**GIVEN**
* the `DifficultySelector` component is rendered
* the backend returns HTTP 201 with a valid game state including `id = "game-123"`

**WHEN**
* the player clicks the "Beginner" button

**THEN**
* the `DifficultySelector` calls `POST /games` with `{"difficulty": "Beginner"}`
* the browser URL changes to `/game/game-123`
* the difficulty selector is no longer visible

#### SCENARIO 2: API error during game creation shows an inline error message

**Scenario ID:** GAME-FE-001.1-S2

**GIVEN**
* the `DifficultySelector` component is rendered
* the backend returns HTTP 422

**WHEN**
* the player clicks any difficulty button

**THEN**
* an error message is visible in the `DifficultySelector` component
* the browser URL does not change
* the three difficulty buttons remain visible and enabled

---

### GAME-FE-001.2: Board rendering — initial empty grid

**Parent:** GAME-STORY-001
**Architecture references:**
- [§5.2 API Layer — POST /games response](../../architecture/05-building-block-view.md)
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)

**Description:** A `Board` component receives the game state from the API response and renders a grid of `Cell` components. On initial load (status `new`) all cells are rendered as unrevealed with no numbers or mine indicators.

#### SCENARIO 1: 9×9 grid renders with all cells unrevealed

**Scenario ID:** GAME-FE-001.2-S1

**GIVEN**
* the `Board` component receives a game state with `board.rows = 9`, `board.cols = 9`, all cells `state = "hidden"`

**WHEN**
* the component renders

**THEN**
* exactly 81 `Cell` elements are present in the DOM
* no cell displays a number or a mine icon
* all cells have an interactive (clickable) appearance

#### SCENARIO 2: 16×30 Expert grid renders with correct cell count

**Scenario ID:** GAME-FE-001.2-S2

**GIVEN**
* the `Board` component receives a game state with `board.rows = 16`, `board.cols = 30`

**WHEN**
* the component renders

**THEN**
* exactly 480 `Cell` elements are present in the DOM
* the grid layout has 30 cells per row and 16 rows

---

## Implementation Order

1. **GAME-INFRA-001.1** — Docker container + persistent volume + DATABASE_PATH
2. **GAME-INFRA-001.3** — SQLite `games` table schema
3. **GAME-INFRA-001.2** — CORS configuration + frontend static build pipeline
4. **GAME-INFRA-001.4** — Confirm no event infrastructure needed
5. **GAME-INFRA-001.5** — `GET /health` endpoint + structured request logging
6. **GAME-BE-001.3** — `Board Management.create_empty()` (pure function, unit-testable immediately)
7. **GAME-BE-001.4** — `Persistence.save()` / `load()` (depends on schema from INFRA-001.3)
8. **GAME-BE-001.2** — `Game Session.create_game()` (depends on BE-001.3 + BE-001.4)
9. **GAME-BE-001.1** — `POST /games` router + DTO mapping (depends on BE-001.2)
10. **GAME-FE-001.1** — `DifficultySelector` component (depends on BE-001.1)
11. **GAME-FE-001.2** — `Board` component initial render (depends on FE-001.1)
12. **GAME-STORY-001 E2E** — Full flow: select difficulty → POST /games → navigate → board visible
