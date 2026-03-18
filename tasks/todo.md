# Current Task: Progressions-Analyse Integration

## Ziel
Neue Views und Komponenten für die tiefere Progressions-Integration in ActiveWorkoutView und StrengthDetailView.

## Schritte

### Phase 1 — Neue Komponenten (reine UI)

- [x] **Schritt 1**: `MiniSparkline.swift` erstellen
  Pfad: `MotionCore/Views/Progression/Components/MiniSparkline.swift`
  Kompakte Inline-Chart-Linie (TrendPoint-Array) für Cards. Schwelle: >= 3 Punkte.

- [x] **Schritt 2**: `LastWorkoutCompareCard.swift` erstellen
  Pfad: `MotionCore/Views/Progression/Components/LastWorkoutCompareCard.swift`
  Vergleich aktuelles Workout vs. letztes Workout (Gewicht, Reps, Volumen). Körpergewichts-Edge-Case: 0 kg → "Körpergewicht". 1RM-Sparkline ausblenden wenn Körpergewicht.

### Phase 2 — CalcEngine-Erweiterung

- [x] **Schritt 3**: `ProgressionAnalyseCalcEngine.analysesForSession()` hinzufügen
  Gibt alle Analysen (als Array) zurück, deren `exerciseName` in der Session trainiert wurde.

### Phase 3 — Neue Views

- [x] **Schritt 4**: `ExerciseProgressionView.swift` erstellen
  Pfad: `MotionCore/Views/Progression/View/ExerciseProgressionView.swift`
  Detailview für eine einzelne Übung: LastWorkoutCompareCard + ProgressionInsightCard + MiniSparklines.

- [x] **Schritt 5**: `WorkoutAnalyseView.swift` erstellen
  Pfad: `MotionCore/Views/Progression/View/WorkoutAnalyseView.swift`
  Aggregierte Analyse für ein abgeschlossenes Workout: ProgressionOverviewCard (mit Session-Stats) + Liste der Übungen mit ProgressionExerciseCard. Tap → ExerciseProgressionView.

### Phase 4 — Integration in bestehende Views

- [x] **Schritt 6**: `StrengthDetailView.swift` anpassen
  - `@Query` für abgeschlossene StrengthSessions + alle Exercises hinzufügen
  - "Analyse" Button in `actionsSection` (nur sichtbar wenn `historicalSessions.count > 0`)
  - Sheet auf `WorkoutAnalyseView` zeigen

- [x] **Schritt 7**: `ActiveWorkoutView.swift` anpassen
  - Analyse-Button in `scrollContent` (nach ExerciseList, vor dem Bottom-Bar-Padding)
  - Nur sichtbar wenn `historicalSessions.count > 0` und kein `session.allSetsCompleted` (→ im aktiven Workout)
  - Sheet auf `WorkoutAnalyseView` zeigen
  - `refreshProgressionAnalyses()` NICHT bei Timer-Ticks aufrufen

## Regeln
- Alle neuen Dateien: Standard-Header kopieren von ProgressionOverviewCard.swift
- `.glassCard()` + `AnimatedBackground` + `scrollViewContentPadding()` in allen neuen Views
- `stableCount` zählt `.volatile` mit (konsistent mit ProgressionViewModel)
- `exerciseNameSnapshot` statt `exerciseName` für Cache-Keys
- Code-Kommentare Deutsch, Variablen/Methoden Englisch

## Review

### Abgeschlossen: 2026-03-18

#### Neue Dateien
- `MotionCore/Views/Progression/Components/MiniSparkline.swift` — kompakte Sparkline, >= 3 Punkte Schwelle
- `MotionCore/Views/Progression/Components/LastWorkoutCompareCard.swift` — Vergleich mit letztem Workout, Körpergewicht-Edge-Case, 1RM-Sparkline bei Gewichtsübungen
- `MotionCore/Views/Progression/View/ExerciseProgressionView.swift` — Detailview pro Übung
- `MotionCore/Views/Progression/View/WorkoutAnalyseView.swift` — aggregierte Workout-Analyse mit Query + ProgressionViewModel

#### Geänderte Dateien
- `MotionCore/Services/Calculation/ProgressionAnalyseCalcEngine.swift` — `analysesForSession()` hinzugefügt
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — @Query + Analyse-Button
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — Analyse-Button + Sheet

#### Wichtige Entscheidungen
- `sessionAnalyses` als `let analyses = sessionAnalyses` in `body` gecacht — verhindert dreifachen Engine-Aufruf
- `openExerciseDetail()` bricht ab wenn Übung nicht in `allExercises` gefunden (kein Crash durch fehlenden SwiftData-Initializer)
- `refreshProgressionAnalyses()` wird NICHT bei Timer-Ticks aufgerufen (vorhandene Logik bleibt unverändert)

## Verification

### Status: ⚠️ Issues Found

### Checked
- [x] No obvious compiler errors (Build successful: Cmd+B)
- [x] All interfaces consistently updated
- [x] New types SwiftData-compliant
- [x] No forgotten open TODOs in new files
- [x] No unintended changes to other files
- [x] File headers present and correct
- [x] No force-unwraps (!) in new files
- [x] Proper use of .glassCard() and AnimatedBackground
- [x] @Query predicates correctly formatted
- [x] SwiftUI Preview compatibility
- [x] Performance patterns correct (caching, no .filter/.map in View body)

### Issues Found

#### 1. ProgressionAnalyseCalcEngine.stableCount missing .volatile
   - **File**: `MotionCore/Services/Calculation/ProgressionAnalyseCalcEngine.swift`, Line 86-88
   - **Severity**: Critical
   - **Description**: The `stableCount` property only filters for `.stable` trend, but the rule specifies it should also count `.volatile` (to match ProgressionViewModel behavior). WorkoutAnalyseView correctly uses the expanded logic on line 72 (`analyses.filter { $0.trend == .stable || $0.trend == .volatile }`), but the engine itself is inconsistent.
   - **Current Code**:
     ```swift
     var stableCount: Int {
         allAnalyses.filter { $0.trend == .stable }.count
     }
     ```
   - **Should Be**:
     ```swift
     var stableCount: Int {
         allAnalyses.filter { $0.trend == .stable || $0.trend == .volatile }.count
     }
     ```
   - **Recommendation**: Update ProgressionAnalyseCalcEngine.stableCount to include .volatile, matching ProgressionViewModel line 45

### Manual Verification Required

After fixing the stableCount issue:
- [ ] Build in Xcode (`Cmd+B`)
- [ ] Check previews:
  - [ ] `MiniSparkline` preview (with >=3 data points, <3 data points)
  - [ ] `LastWorkoutCompareCard` preview (normal + bodyweight case)
  - [ ] `ExerciseProgressionView` preview
  - [ ] `WorkoutAnalyseView` preview
- [ ] Simulator test flows:
  - [ ] Complete a strength workout
  - [ ] Open StrengthDetailView → tap "Progressions-Analyse" button
  - [ ] Verify WorkoutAnalyseView displays correctly with ProgressionOverviewCard counts matching the filtered analysis counts
  - [ ] Tap an exercise in WorkoutAnalyseView
  - [ ] Verify ExerciseProgressionView loads with LastWorkoutCompareCard + ProgressionInsightCard + stats
  - [ ] During active workout: tap "Progressions-Analyse" button (should only show if historicalSessions.count > 0)
  - [ ] Verify rest timer and progression data coexist without performance issues
  - [ ] Verify empty state displays correctly when no historical sessions exist

### Files Involved
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Progression/Components/MiniSparkline.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Progression/Components/LastWorkoutCompareCard.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Progression/View/ExerciseProgressionView.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Progression/View/WorkoutAnalyseView.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Services/Calculation/ProgressionAnalyseCalcEngine.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Components/StrengthDetailView.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
