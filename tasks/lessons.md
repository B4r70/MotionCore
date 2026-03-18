# Lessons Learned

Patterns and mistakes documented here should be avoided in future sessions.
Format: Date, Context, Mistake, Rule.

---

## Known Patterns

### iOS 18.4 Beta — Live Activity Timer
- **Context**: `Text(date, style: .timer)` in Live Activities
- **Mistake**: Freezes in background
- **Rule**: Always use `Text(timerInterval: start...end, countsDown: true)` with fixed anchor dates from `ContentState`

### Background Timers
- **Context**: `Timer.scheduledTimer` is suspended by iOS in background
- **Mistake**: Timer stops, UI shows wrong values
- **Rule**: Always use `Date()` anchor + elapsed time calculation for background-safe timers

### SwiftData + CloudKit Schema Changes
- **Context**: Schema changes in production
- **Mistake**: CloudKit schema cannot be easily changed
- **Rule**: Use a separate `dev.store` with DEBUG flag and disabled CloudKit for testing

### Shared Types
- **Context**: Defining new types
- **Mistake**: Types defined twice, causing conflicts
- **Rule**: Always check CLAUDE.md first to see if the type already exists