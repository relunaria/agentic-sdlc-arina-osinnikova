# 11. Risks and Technical Debt

## 11.1 Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| SQLite single-instance writes | High | Backend must run as single instance; scale horizontally at frontend only |
| No authentication | High | Random UUIDv4 game IDs (not guessable); accounts are out of scope |
| Data loss | High | Persistent volume plus periodic file backup (sqlite3 .backup) |
| Recursive flood fill hits Python recursion limit | Medium | Implement flood fill iteratively (BFS with a queue) |
| Abuse/spam of POST /games | Medium | Basic rate limiting; cleanup of finished/stale games older than N days |

## 11.2 Technical Debt

| Item | Debt | Remediation Plan |
|------|------|------------------|
| Board serialized as JSON | Acceptable for MVP | Consider columnar storage if querying on cells becomes needed |
| No database migrations | Acceptable for MVP | Add alembic when schema changes become frequent |
| No caching | Acceptable for MVP | Add Redis for session caching if player count grows |
| No API versioning | Acceptable for MVP | Add version prefix when breaking changes are anticipated |

## 11.3 Open Decisions

| Decision | Reason for Delay |
|----------|------------------|
| API versioning strategy | No breaking changes anticipated in near term |
| Caching strategy | Single-player workload may not require caching |
| Database monitoring | MVP stage; add when scaling |

---

*Previous chapter: 10. Quality Requirements*

*Next chapter: 12. Glossary*
