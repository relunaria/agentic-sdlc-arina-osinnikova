# User Stories — Minesweeper Web Application

## Domain Mapping

| Domain Prefix | Architecture Module(s) | Description |
|---|---|---|
| **GAME** | Game Session + API Layer (`POST /games`, `GET /games/{id}`) | Game lifecycle — creation and retrieval |
| **REVEAL** | Game Session + Game Engine + Board Management + API Layer (`POST /games/{id}/reveal`) | Cell reveal, flood fill, first-click mine placement, win/loss |
| **FLAG** | Game Session + Game Engine + API Layer (`POST /games/{id}/flag`) | Flag toggling and mines counter |

---

## Story Inventory

| ID | Title | Domain | Priority | Status | File |
|---|---|---|---|---|---|
| GAME-STORY-001 | Create a new game | GAME | Core | ✅ Written | [game-creation.md](./game-creation.md) |
| REVEAL-STORY-001 | Reveal a cell (first click — safe) | REVEAL | Core | ✅ Written | [cell-reveal.md](./cell-reveal.md) |
| REVEAL-STORY-002 | Reveal a cell (subsequent moves — win/loss) | REVEAL | Core | ✅ Written | [game-outcome.md](./game-outcome.md) |
| GAME-STORY-002 | Resume a game by URL | GAME | Supporting | Out of MVP scope | — |
| FLAG-STORY-001 | Toggle a flag on a cell | FLAG | Supporting | Out of MVP scope | — |
| FLAG-STORY-002 | See a remaining-mines counter | FLAG | Supporting | Out of MVP scope | — |
| GAME-STORY-003 | Start a new game after the current one finishes | GAME | Supporting | Out of MVP scope | — |
| GAME-STORY-004 | See a clear error message when the backend is unavailable or returns 404/409/422 | GAME | Supporting | Out of MVP scope | — |

---

## Pareto Metrics

📊 **Pareto Progress:** 3/3 core stories written (100% of core stories)
🎯 **Core functionality coverage:** ~80% of 80% target

| Metric | Value |
|---|---|
| Total stories in inventory | 8 |
| Core stories | 3 (GAME-STORY-001, REVEAL-STORY-001, REVEAL-STORY-002) |
| Core share | 37.5% of inventory |
| Supporting stories (out of MVP scope) | 5 |
| Architecture modules covered by core | All 5 (API Layer, Game Session, Game Engine, Board Management, Persistence) |
| ADRs covered by core | ADR-002, ADR-003, ADR-004, ADR-005, ADR-006, ADR-007, ADR-008 |

> REVEAL-STORY-003 (mine positions on loss) is covered by REVEAL-BE-002.2 and REVEAL-FE-002.1 in the REVEAL-STORY-002 bundle.
> OBS-STORY-001 (health endpoint + logging) is covered by GAME-INFRA-001.5 and REVEAL-INFRA-001.4 in the GAME-STORY-001 and REVEAL-STORY-001 bundles.
