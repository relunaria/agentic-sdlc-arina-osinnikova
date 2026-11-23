# 9. Architecture Decisions

## ADR-001: Technology Stack — React + TypeScript, Python + FastAPI, SQLite

**Status:** Accepted

**Context:**
The frontend needs a modern component-based UI with type safety. The backend needs a clean REST API with async support. The database must be simple to deploy for a single-player application.

**Decision:**
- Frontend: React + TypeScript
- Backend: Python + FastAPI
- Database: SQLite

**Rationale:**
- **Frontend:** React's component model fits the board grid structure; TypeScript catches errors at compile time; strong ecosystem for state management and testing.
- **Backend:** FastAPI's dependency injection supports clean module boundaries; automatic OpenAPI documentation aids testing; async support handles potential I/O; Python's readability supports team collaboration.
- **Database:** SQLite is zero-config, embedded, requires no separate server, and simplifies deployment for a single-player application. The game state is stored as a serialized board per game row.

**Alternatives Considered:**
- Frontend: Vue.js, Svelte — rejected in favor of React's ecosystem and team familiarity
- Backend: Django, Flask — rejected in favor of FastAPI's async support and clean dependency injection
- Database: PostgreSQL, MySQL — rejected for added operational complexity; SQLite is sufficient for single-player

**Consequences:**
- Positive: Fast development, automatic API docs, simple deployment, better code quality
- Trade-offs: Python may not be optimal for CPU-intensive workloads (not expected); SQLite limited to single-instance writes; TypeScript learning curve

## ADR-002: Modular Monolith Architecture

**Status:** Accepted

**Context:**
The system is a single-player game with no need for independent service scaling or deployment. Introducing microservices would add operational complexity without clear benefits.

**Decision:**
The backend is organized as a modular monolith: a single deployable unit with clear internal modules (API Layer, Game Session, Game Engine, Board Management, Persistence).

**Rationale:**
- Simpler deployment and operations for a single-player application
- Clear module boundaries facilitate future refactoring if needed
- No network overhead between internal modules
- Easier to maintain and reason about for a small team

**Consequences:**
- Positive: Simpler deployment, no inter-service communication complexity
- Trade-off: Cannot scale individual modules independently; backend restart affects all functionality

## ADR-003: Separate Frontend and Backend Deployment

**Status:** Accepted

**Context:**
The frontend and backend have different deployment cycles and hosting requirements. Frontend is static assets; backend requires a Python runtime.

**Decision:**
Deploy frontend and backend as separate artifacts with distinct hosting.

**Rationale:**
- Frontend can be served from CDN/static hosting for performance
- Backend can use PaaS with persistent disk for SQLite
- Independent scaling and update cycles
- Clear ownership boundaries

**Consequences:**
- Positive: Flexible hosting options, independent deployments
- Trade-off: Requires CORS configuration, network latency for API calls

## ADR-004: Mines Placed on First Reveal

**Status:** Accepted

**Context:**
Classic Minesweeper guarantees a safe first click. Creating the game with mines already placed would risk the first click being a mine.

**Decision:**
The game is created with an empty board (status `new`), and mines are placed on the first reveal, excluding the clicked cell.

**Rationale:**
- Matches classic Minesweeper behavior
- Eliminates the possibility of losing on the first click
- Domain model reflects game rules accurately

**Consequences:**
- Positive: Safe first click, matches player expectations
- Trade-off: Extra "new" game state, first reveal is a special case in Game Session logic

## ADR-005: Domain Model Never Exposed Directly

**Status:** Accepted

**Context:**
The internal domain model (Game, Board, Cell) contains sensitive information (mine positions) that should not be exposed to clients until the game ends.

**Decision:**
Map domain models to response DTOs in the API Layer. Unrevealed cells carry no mine/count info; mine positions are revealed only on win/loss.

**Rationale:**
- Security: Prevents clients from seeing mine positions prematurely
- Separation of concerns: Domain model optimized for business logic, DTOs for client needs
- Flexibility: Can change domain model without affecting API contract

**Consequences:**
- Positive: Better security, cleaner API contract
- Trade-off: Additional mapping layer in API code

## ADR-006: Pure Functions for Game Logic

**Status:** Accepted

**Context:**
Game rules must be deterministic and thoroughly tested. Side effects complicate testing and reasoning.

**Decision:**
Game Engine and Board Management are pure functions. Board Management uses an injected random.Random (seedable) for deterministic tests.

**Rationale:**
- Easier to unit test (input → output, no mocking needed)
- Deterministic behavior enables debugging and replay
- Thread-safe for future concurrency needs

**Consequences:**
- Positive: High test coverage, easy debugging
- Trade-off: Requires dependency injection for randomness

## ADR-007: Board Persisted as JSON per Game Row

**Status:** Accepted

**Context:**
The board state needs to be persisted efficiently without complex schema changes.

**Decision:**
Store each game as a single row in SQLite, with the board object serialized as JSON.

**Rationale:**
- Simple schema: one table, few columns
- Flexible: board structure can evolve without migrations
- Fast enough for single-player game (no query on board data needed)

**Consequences:**
- Positive: Simple persistence layer, easy to evolve
- Trade-off: Cannot query on board contents; full game load required

## ADR-008: Error Mapping in API Layer

**Status:** Accepted

**Context:**
Domain exceptions need to be converted to appropriate HTTP status codes for API clients.

**Decision:**
Map domain exceptions (GameNotFound, GameFinished, InvalidMove) to HTTP errors (404, 409, 422) in the API Layer using FastAPI's JSON format `{"detail": "..."}`.

**Rationale:**
- Consistent error format for clients
- Clear separation between domain and HTTP concerns
- Leverages FastAPI's built-in exception handling

**Consequences:**
- Positive: Clean domain code, standard HTTP errors
- Trade-off: Requires maintaining exception-to-status mapping

---

*Previous chapter: 8. Cross-Cutting Concepts*

*Next chapter: 10. Quality Requirements*
