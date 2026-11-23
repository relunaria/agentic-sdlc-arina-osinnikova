# 4. Solution Strategy

## 4.1 Architectural Style

The system follows a **Modular Monolith** architecture style. The backend is a single deployable unit organized into five internal modules:

- API Layer (FastAPI routers)
- Game Session
- Game Engine
- Board Management
- Persistence

This approach keeps backend functionality within one deployable unit rather than introducing independently deployed backend services.

## 4.2 Technology Decisions

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Frontend | React + TypeScript | Provides type-safe UI development and component-based architecture |
| Backend | Python + FastAPI | Offers rapid development, async support, and clean REST API capabilities |
| Database | SQLite | Zero-config embedded DB, enough for a single-player game; the game state is stored as a serialized board per game row |
| Deployment | Separate frontend/backend | Confirmed deployment strategy |

## 4.3 Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| API Layer (FastAPI routers) | HTTP and validation only, calls Game Session |
| Game Session | Game lifecycle and status (new/in_progress/won/lost), orchestrates Engine + Persistence |
| Game Engine | Pure rule logic (reveal, flood fill, flag, win/loss), no I/O |
| Board Management | Grid creation, mine placement, adjacent-mine counts |
| Persistence | Repository over SQLite |

## 4.4 API Design

REST is the confirmed API style. The API provides the following endpoints:
- POST /games {difficulty} → 201 game state
- GET /games/{id} → game state
- POST /games/{id}/reveal {row, col} → updated state
- POST /games/{id}/flag {row, col} → updated state

The response never exposes unrevealed mine positions until the game is over. Errors: 404 for unknown game, 409 for move on finished game, 422 for invalid coordinates.

## 4.5 Deployment Strategy

- Frontend: Deployed separately from the backend
- Backend: Deployed as a Python application with FastAPI
- Database: SQLite file stored on the backend server

## 4.6 Development Approach

The modular monolith structure supports:
- Clear separation of concerns between modules
- Independent testing of each module
- Maintainability through well-defined module boundaries

---

*Previous chapter: 3. Context and Scope*

*Next chapter: 5. Building Block View*
