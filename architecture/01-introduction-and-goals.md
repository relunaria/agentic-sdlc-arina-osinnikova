# 1. Introduction and Goals

## 1.1 Requirements Overview

The Minesweeper Web Application is a single-player game that runs in a web browser.

### System Purpose
The application implements classic Minesweeper with the following mechanics:
- Reveal cell
- Toggle flag
- Flood-fill reveal of empty areas
- Win when all non-mine cells are revealed
- Loss when a mine is revealed
- Mines are placed after the first reveal, so the first click is always safe
- Difficulty presets: Beginner (9x9, 10 mines), Intermediate (16x16, 40 mines), Expert (16x30, 99 mines)

### Confirmed Technology Stack
- Frontend: React + TypeScript (separately deployed from backend)
- Backend: Python + FastAPI (REST API)
- Database: SQLite (accessed only through the Persistence module)
- Architecture style: Modular Monolith
- API style: REST
- Deployment: frontend and backend deployed separately

### Main Modules (Backend)
- API Layer (FastAPI routers)
- Game Session
- Game Engine
- Board Management
- Persistence

## 1.2 Quality Goals

| Priority | Quality Goal | Description |
|----------|--------------|-------------|
| High | Correctness | Rules are covered by unit tests; Game Engine and Board Management are pure functions |
| High | Maintainability | Clear module boundaries; no cross-module database access |
| High | Responsiveness | A move responds in under 200 ms |

## 1.3 Stakeholders

| Stakeholder | Role | Interests |
|-------------|------|-----------|
| Player | Plays the game | Correct game mechanics, responsive gameplay |
| Developer | Builds and maintains | Clean architecture, maintainable codebase |
| Course instructor | Reviews architecture | Demonstrates architectural patterns |

---

*Previous chapter: none*

*Next chapter: Constraints (Chapter 2)*
