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

### SwiftData Model-Identifiers
- **Context**: Dictionary-Keys für SwiftData-`@Model`-Instanzen
- **Mistake**: `exercise.id` ist `PersistentIdentifier`, nicht `UUID`. `exercise.name` ist nicht unique (Duplikat-Keys). Beides führt zu Build-Fehlern oder Runtime-Crashes.
- **Rule**: `exercise.persistentModelID` (`PersistentIdentifier`) als Dictionary-Key verwenden. Für Lookups nach Inhalt: `exerciseName`-Feld des zugehörigen Value-Structs nutzen.

### @Observable ViewModels — CalcEngine Caching
- **Context**: CalcEngines als computed properties in Views → werden bei jedem Render neu berechnet
- **Mistake**: O(n·k) Operationen (z.B. `allAnalyses`) 4× pro Render-Zyklus wiederholt
- **Rule**: CalcEngines in `@Observable` ViewModels wrappen. `recalculate()` nur via `.task` + `.onChange(of:)` triggern. `allAnalyses` einmal aufrufen und als `let` speichern, dann alle abgeleiteten Counts daraus berechnen.

### Dictionary aus SwiftData-Ergebnissen
- **Context**: `Dictionary(uniqueKeysWithValues:)` mit SwiftData-Objekten
- **Mistake**: Closure-Return-Typ kann vom Compiler nicht inferiert werden → "ambiguous without type annotation"
- **Rule**: Immer expliziten Return-Typ annotieren: `trained.map { ex -> (PersistentIdentifier, [TrendPoint]) in ... }`