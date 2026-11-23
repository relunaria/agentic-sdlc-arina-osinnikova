# 8. Cross-Cutting Concepts

## 8.1 Architecture Patterns

### Modular Monolith
The backend is organized as a single deployable unit with clear module boundaries. This enables:
- Clear separation of concerns
- Independent testing of modules
- Maintainability through well-defined interfaces

### Layered Architecture
- **API Layer**: HTTP and validation only
- **Business Layer**: Game Session, Game Engine, Board Management
- **Data Layer**: Persistence module only accesses the database

## 8.2 Design Principles

### Single Responsibility
Each module has one clear responsibility:
- API Layer: HTTP/REST only
- Game Session: Lifecycle management
- Game Engine: Pure game rules
- Board Management: Board state and operations
- Persistence: Data persistence only

### Clean Dependencies
- No cross-module database access
- Dependencies flow inward (API → Session → Engine → Board)
- Persistence is isolated and called explicitly

### Pure Functions
Game Engine and Board Management are pure functions with no I/O:
- Easier to test
- Deterministic behavior
- No side effects

Mine placement takes an injected random.Random (seedable) for deterministic tests.

## 8.3 Game State Exposure

The API returns a client view of the board built from the domain board:
- Unrevealed cells carry no mine/count info
- Mine positions are revealed only when status is won/lost
- This mapping lives in the API Layer (response DTOs)
- Domain model is never serialized directly

## 8.4 Domain Model & Serialization

### Game
- id (string/UUID)
- difficulty (Beginner/Intermediate/Expert)
- status (new/in_progress/won/lost)
- created_at (timestamp)
- board (Board object)

### Board
- rows (int)
- cols (int)
- cells (list of Cell)

### Cell
- has_mine (bool)
- adjacent (int)
- state: hidden/revealed/flagged

Persistence stores one row per game with the board serialized as JSON.

## 8.5 Error Handling

| Error | Scenario | Response Format |
|-------|----------|-----------------|
| 404 | Unknown game ID | `{"detail": "Game not found"}` |
| 409 | Move on finished game | `{"detail": "Game already finished"}` |
| 422 | Invalid coordinates | `{"detail": "Invalid coordinates"}` |

Domain exceptions (GameNotFound, GameFinished, InvalidMove) are mapped to HTTP status codes in the API Layer.

## 8.6 Logging

- Python logging, structured to stdout
- One line per request: method, path, status, duration
- Includes game_id on moves
- No PII is stored

## 8.7 Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| DATABASE_PATH | `./games.db` | Path to SQLite file on persistent volume |
| CORS_ALLOWED_ORIGINS | `http://localhost:3000` | Comma-separated list of allowed frontend origins |

## 8.8 Testing Strategy

- Unit tests for Game Engine and Board Management (pure functions)
- Integration tests for API endpoints using FastAPI TestClient
- End-to-end tests for gameplay flows

---

*Previous chapter: 7. Deployment View*

*Next chapter: 9. Architecture Decisions*
