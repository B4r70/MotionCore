# Exercise Rating Feature

**Complexity:** Medium

## Summary

Subjektive Qualitätsbewertung pro Übung nach Abschluss aller Sätze. Drei Stufen (schlecht / mittel / gut) als farbige Outline-Icons. Eigenes SwiftData-Model `ExerciseRating`, Anzeige in StrengthDetailView, intelligente Insights in SummaryView bei auffälligen Mustern, Supabase-Sync.

## Scope

- Enthalten: Enum, SwiftData-Model, Rating-UI in ActiveWorkout, Badge in StrengthDetail, Rating-Zusammenfassung in statisticsCard, Insight-CalcEngine + Card in Summary, Supabase-DTO + Upload + Backup + SQL-Migration, UUID-Dedup
- Ausgeschlossen: Supabase-Rückimport (Read), Watch-Integration, Rating-Bearbeitung außerhalb des Workouts

## Affected Files

**Neue Dateien (5+1 SQL):**
- `MotionCore/Models/Core/ExerciseRating.swift`
- `MotionCore/Views/Workouts/Active/Components/ExerciseRatingCard.swift`
- `MotionCore/Views/Workouts/Active/Components/ExerciseRatingBadge.swift`
- `MotionCore/Services/Calculation/RatingInsightCalcEngine.swift`
- `MotionCore/Views/Summary/Components/SummaryRatingInsightCard.swift`
- `Documentation/SQL/exercise_ratings_migration.sql`

**Bestehende Dateien (11):**
- `MotionCore/Models/Types/StrengthTypes.swift`
- `MotionCore/Utils/Themes/TypesUI.swift`
- `MotionCore/Models/Core/StrengthSession.swift`
- `MotionCore/App/MotionCoreApp.swift`
- `MotionCore/Views/Workouts/Active/Components/ExerciseCompletedCard.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift`
- `MotionCore/Services/ViewModels/SummaryViewModel.swift`
- `MotionCore/Views/Summary/View/SummaryView.swift`
- `MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift`
- `MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift`
- `MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift`

## Risks

- **Schema-Änderung:** Neues SwiftData-Model `ExerciseRating` mit Relationship zu `StrengthSession`. Alle Properties haben Defaults → CloudKit-kompatibel.
- **ActiveWorkoutView:** ~2000 Zeilen → nur chirurgische Änderungen (1 State, 1 Funktion, heroCard-Branch).
- **CloudKit UUID-Default-Bug:** `ratingUUID: UUID = UUID()` → Step 2b fügt Dedup-Block hinzu.

---

## Implementation Steps

### Phase 1: Datenmodell

- [x] **Step 1** — Enum `ExerciseQualityRating` anlegen
  - `StrengthTypes.swift`: Enum mit `poor`/`neutral`/`good` + `icon: String`, `label: String` (nur `import Foundation`)
  - `TypesUI.swift`: `extension ExerciseQualityRating { var color: Color }` rot/orange/grün (analog `Intensity`)
  - STOPP → Build prüfen

- [x] **Step 2** — SwiftData-Model `ExerciseRating.swift` anlegen
  - `ratingUUID: UUID = UUID()`, `exerciseGroupKey: String = ""`, `exerciseNameSnapshot: String = ""`, `ratingRaw: String = "neutral"`, `ratedAt: Date = Date()`
  - `@Relationship(deleteRule: .nullify) var session: StrengthSession?`
  - Computed `var rating: ExerciseQualityRating` (get/set via `ratingRaw`)
  - Convenience-Init mit typisierten Parametern
  - `MotionCoreApp.swift`: `ExerciseRating.self` in `appSchema` aufnehmen
  - STOPP → Build prüfen

- [x] **Step 2b** — CloudKit UUID-Dedup für `ExerciseRating.ratingUUID`
  - `SupabaseFullBackupService.deduplicateAllSyncUUIDs()`: neuen Block nach ExerciseSet-Block einfügen
  - Analog zu `ExerciseSet.setUUID` (kein `syncedToSupabase`-Flag, nur UUID neu vergeben)
  - STOPP → Build prüfen

- [x] **Step 3** — Inverse Relationship auf `StrengthSession`
  - `@Relationship(deleteRule: .cascade, inverse: \ExerciseRating.session) var exerciseRatings: [ExerciseRating]? = []`
  - `var safeExerciseRatings: [ExerciseRating] { exerciseRatings ?? [] }`
  - STOPP → Build prüfen

### Phase 2: UI-Komponenten

- [x] **Step 4** — `ExerciseRatingBadge.swift` anlegen (~30 Zeilen)
  - `Image(systemName: rating.icon).font(.caption).foregroundStyle(rating.color)`
  - STOPP → Build prüfen

- [x] **Step 5** — `ExerciseRatingCard.swift` anlegen (~80 Zeilen)
  - Parameter: `exerciseName: String`, `existingRating: ExerciseQualityRating?`, `onRate: (ExerciseQualityRating) -> Void`, `onSkip: () -> Void`
  - `@State private var selectedRating: ExerciseQualityRating?` — bei `existingRating != nil` vorbelegen (pre-selected, änderbar)
  - `ForEach(ExerciseQualityRating.allCases)`: Outline-Icon + Label, nicht ausgewählt `.secondary`-Opacity, ausgewählt volle Farbe + `.scaleEffect`
  - Tap: Haptic `.light`, `selectedRating` setzen, `onRate` aufrufen, nach 0.5s `onSkip` auslösen
  - „Überspringen"-TextButton ruft `onSkip()` direkt auf
  - `.glassCard()` Styling
  - STOPP → Build prüfen

- [x] **Step 6** — `ExerciseCompletedCard` erweitern
  - Neue Parameter: `exerciseGroupKey: String?`, `existingRating: ExerciseQualityRating?`, `onRate: (ExerciseQualityRating) -> Void`
  - `ExerciseRatingCard` zwischen Beschreibungstext und „Nächste Übung"-Button einbauen
  - `onSkip` der RatingCard → ruft `onNextExercise()` auf (automatischer Übergang nach Rating)
  - STOPP → Build prüfen

### Phase 3: ActiveWorkoutView-Integration

- [x] **Step 7** — Rating-Logik in `ActiveWorkoutView`
  - Neuer State: `@State private var cachedExerciseRatings: [String: ExerciseQualityRating] = [:]`
  - Neue private Funktion `rateExercise(groupKey: String, rating: ExerciseQualityRating)`: Name-Snapshot holen, `ExerciseRating` erstellen, session setzen, `context.insert()`, Cache aktualisieren, `try? context.save()`
  - In `setupSession()`: bestehende Ratings aus `session.safeExerciseRatings` in `cachedExerciseRatings` laden
  - STOPP → Build prüfen

- [x] **Step 8** — heroCard-Branch anpassen
  - `ExerciseCompletedCard` mit neuen Parametern: `exerciseGroupKey: selectedExerciseKey`, `existingRating: selectedExerciseKey.flatMap { cachedExerciseRatings[$0] }`, `onRate: { rating in if let key = selectedExerciseKey { rateExercise(groupKey: key, rating: rating) } }`
  - `onNextExercise` bleibt: `{ selectedExerciseKey = nil }`
  - STOPP → Build + Simulator-Test

### Phase 4: StrengthDetailView-Anzeige

- [x] **Step 9** — Rating-Badges in Übungsliste
  - In `exercisesDetailSection`: neben jedem Übungsnamen Lookup via `session.safeExerciseRatings.first(where: { $0.exerciseGroupKey == groupKey })`
  - Falls vorhanden: `ExerciseRatingBadge(rating: rating.rating)` anzeigen
  - STOPP → Build prüfen

- [x] **Step 10** — Rating-Zusammenfassung in `statisticsCard`
  - Nur anzeigen wenn `!session.safeExerciseRatings.isEmpty`
  - Verteilung als kleine Icon-Reihe mit Zähler (z.B. ✓ 3 | — 1 | ✕ 1)
  - STOPP → Build prüfen

### Phase 5: SummaryView-Insights

- [x] **Step 11** — `RatingInsightCalcEngine.swift` anlegen (~120 Zeilen)
  - `import Foundation` (kein SwiftUI)
  - Nested `struct ExerciseInsight`: `exerciseName`, `exerciseGroupKey`, `insightType`, `consecutiveCount`, `suggestion`
  - Nested `enum InsightType`: `.struggling` / `.thriving`
  - `let consecutiveThreshold: Int` (Default 3)
  - `func analyze(sessions: [StrengthSession]) -> [ExerciseInsight]`: Ratings gruppieren, chronologisch sortieren, letzte N prüfen, Insights generieren, struggling zuerst
  - STOPP → Build prüfen

- [x] **Step 12** — `SummaryRatingInsightCard.swift` anlegen (~100 Zeilen)
  - Parameter: `insights: [RatingInsightCalcEngine.ExerciseInsight]`
  - Max. 3 Insights (CalcEngine liefert bereits struggling-first)
  - `.glassCard()` Styling
  - STOPP → Build prüfen

- [x] **Step 13** — `SummaryViewModel` erweitern
  - `private(set) var ratingInsights: [RatingInsightCalcEngine.ExerciseInsight] = []`
  - In `recalculate()`: `self.ratingInsights = RatingInsightCalcEngine().analyze(sessions: strength)`
  - STOPP → Build prüfen

- [x] **Step 14** — `SummaryView` erweitern
  - Zwischen Section 7 (SummaryBestExerciseCard) und Section 8 (StreakCard): `if !viewModel.ratingInsights.isEmpty { SummaryRatingInsightCard(insights: viewModel.ratingInsights) }`
  - STOPP → Build prüfen

### Phase 6: Supabase-Sync

- [x] **Step 15** — `SupabaseExerciseRatingDTO` + SQL-Migration
  - `SupabaseSessionModels.swift`: `struct SupabaseExerciseRatingDTO: Encodable` mit CodingKeys (`session_id`, `exercise_group_key`, `exercise_name_snapshot`, `rating`, `rated_at`)
  - `Documentation/SQL/exercise_ratings_migration.sql`: CREATE TABLE + Indices (siehe Konzept Abschnitt 6.2)
  - STOPP → Build prüfen

- [x] **Step 16** — `SupabaseSessionService.upload()` erweitern
  - Nach Sets-Upload: alte Ratings löschen (`deleteWhere exercise_ratings session_id=...`), neue als Batch hochladen
  - STOPP → Build prüfen

- [x] **Step 17** — `SupabaseFullBackupService` erweitern
  - Ratings-DTOs pro Session mappen und hochladen (analog zum Sets-Upload)
  - STOPP → Build + Supabase-Tabelle manuell prüfen

---

## Manual Verification

- [ ] Workout starten, Übung abschließen → Rating-Card erscheint
- [ ] Rating auswählen → Haptic, 0.5s Delay, automatisch nächste Übung
- [ ] „Überspringen" → kein Rating gespeichert, direkt zur nächsten Übung
- [ ] Workout resumed → ExerciseCompletedCard zeigt vorheriges Rating pre-selected
- [ ] StrengthDetailView: Rating-Badges und Zusammenfassung sichtbar
- [ ] SummaryView: nach 3+ gleichen Ratings erscheint Insight-Card
- [ ] Supabase: SQL-Migration ausführen, Upload verifizieren

---

## Progress

**Datum:** 2026-04-05
**Abgeschlossene Steps:** 1–17 (alle 17 Implementation Steps vollständig)

**Neue Dateien:**
- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/ExerciseRating.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/ExerciseRatingCard.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/ExerciseRatingBadge.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Services/Calculation/RatingInsightCalcEngine.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Summary/Components/SummaryRatingInsightCard.swift`
- `/Users/bartosz/Developments/MotionCore/Documentation/SQL/exercise_ratings_migration.sql`

**Geänderte Dateien:**
- `StrengthTypes.swift` — Enum `ExerciseQualityRating` hinzugefügt
- `TypesUI.swift` — `extension ExerciseQualityRating { var color }` hinzugefügt
- `StrengthSession.swift` — `exerciseRatings` Relationship + `safeExerciseRatings` hinzugefügt
- `MotionCoreApp.swift` — `ExerciseRating.self` in `appSchema` aufgenommen
- `ExerciseCompletedCard.swift` — neue Parameter + `ExerciseRatingCard` eingebaut
- `ActiveWorkoutView.swift` — `cachedExerciseRatings` State, `rateExercise()` Funktion, heroCard-Branch angepasst
- `StrengthDetailView.swift` — Rating-Badge in Übungsliste, Verteilungs-Row in statisticsCard
- `SummaryViewModel.swift` — `ratingInsights` Property + Berechnung in `recalculate()`
- `SummaryView.swift` — `SummaryRatingInsightCard` zwischen Section 7 und 8
- `SupabaseSessionModels.swift` — `SupabaseExerciseRatingDTO` hinzugefügt
- `SupabaseSessionService.swift` — Ratings-Upload in `upload(_:StrengthSession)`
- `SupabaseFullBackupService.swift` — Ratings-Dedup + Ratings-Upload in `uploadAllStrengthSessions`

**Bekannte offene Punkte:**
- Supabase: SQL-Migration `exercise_ratings_migration.sql` muss manuell im Supabase Dashboard ausgeführt werden
- Manual Verification noch ausstehend (Build in Xcode + Simulator-Test)
