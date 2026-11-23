# 10. Quality Requirements

## 10.1 Quality Tree

```
Quality
├── Correctness
│   ├── Game Rules Coverage (unit tests for Engine/Board)
│   └── Deterministic Behavior (pure functions, seedable randomness)
├── Maintainability
│   ├── Module Boundaries (clear separation, no cross-module DB access)
│   └── Testability (pure functions, dependency injection)
├── Performance
│   └── Responsiveness (< 200ms p95 for max flood fill on Expert board)
└── Security
    ├── Input Validation (API Layer validation)
    └── Minimal Data Exposure (DTO mapping, no mine info in client view)
```

## 10.2 Quality Scenarios

| Priority | Scenario | Response Measure |
|----------|----------|------------------|
| High | Player performs a move | Response time < 200ms |
| High | Game rules are executed | All rules covered by unit tests |
| High | Module boundaries are enforced | No cross-module database access |
| Medium | Game state is persisted | Every move saves to SQLite |
| Medium | Error handling is consistent | 404/409/422 with JSON `{"detail": "..."}` |
| Medium | Input validation is thorough | All coordinates validated before processing |
| Low | Logging is structured | One line per request with game_id on moves |

## 10.3 Performance Scenario

| Priority | Scenario | Response Measure |
|----------|----------|------------------|
| High | Reveal on an Expert board (16x30) that triggers the maximum flood fill | p95 response < 200ms on a single backend instance |

## 10.4 Trade-offs

| Trade-off | Reason |
|-----------|--------|
| Single-instance SQLite limits backend scaling | Simplicity and operational ease for single-player application |
| JSON serialization per game | Simplicity vs query flexibility |
| Pure functions require dependency injection | Testability vs slight complexity in function signatures |

---

*Previous chapter: 9. Architecture Decisions*

*Next chapter: 11. Risks and Technical Debt*
