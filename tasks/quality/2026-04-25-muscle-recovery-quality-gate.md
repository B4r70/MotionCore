# Quality Gate — MuscleRecoveryCalcEngine + Body-Tab

**Datum:** 2026-04-25
**Gesamturteil:** 🟡 Gelb → nach Fix ✅ Grün
**Geprüfte Dateien:** 9 neue + 3 geänderte

---

## Neue Dateien

### MuscleRecoveryTypes.swift ✅
- Standard-Header korrekt
- Alle drei Typen vollständig und korrekt
- `Identifiable`-Extension für `.sheet(item:)` vorhanden
- `recoveryColor(percent:)` als module-level `func` (korrekt für UIKit/SwiftUI-Trennung)
- 84 Zeilen — weit unter Limit

### MuscleRecoveryCalcEngine.swift ✅
- Pure struct, keine Side-Effects, kein State
- Session-Filter: `isCompleted == true` + 14-Tage-Fenster ✅
- Set-Filter: `isCompleted && reps > 0 && setKind == .work` ✅
- Decay: `pow(0.5, ageInDays / 7.0)` ✅
- Volumen-Referenz: `500.0` (nach Domain-Validation-Fix) ✅
- `rpeRecorded` zur Disambiguierung von `rpe == 0` ✅
- Secondary-Muskeln: 30% ✅
- Output-Reihenfolge: `[chest, back, shoulders, arms, legs, core, glutes]` ✅
- Keine `print`-Statements ✅
- 240 Zeilen ✅

### MuscleRecoveryDonut.swift ✅ (94 Zeilen)
### MuscleRecoveryCard.swift ✅ (291 Zeilen — nahe 400er-Grenze, akzeptabel)
### MuscleRecoveryDetailView.swift ✅ (244 Zeilen)

### BodyViewModel.swift ✅
- `@Observable` (nicht `ObservableObject`) ✅
- `private(set)` Properties ✅
- Logik-Wiederverwendung via `ReadinessViewModel` intern ✅
- 48 Zeilen ✅

### BodyView.swift ✅ (nach Fix)
- `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)` ✅
- `scrollViewContentPadding()` ✅
- `.task` + `.onChange(of: scenePhase)` Refresh-Trigger ✅
- `.sheet(item: $detailItem)` — korrekt, kein `isPresented` ✅
- `EmptyState()` ✅
- **BUGFIX angewendet:** `.environmentObject(appSettings)` am Sheet ergänzt (war zuvor fehlend → Crash)
- Preview mit `PreviewData.sharedContainer` + `AppSettings.shared` ✅

### SupabaseMuscleRecoverySnapshot.swift ✅
- Alle 20 Felder explizit in `CodingKeys` mit snake_case ✅
- Kein `related_session_uuid` ✅
- CodingKeys-Trap-Kommentar im Header ✅
- 66 Zeilen ✅

### SupabaseMuscleRecoveryService.swift ✅ (mit Anmerkung)
- `@MainActor final class` + Singleton ✅
- Fire-and-forget: kein crash, kein rethrow ✅
- `#if DEBUG print(...)` bei Fehler ✅
- Gibt `Bool` zurück → Aufrufer setzt UserDefaults nur bei Erfolg ✅
- **Anmerkung:** Verwendet `client.upsert(...)` statt `client.insert(...)` — funktional identisch, da `id` immer neue UUID → kein Conflict möglich. Kein Blocking Issue.

---

## Geänderte Dateien

### BaseView.swift ✅
- Tab-Enum: `case summary, workouts, stats, body, training` ✅
- Default-Tab bleibt `.summary` ✅
- Body-Tab korrekt zwischen Stats und Training eingefügt ✅
- `triggerDailyMuscleRecoverySnapshotIfNeeded()` in `.onAppear`-Delay + `.onChange(of: scenePhase)` ✅
- Kein duplizierter `scenePhase`-Modifier ✅
- 6-Uhr-Schwelle korrekt: `bySettingHour: 6` ✅
- UserDefaults-Key nur bei `success == true` gesetzt ✅

### SummaryViewModel.swift ✅
- `private(set) var recoveryAnalysis: MuscleRecoveryAnalysis? = nil` korrekt hinzugefügt ✅
- `MuscleRecoveryCalcEngine.analyze(sessions: strength)` in `recalculate(...)` ✅
- Keine bestehende Logik verändert ✅

### SummaryView.swift ✅
- `@State private var recoveryDetailItem: MuscleRecoveryAnalysis?` ✅
- `MuscleRecoveryCard(style: .compact)` direkt nach `ReadinessSummaryCard` ✅
- `.sheet(item: $recoveryDetailItem)` mit `.environmentObject(appSettings)` ✅
- Kein `.sheet(isPresented:)` ✅

---

## Gefundene und behobene Issues

| # | Schwere | Datei | Issue | Status |
|---|---|---|---|---|
| 1 | **Blocking** | `BodyView.swift` | `.sheet(item:)` für `MuscleRecoveryDetailView` ohne `.environmentObject(appSettings)` — würde crashen, weil DetailView `@EnvironmentObject var appSettings` deklariert | ✅ Direkt behoben |
| 2 | Minor | `SupabaseMuscleRecoveryService.swift` | `client.upsert(...)` statt `client.insert(...)` — funktional identisch (UUID immer neu), aber semantisch ungenau | Akzeptiert |

---

## Lessons-Check

- [x] Kein `.sheet(isPresented:)` — überall `.sheet(item:)` (nach Fix)
- [x] Alle DTO-Felder in `CodingKeys` explizit
- [x] Engine nicht als computed property in View
- [x] `ExerciseRating` unberührt
- [x] `PlanUpdateCalcEngine` unberührt

---

## Gesamturteil

**Grün nach Bugfix.** Der kritische `EnvironmentObject`-Crash in `BodyView.swift` wurde direkt behoben. Alle anderen Checks bestanden. Das Feature ist merge-bereit.

**Offene manuelle Tests (End-to-End):**
1. `Cmd+B` Build grün bestätigen
2. Body-Tab auf echtem Gerät / Simulator: Recovery-Card erscheint, Tap öffnet Detail-Sheet ohne Crash
3. SummaryView: Recovery-Card unter Readiness-Card, Tap → Sheet
4. Supabase-Snapshot: UserDefaults-Key löschen → App öffnen → 1 Snapshot in `public.muscle_recovery_snapshots`
5. Zweites App-Open am gleichen Tag → kein neuer Snapshot
