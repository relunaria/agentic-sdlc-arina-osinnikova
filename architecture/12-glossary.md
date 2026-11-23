# 12. Glossary

| Term | Definition |
|------|------------|
| API Layer | FastAPI routers handling HTTP requests, validation, and DTO mapping |
| Board | Domain object representing the game grid: rows, cols, and cells |
| Board Management | Module responsible for grid creation, mine placement, and adjacent-mine calculations |
| Cell | Domain object with has_mine, adjacent count, and state (hidden/revealed/flagged) |
| CORS | Cross-Origin Resource Sharing; backend allows frontend origin via headers |
| DTO | Data Transfer Object; API response model mapping domain state to client view |
| Beginner | Difficulty preset: 9x9 grid with 10 mines |
| Expert | Difficulty preset: 16x30 grid with 99 mines |
| FastAPI | Python web framework for the backend API |
| Flood Fill | Algorithm that iteratively (BFS) reveals connected empty cells and their numbered border |
| Game | Domain object: id, difficulty, status (new/in_progress/won/lost), created_at, board |
| Game Engine | Module implementing pure game rules: reveal, flag, flood fill, win/loss detection |
| Game Session | Module managing game lifecycle, orchestrating Engine and Persistence |
| Game State | Current status of a game including board, player actions, and outcome |
| Intermediate | Difficulty preset: 16x16 grid with 40 mines |
| Mine | Cell containing a hidden explosive; revealing it ends the game |
| Modular Monolith | Single deployable unit with clear internal module boundaries |
| New | Game status indicating creation with empty board, no mines placed yet |
| Persistence | Module responsible for reading and writing game state to SQLite |
| Pure Function | Function with no side effects, deterministic output for given input |
| React | JavaScript library for building user interfaces |
| Reveal | Player action exposing a cell's contents |
| REST | Representational State Transfer; API style using HTTP methods |
| SQLite | Embedded relational database stored as a single file |
| TypeScript | Typed superset of JavaScript compiled to JavaScript |
| UUIDv4 | Randomly generated unique identifier for game IDs |

---

*Previous chapter: 11. Risks and Technical Debt*

*End of arc42 documentation*
