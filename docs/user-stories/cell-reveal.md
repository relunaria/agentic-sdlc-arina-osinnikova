# REVEAL-STORY-001: Reveal a cell (first click — safe)

**Priority:** Core (Pareto 20%)
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§6.3 First Reveal Flow](../../architecture/06-runtime-view.md)
- [§4.4 API Design](../../architecture/04-solution-strategy.md)
- [ADR-004 Mines Placed on First Reveal](../../architecture/09-architecture-decisions.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

---

## Original Story

AS A player
I WANT to click a cell on a brand-new board
SO THAT mines are placed away from that cell, the cell (and any empty flood-fill area) is revealed, and I am never killed on my first move

### SCENARIO 1: First click reveals the cell and transitions status to in_progress

**Scenario ID:** REVEAL-STORY-001-S1

**GIVEN**
* a game exists with `status = "new"` and a 9×9 empty board (Beginner)
* the player has not yet revealed any cell

**WHEN**
* the player clicks cell at row 4, col 4
* the frontend sends `POST /games/{id}/reveal` with `{"row": 4, "col": 4}`

**THEN**
* the backend returns HTTP 200
* the response body contains `status: "in_progress"` (not `"lost"`, confirming the clicked cell was not a mine)
* cell (4, 4) in the response has `state: "revealed"` and an `adjacent` integer value
* the frontend re-renders the board showing at least one revealed cell

### SCENARIO 2: First click on an empty cell triggers flood-fill — multiple cells revealed

**Scenario ID:** REVEAL-STORY-001-S2

**GIVEN**
* a game exists with `status = "new"` (Beginner, 9×9, 10 mines)
* the clicked cell and all its neighbours have no adjacent mines (empty area)

**WHEN**
* the frontend sends `POST /games/{id}/reveal` with the coordinates of that empty cell

**THEN**
* the backend returns HTTP 200 with `status: "in_progress"` (not `"lost"`, confirming no mine was hit)
* more than one cell in the response has `state: "revealed"`
* the frontier cells bordering the empty area show their correct `adjacent` count (integer ≥ 1)

### SCENARIO 3: Reveal on an already-finished game returns 409

**Scenario ID:** REVEAL-STORY-001-S3

**GIVEN**
* a game exists with `status = "won"` or `status = "lost"`

**WHEN**
* the frontend sends `POST /games/{id}/reveal` with any valid coordinates

**THEN**
* the backend returns HTTP 409
* the response body is `{"detail": "Game already finished"}`
* no game state change occurs in the database

### SCENARIO 4: Reveal with out-of-bounds coordinates returns 422

**Scenario ID:** REVEAL-STORY-001-S4

**GIVEN**
* a game exists with `status = "new"` and a 9×9 board

**WHEN**
* the frontend sends `POST /games/{id}/reveal` with `{"row": 9, "col": 9}` (0-indexed, out of bounds)

**THEN**
* the backend returns HTTP 422
* the response body matches `{"detail": "Invalid coordinates"}`
* no game state change occurs in the database

### SCENARIO 5: Reveal on an unknown game id returns 404

**Scenario ID:** REVEAL-STORY-001-S5

**GIVEN**
* no game exists with id `"nonexistent-id"`

**WHEN**
* the frontend sends `POST /games/nonexistent-id/reveal` with `{"row": 0, "col": 0}`

**THEN**
* the backend returns HTTP 404
* the response body is `{"detail": "Game not found"}`

---

## INFRA Sub-Stories

### REVEAL-INFRA-001.1: Deployment — no new deployment changes required

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [GAME-INFRA-001.1](./game-creation.md)
- [§7.2 Runtime Environment](../../architecture/07-deployment-view.md)

**Description:** The backend container, persistent volume, and CORS configuration were fully established in GAME-INFRA-001.1 and GAME-INFRA-001.2. The reveal endpoint is served by the same running container with no deployment changes.

#### SCENARIO 1: Reveal endpoint is reachable on the existing deployment

**Scenario ID:** REVEAL-INFRA-001.1-S1

**GIVEN**
* the backend container deployed in GAME-INFRA-001.1 is running

**WHEN**
* `POST /games/{id}/reveal` is called with valid coordinates on a `"new"` game

**THEN**
* the backend returns HTTP 200 without any redeployment or configuration change

---

### REVEAL-INFRA-001.2: Data store — Persistence.save() persists updated board after first reveal

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§8.4 Domain Model & Serialization](../../architecture/08-cross-cutting-concepts.md)
- [ADR-007 Board Persisted as JSON per Game Row](../../architecture/09-architecture-decisions.md)
- [GAME-INFRA-001.3](./game-creation.md)

**Description:** After the first reveal the game's `status` changes from `"new"` to `"in_progress"` and the board now contains mine positions and adjacent counts. `Persistence.save()` (established in GAME-INFRA-001.3) must overwrite the existing row with the updated board JSON. No schema change is needed.

#### SCENARIO 1: Updated game state is persisted after first reveal

**Scenario ID:** REVEAL-INFRA-001.2-S1

**GIVEN**
* a game row exists in the `games` table with `status = "new"` and an empty board JSON

**WHEN**
* `POST /games/{id}/reveal` is processed successfully

**THEN**
* the `games` row for that `id` has `status = "in_progress"`
* the `board` column JSON contains mine positions (at least one cell with `has_mine = true`)
* the `board` column JSON contains `adjacent` counts for cells neighbouring mines
* the previously clicked cell has `state = "revealed"` in the stored JSON

---

### REVEAL-INFRA-001.3: No event infrastructure required (synchronous REST)

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [ADR-002 Modular Monolith](../../architecture/09-architecture-decisions.md)
- [§6.3 First Reveal Flow](../../architecture/06-runtime-view.md)

**Description:** The first-reveal flow is a synchronous in-process call chain: API Layer → Game Session → Board Management (mine placement) → Game Engine (reveal + flood fill) → Persistence. No message bus exists (ADR-002). This sub-story confirms no event infrastructure is introduced.

#### SCENARIO 1: First reveal completes synchronously within the HTTP request

**Scenario ID:** REVEAL-INFRA-001.3-S1

**GIVEN**
* the backend receives `POST /games/{id}/reveal` for a `"new"` game

**WHEN**
* the request is processed

**THEN**
* the HTTP response is returned in the same transaction
* mine placement, flood fill, and persistence all complete before the response is sent
* no outbound message is published to any queue or topic

---

### REVEAL-INFRA-001.4: Monitoring — reveal endpoint logged and meets 200 ms performance requirement

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§8.6 Logging](../../architecture/08-cross-cutting-concepts.md)
- [§10.2 Quality Scenarios](../../architecture/10-quality-requirements.md)
- [§10.3 Performance Scenario](../../architecture/10-quality-requirements.md)
- [GAME-INFRA-001.5](./game-creation.md)

**Description:** The structured logging middleware established in GAME-INFRA-001.5 must include `game_id` on reveal requests (§8.6). The p95 response time for a maximum flood-fill reveal on an Expert board (16×30) must remain below 200 ms (§10.3).

#### SCENARIO 1: Reveal request produces a structured log line with game_id

**Scenario ID:** REVEAL-INFRA-001.4-S1

**GIVEN**
* the backend is running with logging enabled
* a game exists with id `"game-abc"`

**WHEN**
* `POST /games/game-abc/reveal` is called and returns HTTP 200

**THEN**
* stdout contains exactly one log line for this request
* the line includes `method=POST`, `path=/games/game-abc/reveal`, `status=200`, a `duration` value in milliseconds, and `game_id=game-abc`

#### SCENARIO 2: Maximum flood-fill on Expert board responds within 200 ms

**Scenario ID:** REVEAL-INFRA-001.4-S2

**GIVEN**
* a game exists with `difficulty = "Expert"` (16×30, 99 mines) and `status = "new"`
* the first reveal triggers the maximum possible flood-fill area

**WHEN**
* `POST /games/{id}/reveal` is called

**THEN**
* the HTTP response is received in under 200 ms at p95 on a single backend instance

---

## BE Sub-Stories

### REVEAL-BE-001.1: POST /games/{id}/reveal endpoint — validate input and delegate to Game Session

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§4.4 API Design](../../architecture/04-solution-strategy.md)
- [§6.3 First Reveal Flow](../../architecture/06-runtime-view.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)
- [ADR-008 Error Mapping in API Layer](../../architecture/09-architecture-decisions.md)

**Description:** The `POST /games/{id}/reveal` FastAPI router validates that `row` and `col` are within board bounds, calls `Game Session.reveal(id, row, col)`, maps the returned `GameState` to a response DTO (ADR-005), and maps domain exceptions to 404/409/422 (ADR-008).

#### SCENARIO 1: Valid reveal on a new game returns 200 with updated DTO

**Scenario ID:** REVEAL-BE-001.1-S1

**GIVEN**
* a game exists with `id = "g1"` and `status = "new"` (9×9 board)
* the router for `POST /games/{id}/reveal` is registered

**WHEN**
* `POST /games/g1/reveal` is called with `{"row": 0, "col": 0}`

**THEN**
* the router calls `Game Session.reveal("g1", 0, 0)`
* the response status is 200
* the response body contains `status: "in_progress"`
* unrevealed cells in the response contain only position and state; no `has_mine` or `adjacent` fields are present for hidden cells (§8.3, ADR-005)

#### SCENARIO 2: GameNotFound exception maps to 404

**Scenario ID:** REVEAL-BE-001.1-S2

**GIVEN**
* `Game Session.reveal` raises `GameNotFound`

**WHEN**
* `POST /games/unknown/reveal` is called

**THEN**
* the router returns HTTP 404
* the response body is `{"detail": "Game not found"}`

#### SCENARIO 3: GameFinished exception maps to 409

**Scenario ID:** REVEAL-BE-001.1-S3

**GIVEN**
* `Game Session.reveal` raises `GameFinished`

**WHEN**
* `POST /games/{id}/reveal` is called on a finished game

**THEN**
* the router returns HTTP 409
* the response body is `{"detail": "Game already finished"}`

#### SCENARIO 4: InvalidMove exception maps to 422

**Scenario ID:** REVEAL-BE-001.1-S4

**GIVEN**
* `row` or `col` is outside the board dimensions

**WHEN**
* `POST /games/{id}/reveal` is called with out-of-bounds coordinates

**THEN**
* the router returns HTTP 422
* the response body is `{"detail": "Invalid coordinates"}`

---

### REVEAL-BE-001.2: Game Session — reveal() places mines on first reveal and delegates to Game Engine

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§6.3 First Reveal Flow](../../architecture/06-runtime-view.md)
- [ADR-004 Mines Placed on First Reveal](../../architecture/09-architecture-decisions.md)

**Description:** `Game Session.reveal(id, row, col)` loads the game via Persistence, detects `status = "new"`, calls `Board Management.place_mines()` and `Board Management.adjacent_counts()` excluding the clicked cell, then calls `Game Engine.reveal()`, updates `status` to `"in_progress"` (or `"won"`/`"lost"`), and persists the result.

#### SCENARIO 1: First reveal places mines excluding the clicked cell

**Scenario ID:** REVEAL-BE-001.2-S1

**GIVEN**
* a game exists with `id = "g1"`, `status = "new"`, 9×9 board, 10 mines to place

**WHEN**
* `Game Session.reveal("g1", 4, 4)` is called

**THEN**
* `Board Management.place_mines` is called with `safe_cell = (4, 4)`
* cell (4, 4) in the resulting board has `has_mine = False`
* exactly 10 cells in the board have `has_mine = True`
* `Persistence.save` is called with the updated `GameState`
* the returned `GameState` has `status = "in_progress"`

#### SCENARIO 2: Second reveal on the same game skips mine placement

**Scenario ID:** REVEAL-BE-001.2-S2

**GIVEN**
* a game exists with `status = "in_progress"` (mines already placed)

**WHEN**
* `Game Session.reveal(id, row, col)` is called for an unrevealed, non-mine cell

**THEN**
* `Board Management.place_mines` is NOT called
* `Game Engine.reveal` is called with the existing board
* `Persistence.save` is called with the updated `GameState`

#### SCENARIO 3: reveal() raises GameFinished when game is already won or lost

**Scenario ID:** REVEAL-BE-001.2-S3

**GIVEN**
* a game exists with `status = "won"` or `status = "lost"`

**WHEN**
* `Game Session.reveal(id, row, col)` is called

**THEN**
* `GameFinished` exception is raised
* `Persistence.save` is NOT called

---

### REVEAL-BE-001.3: Board Management — place_mines() and adjacent_counts() pure functions

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.5 Board Management](../../architecture/05-building-block-view.md)
- [ADR-004 Mines Placed on First Reveal](../../architecture/09-architecture-decisions.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

**Description:** `Board Management.place_mines(board, count, safe_cell)` randomly distributes `count` mines across the board, never placing one at `safe_cell`. `Board Management.adjacent_counts(board)` fills each non-mine cell's `adjacent` field with the count of neighbouring mines. Both are pure functions; `place_mines` accepts an injected `random.Random` for deterministic tests.

#### SCENARIO 1: place_mines excludes the safe cell and places the correct count

**Scenario ID:** REVEAL-BE-001.3-S1

**GIVEN**
* a 9×9 empty board (from `Board Management.create_empty(9, 9)`)
* `safe_cell = (4, 4)`
* a seeded `random.Random(42)` instance

**WHEN**
* `Board Management.place_mines(board, 10, safe_cell=(4,4), rng=random.Random(42))` is called

**THEN**
* exactly 10 cells have `has_mine = True`
* cell (4, 4) has `has_mine = False`
* repeated calls with the same seed produce the same mine layout

#### SCENARIO 2: adjacent_counts fills correct neighbour counts

**Scenario ID:** REVEAL-BE-001.3-S2

**GIVEN**
* a 3×3 board with a mine at (0, 0) and no other mines

**WHEN**
* `Board Management.adjacent_counts(board)` is called

**THEN**
* cell (0, 1) has `adjacent = 1`
* cell (1, 0) has `adjacent = 1`
* cell (1, 1) has `adjacent = 1`
* cell (0, 0) (the mine cell) has `adjacent = 0`
* cells (0, 2), (2, 0), (2, 1), (2, 2) have `adjacent = 0`

---

### REVEAL-BE-001.4: Game Engine — reveal() with flood-fill

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§1.1 Requirements Overview — flood-fill reveal](../../architecture/01-introduction-and-goals.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

**Description:** `Game Engine.reveal(board, row, col)` is a pure function. If the target cell has `adjacent = 0` and no mine, it flood-fills all contiguous zero-adjacent cells and their immediate numbered neighbours using an iterative BFS queue (not recursion) to avoid stack overflow on large Expert boards — see [§11 Risks](../../architecture/11-risks-and-technical-debt.md) risk "Recursive flood fill". It returns the updated `Board` without mutating the input.

#### SCENARIO 1: Reveal a numbered cell — only that cell is revealed

**Scenario ID:** REVEAL-BE-001.4-S1

**GIVEN**
* a board where cell (2, 2) has `adjacent = 3`, `has_mine = False`, `state = "hidden"`

**WHEN**
* `Game Engine.reveal(board, 2, 2)` is called

**THEN**
* cell (2, 2) in the returned board has `state = "revealed"`
* all other cells retain their previous state
* the input board is not mutated

#### SCENARIO 2: Reveal an empty cell triggers flood-fill

**Scenario ID:** REVEAL-BE-001.4-S2

**GIVEN**
* a 5×5 board where cells (0,0), (0,1), (1,0), (1,1) all have `adjacent = 0` and no mines
* cell (0,2) has `adjacent = 1`

**WHEN**
* `Game Engine.reveal(board, 0, 0)` is called

**THEN**
* cells (0,0), (0,1), (1,0), (1,1) all have `state = "revealed"` in the returned board
* cell (0,2) has `state = "revealed"` (frontier numbered cell)
* cells beyond the flood-fill frontier retain `state = "hidden"`

---

### REVEAL-BE-001.5: Game Engine — evaluate_status() after reveal

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§1.1 Requirements Overview — win/loss conditions](../../architecture/01-introduction-and-goals.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

**Description:** `Game Engine.evaluate_status(board)` is a pure function that returns `"in_progress"`, `"won"`, or `"lost"`. It returns `"lost"` if any revealed cell has `has_mine = True`, `"won"` if all non-mine cells are revealed, and `"in_progress"` otherwise.

#### SCENARIO 1: All non-mine cells revealed → won

**Scenario ID:** REVEAL-BE-001.5-S1

**GIVEN**
* a board where every non-mine cell has `state = "revealed"` and no mine cell is revealed

**WHEN**
* `Game Engine.evaluate_status(board)` is called

**THEN**
* the return value is `"won"`

#### SCENARIO 2: A mine cell is revealed → lost

**Scenario ID:** REVEAL-BE-001.5-S2

**GIVEN**
* a board where at least one cell has `has_mine = True` and `state = "revealed"`

**WHEN**
* `Game Engine.evaluate_status(board)` is called

**THEN**
* the return value is `"lost"`

#### SCENARIO 3: Some non-mine cells still hidden → in_progress

**Scenario ID:** REVEAL-BE-001.5-S3

**GIVEN**
* a board where at least one non-mine cell has `state = "hidden"` and no mine is revealed

**WHEN**
* `Game Engine.evaluate_status(board)` is called

**THEN**
* the return value is `"in_progress"`

---

## FE Sub-Stories

### REVEAL-FE-001.1: Cell component — click handler sends reveal request

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§5.2 API Layer — POST /games/{id}/reveal](../../architecture/05-building-block-view.md)
- [§6.3 First Reveal Flow](../../architecture/06-runtime-view.md)

**Description:** Each `Cell` component in the `Board` renders as an interactive element. Clicking a hidden cell calls `POST /games/{id}/reveal` with the cell's row and column. While the request is in-flight the cell is non-interactive to prevent duplicate submissions.

#### SCENARIO 1: Clicking a hidden cell sends the correct reveal request

**Scenario ID:** REVEAL-FE-001.1-S1

**GIVEN**
* the `Board` component is rendered for a game in `status = "new"`
* all cells are in `state = "hidden"`

**WHEN**
* the player clicks the `Cell` at row 2, col 3

**THEN**
* exactly one `POST /games/{id}/reveal` request is sent with body `{"row": 2, "col": 3}`
* the clicked cell becomes non-interactive (e.g. disabled or pointer-events suppressed) until the response is received

#### SCENARIO 2: Clicking an already-revealed cell sends no request

**Scenario ID:** REVEAL-FE-001.1-S2

**GIVEN**
* a `Cell` component has `state = "revealed"`

**WHEN**
* the player clicks it

**THEN**
* no `POST /games/{id}/reveal` request is sent

---

### REVEAL-FE-001.2: Board component — re-render after reveal response

**Parent:** REVEAL-STORY-001
**Architecture references:**
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)

**Description:** After a successful reveal response the `Board` component updates its state with the new game state from the API. Revealed cells display their `adjacent` count (if > 0) or appear blank (if 0). Flagged cells retain the flag icon.

#### SCENARIO 1: Revealed numbered cell displays its adjacent count

**Scenario ID:** REVEAL-FE-001.2-S1

**GIVEN**
* the API returns a game state where cell (1, 1) has `state = "revealed"` and `adjacent = 3`

**WHEN**
* the `Board` component re-renders with the new state

**THEN**
* the `Cell` at (1, 1) displays the number `3`
* the `Cell` at (1, 1) is no longer interactive (cannot be clicked again)

#### SCENARIO 2: Flood-fill result reveals multiple cells simultaneously

**Scenario ID:** REVEAL-FE-001.2-S2

**GIVEN**
* the API returns a game state where 15 cells have `state = "revealed"` after a single reveal request

**WHEN**
* the `Board` component re-renders

**THEN**
* exactly 15 `Cell` elements are rendered in a revealed visual state
* cells with `adjacent = 0` display no number
* cells with `adjacent > 0` display their numeric count

---

## Implementation Order

1. **REVEAL-INFRA-001.1** — Confirm no new deployment changes (references GAME-INFRA-001.1)
2. **REVEAL-INFRA-001.2** — Verify Persistence.save() overwrites correctly after reveal
3. **REVEAL-INFRA-001.3** — Confirm synchronous flow, no event infrastructure
4. **REVEAL-INFRA-001.4** — Add game_id to logging middleware; establish performance baseline
5. **REVEAL-BE-001.3** — `Board Management.place_mines()` + `adjacent_counts()` (pure, unit-testable)
6. **REVEAL-BE-001.4** — `Game Engine.reveal()` with flood-fill (pure, unit-testable)
7. **REVEAL-BE-001.5** — `Game Engine.evaluate_status()` (pure, unit-testable)
8. **REVEAL-BE-001.2** — `Game Session.reveal()` (integrates BE-001.3, BE-001.4, BE-001.5)
9. **REVEAL-BE-001.1** — `POST /games/{id}/reveal` router + error mapping (depends on BE-001.2)
10. **REVEAL-FE-001.1** — `Cell` click handler (depends on BE-001.1)
11. **REVEAL-FE-001.2** — `Board` re-render after reveal (depends on FE-001.1)
12. **REVEAL-STORY-001 E2E** — Full flow: new game → first click → board updates to in_progress
