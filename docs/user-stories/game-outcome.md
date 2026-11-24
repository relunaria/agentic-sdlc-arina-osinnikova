# REVEAL-STORY-002: Reveal a cell (subsequent moves — win/loss)

**Priority:** Core (Pareto 20%)
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§6.4 Subsequent Moves Flow](../../architecture/06-runtime-view.md)
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)
- [ADR-006 Pure Functions for Game Logic](../../architecture/09-architecture-decisions.md)

> **Reuse note:** The `POST /games/{id}/reveal` router (REVEAL-BE-001.1), the subsequent-move branch of `Game Session.reveal()` (REVEAL-BE-001.2-S2), `Game Engine.evaluate_status()` (REVEAL-BE-001.5), and 409 handling are all defined in REVEAL-STORY-001. This story covers only what is new: hitting a mine (→ `"lost"`), revealing the last safe cell (→ `"won"`), and the DTO behaviour that exposes mine positions on game end (§8.3, ADR-005).

---

## Original Story

AS A player
I WANT subsequent reveals to end the game when I hit a mine or uncover the last safe cell
SO THAT I see the correct win or loss outcome and all mine positions are shown at game end

### SCENARIO 1: Player hits a mine — game transitions to lost and mines are exposed

**Scenario ID:** REVEAL-STORY-002-S1

**GIVEN**
* a game exists with `status = "in_progress"` (mines already placed)
* cell (3, 5) has `has_mine = True` and `state = "hidden"`

**WHEN**
* the player clicks cell (3, 5)
* the frontend sends `POST /games/{id}/reveal` with `{"row": 3, "col": 5}`

**THEN**
* the backend returns HTTP 200
* the response body contains `status: "lost"`
* every cell that has a mine is present in the response with `has_mine: true` (mine positions exposed on loss, §8.3, ADR-005)
* cell (3, 5) has `state: "revealed"` and `has_mine: true`
* the frontend displays a game-over banner indicating the player lost

### SCENARIO 2: Player reveals the last safe cell — game transitions to won and mines are exposed

**Scenario ID:** REVEAL-STORY-002-S2

**GIVEN**
* a game exists with `status = "in_progress"`
* exactly one non-mine cell remains with `state = "hidden"`

**WHEN**
* the player clicks that last hidden safe cell
* the frontend sends `POST /games/{id}/reveal` with its coordinates

**THEN**
* the backend returns HTTP 200
* the response body contains `status: "won"`
* every cell that has a mine is present in the response with `has_mine: true` (mine positions exposed on win, §8.3, ADR-005)
* all non-mine cells have `state: "revealed"`
* the frontend displays a win banner

### SCENARIO 3: Move on a finished game is rejected (reference)

**Scenario ID:** REVEAL-STORY-002-S3

**GIVEN**
* a game exists with `status = "won"` or `status = "lost"`

**WHEN**
* the frontend sends `POST /games/{id}/reveal` with any coordinates

**THEN**
* the backend returns HTTP 409 with `{"detail": "Game already finished"}`
* (full specification in REVEAL-STORY-001-S3 and REVEAL-BE-001.1-S3)

---

## INFRA Sub-Stories

### REVEAL-INFRA-002.1: Deployment — no new deployment changes required

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [GAME-INFRA-001.1](./game-creation.md)
- [§7.2 Runtime Environment](../../architecture/07-deployment-view.md)

**Description:** The backend container, persistent volume, CORS, and logging established in GAME-INFRA-001.1/001.2/001.5 are unchanged. The reveal endpoint already serves subsequent moves. No deployment change is needed for win/loss outcomes.

#### SCENARIO 1: Win/loss outcomes are served by the existing deployment

**Scenario ID:** REVEAL-INFRA-002.1-S1

**GIVEN**
* the backend container from GAME-INFRA-001.1 is running

**WHEN**
* `POST /games/{id}/reveal` triggers a `"won"` or `"lost"` outcome

**THEN**
* the backend returns HTTP 200 with the correct status and mine positions without any redeployment

---

### REVEAL-INFRA-002.2: Data store — game row updated to won/lost with full board persisted

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§5.6 Persistence](../../architecture/05-building-block-view.md)
- [§8.4 Domain Model & Serialization](../../architecture/08-cross-cutting-concepts.md)
- [ADR-007 Board Persisted as JSON per Game Row](../../architecture/09-architecture-decisions.md)
- [GAME-INFRA-001.3](./game-creation.md)

**Description:** When the game ends, `Persistence.save()` (GAME-INFRA-001.3) writes the final board state including all mine positions and `status = "won"` or `"lost"`. No schema change is needed; the existing `games` table row is overwritten.

#### SCENARIO 1: Loss outcome is persisted correctly

**Scenario ID:** REVEAL-INFRA-002.2-S1

**GIVEN**
* a game row exists in the `games` table with `status = "in_progress"`

**WHEN**
* a reveal hits a mine and the game transitions to `"lost"`

**THEN**
* the `games` row for that `id` has `status = "lost"`
* the `board` JSON contains the mine cell with `state = "revealed"` and `has_mine = true`
* `Persistence.load(id)` returns a `GameState` with `status = "lost"`

#### SCENARIO 2: Win outcome is persisted correctly

**Scenario ID:** REVEAL-INFRA-002.2-S2

**GIVEN**
* a game row exists with `status = "in_progress"` and one hidden safe cell remaining

**WHEN**
* that last cell is revealed and the game transitions to `"won"`

**THEN**
* the `games` row has `status = "won"`
* all non-mine cells in the `board` JSON have `state = "revealed"`

---

### REVEAL-INFRA-002.3: No event infrastructure required (synchronous REST)

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [ADR-002 Modular Monolith](../../architecture/09-architecture-decisions.md)
- [§6.4 Subsequent Moves Flow](../../architecture/06-runtime-view.md)

**Description:** Win/loss evaluation is a synchronous in-process call (Game Engine → Game Session → Persistence) with no message bus (ADR-002). This sub-story confirms no event infrastructure is introduced for game-end transitions.

#### SCENARIO 1: Win/loss transition completes synchronously within the HTTP request

**Scenario ID:** REVEAL-INFRA-002.3-S1

**GIVEN**
* the backend receives `POST /games/{id}/reveal` that triggers a win or loss

**WHEN**
* the request is processed

**THEN**
* the HTTP response is returned in the same transaction with the final `status`
* no outbound message is published to any queue or topic
* the updated game row is readable in SQLite before the response reaches the client

---

### REVEAL-INFRA-002.4: Monitoring — won/lost outcomes logged with game_id

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§8.6 Logging](../../architecture/08-cross-cutting-concepts.md)
- [§10.2 Quality Scenarios](../../architecture/10-quality-requirements.md)
- [GAME-INFRA-001.5](./game-creation.md)
- [REVEAL-INFRA-001.4](./cell-reveal.md)

**Description:** The logging middleware established in GAME-INFRA-001.5 and extended in REVEAL-INFRA-001.4 already captures `game_id` on every reveal. No additional logging changes are needed. This sub-story confirms the existing middleware covers the won/lost response codes.

#### SCENARIO 1: Loss-triggering reveal is logged with status 200 and game_id

**Scenario ID:** REVEAL-INFRA-002.4-S1

**GIVEN**
* the backend is running with the logging middleware from GAME-INFRA-001.5 and REVEAL-INFRA-001.4

**WHEN**
* `POST /games/{id}/reveal` triggers a `"lost"` outcome and returns HTTP 200

**THEN**
* stdout contains one log line with `method=POST`, `path=/games/{id}/reveal`, `status=200`, a `duration` in milliseconds, and `game_id={id}`

---

## BE Sub-Stories

### REVEAL-BE-002.1: Game Session — reveal() transitions to won/lost and persists final state

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§5.3 Game Session](../../architecture/05-building-block-view.md)
- [§5.4 Game Engine](../../architecture/05-building-block-view.md)
- [§6.4 Subsequent Moves Flow](../../architecture/06-runtime-view.md)
- [ADR-004 Mines Placed on First Reveal](../../architecture/09-architecture-decisions.md)

> **Reuse note:** The subsequent-move branch (status already `"in_progress"`, mine placement skipped) is specified in REVEAL-BE-001.2-S2. `Game Engine.evaluate_status()` is specified in REVEAL-BE-001.5. This sub-story covers only the game-end outcomes produced by that existing call chain.

**Description:** After `Game Engine.reveal()` runs on an `"in_progress"` game, `Game Session` calls `Game Engine.evaluate_status()`. If the result is `"won"` or `"lost"`, it sets `GameState.status` accordingly and calls `Persistence.save()` before returning.

#### SCENARIO 1: Revealing a mine sets status to lost and saves

**Scenario ID:** REVEAL-BE-002.1-S1

**GIVEN**
* a `GameState` with `status = "in_progress"` where cell (2, 2) has `has_mine = True`, `state = "hidden"`

**WHEN**
* `Game Session.reveal(id, 2, 2)` is called

**THEN**
* `Game Engine.reveal` sets cell (2, 2) to `state = "revealed"`
* `Game Engine.evaluate_status` returns `"lost"`
* the returned `GameState` has `status = "lost"`
* `Persistence.save` is called exactly once with `status = "lost"`

#### SCENARIO 2: Revealing the last safe cell sets status to won and saves

**Scenario ID:** REVEAL-BE-002.1-S2

**GIVEN**
* a `GameState` with `status = "in_progress"` where exactly one non-mine cell has `state = "hidden"`

**WHEN**
* `Game Session.reveal(id, row, col)` is called for that cell

**THEN**
* `Game Engine.evaluate_status` returns `"won"`
* the returned `GameState` has `status = "won"`
* `Persistence.save` is called exactly once with `status = "won"`

---

### REVEAL-BE-002.2: API Layer DTO — expose mine positions only on won/lost

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§5.2 API Layer](../../architecture/05-building-block-view.md)
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)
- [ADR-005 Domain Model Never Exposed Directly](../../architecture/09-architecture-decisions.md)

**Description:** The response DTO mapper in the API Layer inspects `GameState.status`. When `status` is `"won"` or `"lost"` it includes `has_mine: true` on mine cells in the response. When `status` is `"new"` or `"in_progress"` mine cells carry no `has_mine` field. This mapping lives entirely in the API Layer.

#### SCENARIO 1: in_progress response omits has_mine on all cells

**Scenario ID:** REVEAL-BE-002.2-S1

**GIVEN**
* `Game Session.reveal()` returns a `GameState` with `status = "in_progress"`

**WHEN**
* the API Layer maps the domain model to a response DTO

**THEN**
* no cell in the response body contains a `has_mine` field
* revealed cells contain `state: "revealed"` and an `adjacent` count
* hidden cells contain only their position and `state: "hidden"`

#### SCENARIO 2: lost response includes has_mine on mine cells

**Scenario ID:** REVEAL-BE-002.2-S2

**GIVEN**
* `Game Session.reveal()` returns a `GameState` with `status = "lost"`
* the board has 10 mine cells

**WHEN**
* the API Layer maps the domain model to a response DTO

**THEN**
* exactly 10 cells in the response have `has_mine: true`
* the cell that triggered the loss has `state: "revealed"` and `has_mine: true`
* non-mine cells do not have a `has_mine` field

#### SCENARIO 3: won response includes has_mine on mine cells

**Scenario ID:** REVEAL-BE-002.2-S3

**GIVEN**
* `Game Session.reveal()` returns a `GameState` with `status = "won"`
* the board has 10 mine cells

**WHEN**
* the API Layer maps the domain model to a response DTO

**THEN**
* exactly 10 cells in the response have `has_mine: true`
* all non-mine cells have `state: "revealed"`

---

## FE Sub-Stories

### REVEAL-FE-002.1: Game-over banner on loss

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§5.2 API Layer — POST /games/{id}/reveal response](../../architecture/05-building-block-view.md)
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)

**Description:** When the reveal response contains `status: "lost"`, a `GameOverBanner` component renders over or below the board with a loss message. All cells become non-interactive. Mine cells with `has_mine: true` are rendered with a mine icon.

#### SCENARIO 1: Loss banner appears and board becomes non-interactive

**Scenario ID:** REVEAL-FE-002.1-S1

**GIVEN**
* the `Board` component is rendered for a game in `status = "in_progress"`

**WHEN**
* a reveal response arrives with `status: "lost"`

**THEN**
* a `GameOverBanner` component is visible in the DOM with text indicating a loss (e.g. "Game Over")
* all `Cell` elements are non-interactive (click events produce no API call)
* every cell returned with `has_mine: true` displays a mine icon

#### SCENARIO 2: Mine positions are displayed after loss

**Scenario ID:** REVEAL-FE-002.1-S2

**GIVEN**
* the reveal response for a Beginner game contains `status: "lost"` and 10 cells with `has_mine: true`

**WHEN**
* the `Board` component re-renders with the new state

**THEN**
* exactly 10 `Cell` elements display a mine icon
* the cell that was clicked has both a mine icon and a visually distinct "triggered" state

---

### REVEAL-FE-002.2: Win banner on victory

**Parent:** REVEAL-STORY-002
**Architecture references:**
- [§5.2 API Layer — POST /games/{id}/reveal response](../../architecture/05-building-block-view.md)
- [§8.3 Game State Exposure](../../architecture/08-cross-cutting-concepts.md)

**Description:** When the reveal response contains `status: "won"`, a `WinBanner` component renders with a victory message. All cells become non-interactive. Mine cells are rendered with a flag or mine icon to confirm their positions.

#### SCENARIO 1: Win banner appears and all cells are revealed

**Scenario ID:** REVEAL-FE-002.2-S1

**GIVEN**
* the `Board` component is rendered for a game in `status = "in_progress"`

**WHEN**
* a reveal response arrives with `status: "won"`

**THEN**
* a `WinBanner` component is visible in the DOM with text indicating a win (e.g. "You Win!")
* all non-mine `Cell` elements display `state = "revealed"` with their adjacent count or blank
* all `Cell` elements are non-interactive
* mine cells display a mine or flag icon

---

## Implementation Order

1. **REVEAL-INFRA-002.1** — Confirm no new deployment changes
2. **REVEAL-INFRA-002.2** — Verify Persistence.save() writes won/lost status and final board
3. **REVEAL-INFRA-002.3** — Confirm synchronous flow for game-end transitions
4. **REVEAL-INFRA-002.4** — Confirm existing logging covers won/lost response codes
5. **REVEAL-BE-002.1** — `Game Session.reveal()` won/lost outcomes (extends REVEAL-BE-001.2)
6. **REVEAL-BE-002.2** — API Layer DTO mine-exposure logic for won/lost
7. **REVEAL-FE-002.1** — `GameOverBanner` component + mine icon display
8. **REVEAL-FE-002.2** — `WinBanner` component
9. **REVEAL-STORY-002 E2E** — Full flow: in_progress game → hit mine → lost + mines shown; and → reveal last cell → won + mines shown
