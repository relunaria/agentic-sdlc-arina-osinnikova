# 2. Constraints

## 2.1 Technology Constraints

| Constraint | Description |
|------------|-------------|
| Frontend Framework | React + TypeScript must be used for the frontend |
| Backend Framework | Python + FastAPI must be used for the backend |
| Database | SQLite must be used for data persistence |
| Architecture Style | Modular Monolith architecture is required |
| API Style | REST API must be used for backend communication |

## 2.2 Deployment Constraints

| Constraint | Description |
|------------|-------------|
| Separate Deployment | Frontend and backend must be deployed separately |

## 2.3 Integration Constraints

| Constraint | Description |
|------------|-------------|
| Database Access | SQLite database is accessed only through the Persistence module |
| Communication | Frontend communicates with backend via REST API |

## 2.4 Organizational Constraints

No organizational constraints were explicitly specified in the project context.

## 2.5 Quality Constraints

| Constraint | Description |
|------------|-------------|
| Correctness | Game rules must be covered by unit tests |
| Maintainability | Module boundaries must be clear; no cross-module DB access |
| Responsiveness | Move responses must be under 200 ms |

## 2.6 Naming and Design Constraints

| Constraint | Description |
|------------|-------------|
| Module Naming | Backend must be organized into five modules: API Layer, Game Session, Game Engine, Board Management, Persistence |

---

*Previous chapter: 1. Introduction and Goals*

*Next chapter: 3. Context and Scope*
