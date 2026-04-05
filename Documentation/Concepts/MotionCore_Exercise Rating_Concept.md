# Exercise Rating Feature — Konzeptdokument

## Übersicht

Subjektive Qualitätsbewertung pro Übung nach Abschluss aller Sätze. Drei Stufen (schlecht / mittel / gut) als farbige Outline-Icons. Wird als eigenes SwiftData-Model (`ExerciseRating`) gespeichert. Anzeige in StrengthDetailView und intelligente Insights in SummaryView bei auffälligen Mustern.

---

## 1. Datenmodell

### 1.1 Neues Model: `ExerciseRating`

**Datei:** `ExerciseRating.swift`

```swift
@Model
final class ExerciseRating {
    var ratingUUID: UUID = UUID()
    var exerciseGroupKey: String = ""        // groupKey der Übung (UUID-basiert)
    var exerciseNameSnapshot: String = ""    // Snapshot des Namens bei Erstellung
    var ratingRaw: String = "neutral"        // "poor" | "neutral" | "good"
    var ratedAt: Date = Date()               // Zeitpunkt der Bewertung

    @Relationship(deleteRule: .nullify)
    var session: StrengthSession?

    // Typisierter Zugriff
    var rating: ExerciseQualityRating {
        get { ExerciseQualityRating(rawValue: ratingRaw) ?? .neutral }
        set { ratingRaw = newValue.rawValue }
    }

    init(
        exerciseGroupKey: String = "",
        exerciseNameSnapshot: String = "",
        rating: ExerciseQualityRating = .neutral,
        ratedAt: Date = Date()
    ) {
        self.exerciseGroupKey = exerciseGroupKey
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.ratingRaw = rating.rawValue
        self.ratedAt = ratedAt
    }
}
```

### 1.2 Enum: `ExerciseQualityRating`

**Datei:** `StrengthTypes.swift` (dort ergänzen, passt zum Domain)

```swift
enum ExerciseQualityRating: String, Codable, CaseIterable {
    case poor = "poor"         // Schlecht — unsauber, abgebrochen, sehr schwer
    case neutral = "neutral"   // OK — geschafft, aber nicht überragend
    case good = "good"         // Stark — sauber, kontrolliert, Gewicht passt

    var icon: String {
        switch self {
        case .poor: return "xmark.circle"         // Outline
        case .neutral: return "minus.circle"      // Outline
        case .good: return "checkmark.circle"     // Outline
        }
    }

    var color: Color {
        switch self {
        case .poor: return .red
        case .neutral: return .orange
        case .good: return .green
        }
    }

    var label: String {
        switch self {
        case .poor: return "Schwer"
        case .neutral: return "OK"
        case .good: return "Stark"
        }
    }
}
```

### 1.3 Inverse Relationship auf `StrengthSession`

In `StrengthSession.swift` ergänzen:

```swift
@Relationship(deleteRule: .cascade, inverse: \ExerciseRating.session)
var exerciseRatings: [ExerciseRating]? = []

var safeExerciseRatings: [ExerciseRating] { exerciseRatings ?? [] }
```

**Wichtig:** `deleteRule: .cascade` — Ratings werden mit der Session gelöscht (gleich wie ExerciseMetrics).

---

## 2. UI-Komponenten

### 2.1 Rating-Card: `ExerciseRatingCard`

**Datei:** `ExerciseRatingCard.swift` (neue Datei, ~80 Zeilen)

Wird in `ActiveWorkoutView` angezeigt, wenn alle Sätze einer Übung abgeschlossen sind — **oberhalb** des "Nächste Übung"-Buttons in der `ExerciseCompletedCard`.

**Design:**
- Drei Outline-Icons nebeneinander (horizontal)
- Farbig: Rot (xmark.circle) | Orange (minus.circle) | Grün (checkmark.circle)
- Unter jedem Icon ein kurzes Label: "Schwer" | "OK" | "Stark"
- Nicht ausgewählt: `.secondary` opacity
- Ausgewählt: volle Farbe + leichte Scale-Animation
- Darunter ein kleiner "Überspringen"-Text-Button (sekundär)

```
┌─────────────────────────────────────┐
│    Wie lief "Bankdrücken"?          │
│                                     │
│   ✕         —         ✓            │
│  Schwer     OK      Stark          │
│                                     │
│         [ Überspringen ]            │
└─────────────────────────────────────┘
```

**Interaktion:**
- Tap auf ein Icon → speichert Rating sofort
- Kurze Haptic-Feedback (`.light`)
- Nach Auswahl: 0.5s Delay, dann automatisch `onNextExercise()`
- "Überspringen" → kein Rating gespeichert, direkt `onNextExercise()`

### 2.2 Integration in `ExerciseCompletedCard`

Die bestehende `ExerciseCompletedCard` wird erweitert. Neue Parameter:

```swift
struct ExerciseCompletedCard: View {
    let exerciseName: String?
    let exerciseGroupKey: String?           // NEU
    let existingRating: ExerciseQualityRating?  // NEU (falls bereits bewertet)
    let onRate: (ExerciseQualityRating) -> Void // NEU
    let onNextExercise: () -> Void

    // Body: Checkmark-Icon + Text + ExerciseRatingCard + Nächste-Übung-Button
}
```

### 2.3 Rating-Badge: `ExerciseRatingBadge`

**Datei:** `ExerciseRatingBadge.swift` (neue Datei, ~30 Zeilen)

Kleines Inline-Icon für die Anzeige in Listen (StrengthDetailView, ExercisesOverviewCard):

```swift
struct ExerciseRatingBadge: View {
    let rating: ExerciseQualityRating

    var body: some View {
        Image(systemName: rating.icon)
            .font(.caption)
            .foregroundStyle(rating.color)
    }
}
```

---

## 3. Integration in ActiveWorkoutView

### 3.1 Neuer State

```swift
@State private var cachedExerciseRatings: [String: ExerciseQualityRating] = [:]
```

Dictionary `groupKey → Rating` als lokaler Cache. Wird beim Speichern eines Ratings aktualisiert.

### 3.2 Rating-Speicherung

Neue private Funktion in `ActiveWorkoutView`:

```swift
private func rateExercise(groupKey: String, rating: ExerciseQualityRating) {
    let name = session.safeExerciseSets
        .first(where: { $0.groupKey == groupKey })?
        .exerciseNameSnapshot ?? groupKey

    let exerciseRating = ExerciseRating(
        exerciseGroupKey: groupKey,
        exerciseNameSnapshot: name,
        rating: rating
    )
    exerciseRating.session = session
    context.insert(exerciseRating)

    cachedExerciseRatings[groupKey] = rating

    Task { @MainActor in
        try? context.save()
    }
}
```

### 3.3 heroCard-Anpassung

Im `heroCard` ViewBuilder, der `ExerciseCompletedCard`-Branch:

```swift
} else if isSelectedExerciseComplete, !session.allSetsCompleted {
    ExerciseCompletedCard(
        exerciseName: selectedExerciseName,
        exerciseGroupKey: selectedExerciseKey,
        existingRating: selectedExerciseKey.flatMap { cachedExerciseRatings[$0] },
        onRate: { rating in
            if let key = selectedExerciseKey {
                rateExercise(groupKey: key, rating: rating)
            }
        },
        onNextExercise: { selectedExerciseKey = nil }
    )
}
```

---

## 4. Anzeige in StrengthDetailView

### 4.1 Rating-Badge in der Übungsliste

In `exercisesDetailSection`: Neben jedem Übungsnamen das `ExerciseRatingBadge` anzeigen, falls ein Rating existiert.

```swift
// Lookup: groupKey → Rating
let rating = session.safeExerciseRatings
    .first(where: { $0.exerciseGroupKey == groupKey })

if let rating {
    ExerciseRatingBadge(rating: rating.rating)
}
```

### 4.2 Rating-Zusammenfassung in der Header-Card

Optional: In der `statisticsCard` eine Zeile "Übungsbewertung" mit der Verteilung (z.B. "3× Stark, 1× OK, 1× Schwer") als kleine farbige Dots.

---

## 5. SummaryView — Intelligente Insights

### 5.1 Neue CalcEngine: `RatingInsightCalcEngine`

**Datei:** `RatingInsightCalcEngine.swift` (~120 Zeilen)

Analysiert Ratings über mehrere Sessions hinweg und erkennt Muster.

```swift
struct RatingInsightCalcEngine {

    struct ExerciseInsight {
        let exerciseName: String
        let exerciseGroupKey: String
        let insightType: InsightType      // .struggling | .thriving
        let consecutiveCount: Int          // Wie viele Sessions hintereinander
        let suggestion: String             // Empfehlungstext
    }

    enum InsightType {
        case struggling   // Mehrfach "poor" hintereinander
        case thriving     // Mehrfach "good" hintereinander
    }

    /// Schwelle: Ab wie vielen aufeinanderfolgenden gleichen Ratings
    /// wird ein Insight generiert?
    let consecutiveThreshold: Int

    init(consecutiveThreshold: Int = 3) {
        self.consecutiveThreshold = consecutiveThreshold
    }

    /// Analysiert alle Ratings aus den übergebenen Sessions.
    /// Gibt Insights für Übungen zurück, die auffällige Muster zeigen.
    func analyze(sessions: [StrengthSession]) -> [ExerciseInsight] {
        // 1. Alle Ratings sammeln, gruppiert nach exerciseGroupKey
        // 2. Pro Übung: letzte N Ratings chronologisch sortieren
        // 3. Prüfen ob die letzten consecutiveThreshold Ratings gleich sind
        // 4. "poor" × 3+ → struggling Insight mit Empfehlung "Gewicht reduzieren"
        // 5. "good" × 3+ → thriving Insight mit Empfehlung "Gewicht erhöhen"
        // 6. Sortierung: struggling zuerst, dann thriving
    }
}
```

**Empfehlungstexte (Deutsch):**
- Struggling: "{Übung} war die letzten {N} Einheiten schwierig. Vielleicht Gewicht reduzieren oder Technik prüfen?"
- Thriving: "{Übung} läuft seit {N} Einheiten stark! Zeit für mehr Gewicht oder Wiederholungen?"

### 5.2 Neue Card: `SummaryRatingInsightCard`

**Datei:** `SummaryRatingInsightCard.swift` (~100 Zeilen)

Wird in SummaryView zwischen Section 7 (Übung der Woche) und Section 8 (Streak) eingefügt.

**Design:**
- Nur sichtbar wenn mindestens 1 Insight vorhanden
- Struggling-Insights: rotes Outline-Icon + Übungsname + Empfehlung
- Thriving-Insights: grünes Outline-Icon + Übungsname + Motivation
- Maximal 3 Insights anzeigen (Top-Priorität: struggling vor thriving)
- `.glassCard()` Styling

### 5.3 Integration in SummaryViewModel

Neues Property:

```swift
var ratingInsights: [RatingInsightCalcEngine.ExerciseInsight] = []
```

In `recalculate()`:

```swift
let ratingEngine = RatingInsightCalcEngine()
ratingInsights = ratingEngine.analyze(sessions: strength)
```

---

## 6. Supabase-Sync

### 6.1 Neues DTO: `SupabaseExerciseRatingDTO`

In `SupabaseSessionModels.swift` ergänzen:

```swift
struct SupabaseExerciseRatingDTO: Encodable {
    let id: UUID
    let sessionId: UUID
    let exerciseGroupKey: String
    let exerciseNameSnapshot: String
    let ratingRaw: String
    let ratedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId          = "session_id"
        case exerciseGroupKey   = "exercise_group_key"
        case exerciseNameSnapshot = "exercise_name_snapshot"
        case ratingRaw          = "rating"
        case ratedAt            = "rated_at"
    }
}
```

### 6.2 Supabase-Tabelle: `exercise_ratings`

```sql
CREATE TABLE IF NOT EXISTS public.exercise_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.strength_sessions(id) ON DELETE CASCADE,
    exercise_group_key TEXT NOT NULL,
    exercise_name_snapshot TEXT NOT NULL DEFAULT '',
    rating TEXT NOT NULL DEFAULT 'neutral' CHECK (rating IN ('poor', 'neutral', 'good')),
    rated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_exercise_ratings_session ON public.exercise_ratings(session_id);
CREATE INDEX idx_exercise_ratings_exercise ON public.exercise_ratings(exercise_group_key);
```

### 6.3 Upload-Integration

In `SupabaseSessionService.upload()` nach dem Sets-Upload die Ratings mitschicken. In `SupabaseFullBackupService` ebenfalls berücksichtigen.

---

## 7. Implementierungsplan (Claude Code Steps)

### Phase 1: Datenmodell (Steps 1–3)

**Step 1** — Enum `ExerciseQualityRating` in `StrengthTypes.swift` anlegen
- Drei Cases: `poor`, `neutral`, `good`
- Properties: `icon`, `color`, `label`
- STOPP → Build prüfen

**Step 2** — Model `ExerciseRating.swift` anlegen
- SwiftData `@Model` mit allen Properties (siehe 1.1)
- `@Relationship(deleteRule: .nullify)` zu `StrengthSession`
- Defaults auf allen Properties (CloudKit-kompatibel)
- STOPP → Build prüfen

**Step 3** — Inverse Relationship auf `StrengthSession`
- `exerciseRatings: [ExerciseRating]? = []` mit `.cascade` + inverse
- `safeExerciseRatings` Accessor
- STOPP → Build prüfen

### Phase 2: UI-Komponenten (Steps 4–6)

**Step 4** — `ExerciseRatingBadge.swift` anlegen
- Kleine Inline-View mit Outline-Icon + Farbe
- ~30 Zeilen
- STOPP → Build prüfen

**Step 5** — `ExerciseRatingCard.swift` anlegen
- Drei horizontale Outline-Icons mit Labels
- `@State private var selectedRating: ExerciseQualityRating?`
- Callback `onRate: (ExerciseQualityRating) -> Void`
- Callback `onSkip: () -> Void`
- Haptic Feedback bei Auswahl
- 0.5s Delay nach Auswahl, dann automatisch weiter
- `.glassCard()` Styling
- STOPP → Build prüfen

**Step 6** — `ExerciseCompletedCard` erweitern
- Neue Parameter: `exerciseGroupKey`, `existingRating`, `onRate`
- `ExerciseRatingCard` zwischen Checkmark-Text und "Nächste Übung"-Button einbauen
- Falls `existingRating` vorhanden: Card im "bereits bewertet"-Modus anzeigen
- STOPP → Build prüfen

### Phase 3: ActiveWorkoutView-Integration (Steps 7–8)

**Step 7** — Rating-Logik in `ActiveWorkoutView`
- `@State private var cachedExerciseRatings: [String: ExerciseQualityRating] = [:]`
- `rateExercise(groupKey:rating:)` Funktion
- `onAppear`: bestehende Ratings aus Session in Cache laden
- STOPP → Build prüfen

**Step 8** — heroCard-Branch anpassen
- `ExerciseCompletedCard` mit neuen Parametern aufrufen
- `onRate` → `rateExercise()` + 0.5s Delay + `selectedExerciseKey = nil`
- STOPP → Build + Live-Test im Simulator prüfen

### Phase 4: StrengthDetailView-Anzeige (Steps 9–10)

**Step 9** — Rating-Badges in `exercisesDetailSection`
- Neben jedem Übungsnamen das `ExerciseRatingBadge` anzeigen
- Lookup über `session.safeExerciseRatings`
- STOPP → Build prüfen

**Step 10** — Rating-Zusammenfassung in Header
- In `statisticsCard`: Zeile mit Rating-Verteilung als farbige Dots
- Nur anzeigen wenn mindestens 1 Rating vorhanden
- STOPP → Build prüfen

### Phase 5: SummaryView-Insights (Steps 11–14)

**Step 11** — `RatingInsightCalcEngine.swift` anlegen
- Pure struct, kein SwiftUI-Import
- `analyze(sessions:)` → `[ExerciseInsight]`
- Logik: letzte N Sessions pro Übung prüfen, consecutive gleiche Ratings zählen
- Threshold default = 3
- STOPP → Build prüfen

**Step 12** — `SummaryRatingInsightCard.swift` anlegen
- Zeigt max. 3 Insights (struggling + thriving)
- Rotes/grünes Outline-Icon + Übungsname + Empfehlungstext
- `.glassCard()` Styling
- STOPP → Build prüfen

**Step 13** — `SummaryViewModel` erweitern
- Neues Property `ratingInsights`
- In `recalculate()`: `RatingInsightCalcEngine().analyze(sessions:)`
- STOPP → Build prüfen

**Step 14** — `SummaryView` erweitern
- `SummaryRatingInsightCard` zwischen Section 7 und 8 einfügen
- Nur sichtbar wenn `!viewModel.ratingInsights.isEmpty`
- STOPP → Build prüfen

### Phase 6: Supabase-Sync (Steps 15–17)

**Step 15** — `SupabaseExerciseRatingDTO` in `SupabaseSessionModels.swift`
- Encodable struct mit CodingKeys (snake_case)
- STOPP → Build prüfen

**Step 16** — `SupabaseSessionService.upload()` erweitern
- Nach Sets-Upload: Ratings als Batch hochladen
- Tabelle: `exercise_ratings`
- UPSERT auf `id`
- STOPP → Build prüfen

**Step 17** — `SupabaseFullBackupService` erweitern
- Ratings in den Backup-Flow aufnehmen
- Progress-Tracking aktualisieren
- STOPP → Build + Supabase-Tabelle manuell prüfen

---

## 8. Offene Entscheidungen

Keine — alle Fragen sind geklärt.

---

## 9. Betroffene Dateien (Übersicht)

| Datei | Aktion |
|---|---|
| `StrengthTypes.swift` | Enum `ExerciseQualityRating` ergänzen |
| `ExerciseRating.swift` | **NEU** — SwiftData Model |
| `StrengthSession.swift` | Inverse Relationship ergänzen |
| `ExerciseRatingCard.swift` | **NEU** — Rating-Auswahl UI |
| `ExerciseRatingBadge.swift` | **NEU** — Inline-Badge |
| `ExerciseCompletedCard.swift` | Erweitern mit Rating-Integration |
| `ActiveWorkoutView.swift` | Rating-State + Speicherlogik |
| `StrengthDetailView.swift` | Rating-Badges in Übungsliste |
| `RatingInsightCalcEngine.swift` | **NEU** — Pattern-Analyse |
| `SummaryRatingInsightCard.swift` | **NEU** — Insight-Card |
| `SummaryViewModel.swift` | Rating-Insights berechnen |
| `SummaryView.swift` | Insight-Card einbinden |
| `SupabaseSessionModels.swift` | DTO ergänzen |
| `SupabaseSessionService.swift` | Upload erweitern |
| `SupabaseFullBackupService.swift` | Backup erweitern |

---

## 10. Komplexität

**Medium** — 5 neue Dateien, 10 bestehende Dateien anpassen, 17 Steps. Keine Breaking Changes an bestehenden Models (nur Ergänzungen mit Defaults). CloudKit-kompatibel durch optionale Properties und Defaults.
