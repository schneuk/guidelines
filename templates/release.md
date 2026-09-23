# Release Manifest: [PROJECT_NAME] v[VERSION]
**Version:** `v[VERSION]`  
**Release Date:** [YYYY-MM-DD]  
**Git Tag:** `v[VERSION]`  
**Target Commit:** `[COMMIT_HASH]`

---

## 1. Summary of Changes
Brief high-level overview of milestone achievements and architectural additions.

## 2. Completed Tickets in this Release
| Ticket ID | Type | Title | Contributor |
| :--- | :--- | :--- | :--- |
| `FEAT-088` | feature | Implement Dynamic Weapon Cooldown & Overheat | Agent |
| `FEAT-092` | feature | Add HUD Overheat Gauge Component | Agent |
| `BUG-014`  | bug | Fix weapon swap race condition | Agent |

## 3. Detailed Changelog Entry
```markdown
## [v1.2.0] - YYYY-MM-DD
### Added
- Weapon cooldown and overheat mechanics (FEAT-088)
- HUD overheat gauge component (FEAT-092)

### Fixed
- Weapon swap race condition on rapid keyboard events (BUG-014)

### Performance
- Chunk heightmap generation optimized by 35%
```

## 4. Verification & QA Audit
- **Unit Test Suite:** Passed (X tests, 0 failures)
- **Integration Tests:** Passed
- **Build / Packaging:** Clean build exit code 0
