# MotionCore — Smart Progression, Readiness & Training Intelligence
## Concept-Dokument v1.1 (Codebase-validiert)

**Autor:** Barto Stryjewski (mit Claude)
**Datum:** 18. April 2026
**Vorherige Version:** v1.0 — basierte auf Annahmen über `ProgressionSettings`-Klasse, die nicht existiert
**Status:** Entwurf zur Freigabe für Claude-Code-Implementation

---

## 0. Was ist neu in v1.1

Nach Sichtung der echten Codebase wurden folgende Korrekturen gegenüber v1.0 vorgenommen:

1. **`ProgressionSettings`-Klasse existiert nicht.** Progressions-Felder liegen direkt auf `Exercise` und `ExerciseSet`. Migration wurde neu geschrieben.
2. **RIR-Tracking existiert bereits via `rpe`-Feld** auf `ExerciseSet` (computed `calculatedRIR = 10 - rpe`). Neues System überschreibt nicht, sondern nutzt das bestehende Feld.
3. **Bestehende `ProgressionCalcEngine` wird ersetzt** (Clean Slate / Option 1). Alte komplexe Analyse-Logik wird entfernt.
4. **`ProgressionAnalyseView` und zugehörige Views werden entfernt** — waren der eigentliche Pain Point.
5. **`ExerciseRating` bleibt vollständig bestehen** — war fälschlich als "Gut/Mittel/Schlecht zum Entfernen" interpretiert, ist aber Bartos aktuelles Bewertungssystem.
6. **`PlanUpdateCalcEngine` bleibt bestehen** — komplementär zu Smart Progression.
7. **`ExerciseEquipment`-Enum auf Exercise bleibt** — ist Equipment-*Art* (barbell/cable/...), komplementär zu neuem konkreten `StudioEquipment`.

---

## 1. Zielbild

MotionCore soll die Frage *"Trainiere ich gerade gut genug?"* nicht mehr dem Bauchgefühl überlassen. Die App nutzt vorhandene Historiendaten, HealthKit-Signale und ein minimales Feedback-Signal pro Übung (RIR am letzten Satz), um dem User **Entscheidungen abzunehmen statt Konfiguration aufzubürden**.

### 1.1 Leitprinzipien

1. **Datengetrieben statt konfigurationsgetrieben**
2. **Vorschlag statt Vorschrift**
3. **Readiness als Modulator, nicht als Gate**
4. **Plan als Leitplanke, nicht als Käfig**
5. **Ehrlichkeit über Ungewissheit**
6. **Config-in-Progress** — Übungs-Metadaten können aus dem aktiven Training heraus gepflegt werden

### 1.2 Was wird gelöst?

| Pain Point | Lösung |
|---|---|
| Progressionssettings zu komplex | Smart Progression als Default, minimale Konfiguration |
| Settings passen nicht zum Gerät | Studio-Equipment-Profil mit echten Sprüngen |
| Spontane Übungen ohne Settings | Smart Defaults + Quick-Config aus aktivem Training |
| Zu früh auf nächstes Gewicht gegangen | Automatische Rollback-Erkennung |
| Training nach Bauchgefühl in Stressphase | Readiness-Score aus HealthKit |
| Muskelgruppen vernachlässigt | Wochenvolumen-Ampel + Split-Hinweise |

---

## 2. Scope

### 2.1 Im Scope (v1)

- Smart Progression für Strength-Workouts
- Equipment-Profil mit einem Studio (Multi-Studio vorbereitet)
- Readiness-Score aus HealthKit
- Optional 2 Tap-Fragen
- RIR-Erfassung am letzten Satz (5-Button, gespeichert als `rpe`)
- Wochenvolumen-Ampel
- Dynamic-Split-Hinweise
- Session-Qualitätsscore
- **Ersatz der bestehenden `ProgressionCalcEngine`**
- **Entfernung aller alten Progression-Analyse-Views**
- **Entfernung unnötiger Felder auf `Exercise`**

### 2.2 Nicht im Scope (v1)

- Adaptive Learning pro User
- Periodisierung über Wochen
- Exercise-Swap-Vorschläge
- Cardio/E-Bike-Progression
- Multi-User
- Medikamenten-Liste (nur Schalter)
- `ExerciseRating`-System (bleibt unverändert)
- `PlanUpdateCalcEngine` (bleibt unverändert)

---

## 3. Datenmodell-Änderungen

### 3.1 Neue SwiftData-Modelle

#### 3.1.1 `Studio`

```swift
@Model
final class Studio {
    var id: UUID = UUID()
    var name: String = ""
    var isPrimary: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \StudioEquipment.studio)
    var equipment: [StudioEquipment]? = []

    var safeEquipment: [StudioEquipment] { equipment ?? [] }

    init(name: String = "", isPrimary: Bool = false) {
        self.name = name
        self.isPrimary = isPrimary
    }
}
```

#### 3.1.2 `StudioEquipment`

```swift
@Model
final class StudioEquipment {
    var id: UUID = UUID()
    var name: String = ""
    var equipmentTypeRaw: String = "machine"
    var startWeight: Double = 0.0
    var increment: Double = 2.5
    var minWeight: Double = 0.0
    var maxWeight: Double? = nil
    var intermediateIncrements: [Double] = []
    var notes: String = ""
    var createdAt: Date = Date()

    var studio: Studio?

    var equipmentType: StudioEquipmentType {
        get { StudioEquipmentType(rawValue: equipmentTypeRaw) ?? .machine }
        set { equipmentTypeRaw = newValue.rawValue }
    }

    init(name: String = "", equipmentType: StudioEquipmentType = .machine,
         startWeight: Double = 0.0, increment: Double = 2.5,
         intermediateIncrements: [Double] = []) {
        self.name = name
        self.equipmentTypeRaw = equipmentType.rawValue
        self.startWeight = startWeight
        self.increment = increment
        self.minWeight = startWeight
        self.intermediateIncrements = intermediateIncrements
    }
}

enum StudioEquipmentType: String, Codable, CaseIterable {
    case machine, cable, dumbbell, barbell, bodyweight, other
}
```

**Naming-Hinweis:** Enum heißt `StudioEquipmentType` (nicht `EquipmentType`), da `ExerciseEquipment` bereits in der Codebase existiert.

**Default-Seed für Bartos Studio:**

| Name | Type | Start | Incr | Intermediate | Max |
|---|---|---|---|---|---|
| Kabelzug | cable | 1.25 | 2.5 | [0.625, 1.25] | — |
| Kurzhanteln | dumbbell | 2.0 | 2.0 | [] | 24.0 |
| Beinpresse | machine | 0.0 | 7.0 | [3.5] | — |
| Brustpresse | machine | 0.0 | 7.0 | [3.5] | — |
| Latzugmaschine | machine | 0.0 | 7.0 | [3.5] | — |

LifeFitness-Startgewichte sind Platzhalter — Barto verifiziert und editiert im Setup-Screen.

#### 3.1.3 `ExerciseProgressionState`

```swift
@Model
final class ExerciseProgressionState {
    var id: UUID = UUID()
    var exerciseGroupKey: String = ""
    var workingWeight: Double = 0.0
    var targetReps: Int = 10
    var minTargetReps: Int = 8
    var maxTargetReps: Int = 12
    var progressionModeRaw: String = "smart"
    var lastProgressionDate: Date?
    var lastRollbackDate: Date?
    var previousWorkingWeight: Double?
    var consecutiveSuccessCount: Int = 0
    var consecutiveFailCount: Int = 0
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var progressionMode: ProgressionMode {
        get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
        set { progressionModeRaw = newValue.rawValue }
    }

    init(exerciseGroupKey: String = "", workingWeight: Double = 0.0) {
        self.exerciseGroupKey = exerciseGroupKey
        self.workingWeight = workingWeight
    }
}

enum ProgressionMode: String, Codable, CaseIterable {
    case smart, advanced, off
}
```

Match-Logik via `exerciseGroupKey` (wie `ExerciseRating`).

#### 3.1.4 `SessionReadiness`

```swift
@Model
final class SessionReadiness {
    var id: UUID = UUID()
    var sessionUUID: String?
    var capturedAt: Date = Date()

    var hrvScore: Double?
    var sleepScore: Double?
    var restingHRScore: Double?
    var activityScore: Double?

    var userEnergyLevel: Int?
    var userStressLevelRaw: String?

    var overallScore: Int = 50
    var isCalibrating: Bool = false

    init() {}
}
```

#### 3.1.5 `HealthBaseline`

```swift
@Model
final class HealthBaseline {
    var id: UUID = UUID()
    var metricTypeRaw: String = ""
    var rollingMean: Double = 0.0
    var rollingStdDev: Double = 0.0
    var sampleCount: Int = 0
    var lastUpdated: Date = Date()

    init(metricType: HealthMetricType = .hrv) {
        self.metricTypeRaw = metricType.rawValue
    }
}

enum HealthMetricType: String, Codable, CaseIterable {
    case hrv, sleep, restingHR, activity
}
```

### 3.2 Geänderte SwiftData-Modelle

#### 3.2.1 `Exercise` — Felder entfernen

**Entfernen:**
- `progressionStrategyRaw: String`
- `customProgressionStep: Double?`
- `progressionSessionsRequired: Int`
- `minDaysBetweenProgressions: Int`

Zusammen mit `init()`-Parametern und allen Referenzen in ViewModels, Seedern, Exportern.

**Behalten:**
- `progressionStep: Double = 2.5` (Fallback wenn kein Equipment)
- `repRangeMin: Int`, `repRangeMax: Int`
- `targetRIR: Int = 2` (Default für Set-Level)
- `lastProgressionDate: Date?`

**Hinzufügen:**
```swift
var studioEquipmentID: UUID? = nil       // Soft-Link
var customTargetReps: Int? = nil
var progressionModeRaw: String = "smart"
var configNotes: String = ""

var progressionMode: ProgressionMode {
    get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
    set { progressionModeRaw = newValue.rawValue }
}
```

**Wichtig — Soft-Link:** `studioEquipmentID` ist UUID-basierter Soft-Link, keine echte `@Relationship`. Vermeidet CloudKit-Inverse-Relationship-Zwang bei Many-to-One-Szenario.

#### 3.2.2 `ExerciseSet` — minimale Änderungen

**Behalten (unverändert):**
- `rpe: Int` — wird weiter genutzt, nun mit RIR-Semantik (User gibt 0-4 ein, gespeichert als `10 - RIR`)
- `calculatedRIR` — bleibt computed
- `targetRepsMin`, `targetRepsMax`, `targetRIR`

**Hinzufügen:**
```swift
var isLastSetOfExercise: Bool = false
```

**Wichtig:** KEIN `qualityRating`-Feld wird entfernt — v1.0 hatte das fälschlich angenommen. `ExerciseRating` ist separates Model und bleibt vollständig erhalten.

#### 3.2.3 `StrengthSession`

**Hinzufügen:**
```swift
var sessionQualityScore: Int? = nil
var sessionReadinessID: UUID? = nil
```

### 3.3 Zu entfernende Files (Clean Slate)

**Views:**
- `ProgressionAnalyseView.swift`
- `ProgressionDetailView.swift`
- `ProgressionBannerView.swift`
- `ProgressionOverviewCard.swift`
- `ProgressionExerciseCard.swift`
- `ProgressionInsightCard.swift`
- `ProgressionSectionHeader.swift`
- `ProgressionSummaryCard.swift`

**ViewModels:**
- `ProgressionViewModel.swift`

**CalcEngines:**
- `ProgressionCalcEngine.swift` (wird durch neue schlanke Version ersetzt)
- `ProgressionAnalyseCalcEngine.swift`

**Types:**
- `ProgressionTypes.swift` (mit Vorsicht: prüfen ob `TrendPoint` woanders genutzt wird, ggf. extrahieren)

**UI-Sektionen:**
- `ExerciseProgressionSection` in `FormViewSection.swift`
- Entsprechende State/Bindings in `SetConfigurationSheet.swift`
- Referenzen in `WorkoutAnalyseView.swift`

**Navigations-Einstieg:** `AnalyseSegment.progression` wird entfernt (Enum auf nur noch `.heatmap` reduziert oder Enum komplett weg, wenn nur ein Wert übrig).

### 3.4 Keine Datenmigration

- Alte Analyse-Daten existieren nicht persistent → kein Verlust
- Entfernte Exercise-Felder werden via SwiftData-Schema-Update transparent ignoriert
- `ExerciseProgressionState` wird **lazy initialisiert** beim ersten Set-Abschluss: `workingWeight = aktuelles Set-Gewicht`
- `StudioEquipment`-Zuordnung erfolgt manuell via Quick-Config durch Barto

### 3.5 Supabase-Backup

Neue Tabellen:
- `studios`
- `studio_equipment`
- `exercise_progression_states`
- `session_readiness`
- `health_baselines`

Erweitern:
- `exercises`: neue Spalten hinzufügen; alte Spalten in Supabase bleiben bestehen (werden vom Client ignoriert)
- `exercise_sets`: `is_last_set_of_exercise` hinzufügen
- `strength_sessions`: `session_quality_score`, `session_readiness_id`

---

## 4. Neue CalcEngines

### 4.1 Neue `ProgressionCalcEngine` (Ersatz)

```swift
struct ProgressionCalcEngine {
    struct Input {
        let progressionState: ExerciseProgressionState
        let lastSessionSets: [ExerciseSet]
        let studioEquipment: StudioEquipment?
        let exerciseFallbackStep: Double
        let readinessModifier: Double
        let currentSessionSetIndex: Int
        let currentSessionPreviousSets: [ExerciseSet]
    }

    struct Output {
        let suggestedWeight: Double
        let suggestedReps: Int
        let reasoning: ProgressionReasoning
        let isProgressionStep: Bool
        let isRollbackCandidate: Bool
    }

    enum ProgressionReasoning {
        case holdWeight, increaseWeight, bigIncrease
        case rollbackSuggested, firstSession, readinessReduced, noProgression
    }

    static func calculate(input: Input) -> Output { ... }
}
```

**Entscheidungsbaum:**

1. `currentSessionSetIndex > 0` → Werte vom vorherigen Satz der aktuellen Session
2. Keine Historie → `firstSession`
3. Modus `.off` oder `.advanced` → `noProgression`
4. Readiness-Modifier < 0.9 → `readinessReduced` (weight × modifier)
5. Letzte Session: alle Ziel-Reps + RIR 0-1 → `increaseWeight`
6. Letzte Session: alle Ziel-Reps + RIR ≥ 3 → `bigIncrease` (+2× increment)
7. Letzte Session: Reps unter Ziel + RIR 0 → `holdWeight`
8. Letzte Session: Reps unter Ziel + kürzliche Progression → `rollbackSuggested`

**Equipment-Aware Rounding:** `roundToValidWeight(weight, equipment)` — rundet auf gültige Sprünge. Zwischengewichte nur via Feintuning-Chips, nicht automatisch.

### 4.2 `ReadinessCalcEngine`

```swift
struct ReadinessCalcEngine {
    struct Input {
        let hrvToday: Double?
        let hrvBaseline: HealthBaseline?
        let sleepDurationToday: Double?
        let sleepBaseline: HealthBaseline?
        let restingHRToday: Double?
        let restingHRBaseline: HealthBaseline?
        let activityYesterday: Double?
        let activityBaseline: HealthBaseline?
        let userEnergy: Int?
        let userStressRaw: String?
        let takesCardioMedication: Bool
    }

    struct Output {
        let score: Int
        let label: ReadinessLabel
        let breakdown: [ReadinessFactor]
        let modifier: Double
        let isCalibrating: Bool
    }

    enum ReadinessLabel {
        case veryLow, low, normal, good, excellent
    }
}
```

**Gewichtung ohne Medikamente:** HRV 40% / Schlaf 30% / RuhePuls 20% / Aktivität 10%
**Gewichtung mit Medikation:** HRV 25% / Schlaf 40% / RuhePuls 15% / Aktivität 15% / User 5%

**Kalibrierung:** 28 Tage / 42 Tage bei Medikation. `sampleCount >= 14` pro Metrik.

**Modifier-Tabelle:**

| Score | Modifier |
|---|---|
| 0-29 | 0.85 |
| 30-49 | 0.92 |
| 50-69 | 1.00 |
| 70-84 | 1.00 |
| 85-100 | 1.05 |

### 4.3 `RollbackDetectionCalcEngine`

```swift
struct RollbackDetectionCalcEngine {
    struct Input {
        let progressionState: ExerciseProgressionState
        let last2Sessions: [[ExerciseSet]]
    }

    struct Output {
        let shouldSuggestRollback: Bool
        let previousWeight: Double?
        let reasoning: String
    }
}
```

Trigger: `lastProgressionDate` in letzten 2 Sessions UND beide Sessions `lastSet.reps < minTargetReps`.

### 4.4 `VolumeTargetCalcEngine`

```swift
struct VolumeTargetCalcEngine {
    struct Input {
        let setsLast7Days: [ExerciseSet]
        let trackedMuscleGroups: [MuscleGroup]
    }

    struct Output {
        let groups: [MuscleGroupVolumeStatus]
    }

    enum VolumeStatus {
        case belowMEV, inRange, aboveMAV
    }
}
```

**MEV/MAV-Defaults (Schoenfeld):**

| Muskelgruppe | MEV | MAV |
|---|---|---|
| Brust | 10 | 20 |
| Rücken breit | 10 | 22 |
| Rücken obere | 10 | 20 |
| Schultern vorne | 6 | 16 |
| Schultern seitlich | 8 | 20 |
| Schultern hinten | 10 | 20 |
| Bizeps | 8 | 20 |
| Trizeps | 8 | 18 |
| Quadrizeps | 10 | 20 |
| Beinbizeps | 8 | 18 |
| Gesäß | 8 | 16 |
| Bauch | 8 | 20 |

**Tracked Default aktiv:** Brust, Rücken (beide), Schultern (alle 3), Bizeps, Trizeps, Quadrizeps, Beinbizeps, Bauch
**Tracked Default inaktiv:** Waden, Nacken, Unterarm, Gesäß

### 4.5 `DynamicSplitHintCalcEngine`

```swift
struct DynamicSplitHintCalcEngine {
    struct Input {
        let recoveryScores: [MuscleGroup: Double]
        let lastTrainedDates: [MuscleGroup: Date]
        let trackedMuscleGroups: [MuscleGroup]
        let volumeStatus: [MuscleGroupVolumeStatus]
    }

    struct Output {
        let hints: [SplitHint]
    }
}
```

Max 3 Hints, priorisiert. Nur informativ.

### 4.6 `SessionQualityCalcEngine`

```swift
struct SessionQualityCalcEngine {
    struct Input {
        let session: StrengthSession
        let allSets: [ExerciseSet]
        let readiness: SessionReadiness?
    }

    struct Output {
        let score: Int
        let factors: [QualityFactor]
    }
}
```

**Gewichtung:**
- RIR-Ausbelastung (Anteil mit letztem RIR 0-2): 40%
- Ziel-Reps erreicht: 35%
- Readiness-adjustierte Progression: 25%

---

## 5. UI-Flows

### 5.1 Workout-Start (unverändert vs. v1.0)

### 5.2 Aktives Training — normaler Satz

Placeholder-Werte aus Engine im Gewicht-/Reps-Feld. Feintuning-Button für Zwischengewichte.

### 5.3 RIR-Sheet am letzten Satz

Bei "Satz abschließen" auf dem letzten Satz:
- Separates RIR-Sheet öffnet (nicht RestTimer-Integration)
- Kompakter RestTimer (~60% Höhe) oben im Sheet
- Einzeilige Button-Reihe: `0` `1` `2` `3` `4+`, Höhe ~48pt
- Kleiner Skip-Link
- Tap: `rpe = 10 - rirValue` (bei `4+` → `rpe = 6`), Sheet schließt
- Skip: `rpe` bleibt 0, Sheet schließt

**Keine Kollision mit `ExerciseRatingCard`:** Das RIR-Sheet erscheint *während* des letzten Satzes (beim Abschließen). `ExerciseRatingCard` erscheint *nach* der ganzen Übung (im `ExerciseCompletedCard`). Zeitlich getrennt.

### 5.4 Quick-Config aus ActiveWorkout

⚙️-Icon am Übungskopf → Sheet mit aktueller Equipment-Zuweisung und Link zur bestehenden ExerciseEditView (mit neuen Feldern).

### 5.5 Rollback-Flow (unverändert vs. v1.0)

### 5.6 Readiness-Expanded-View (unverändert vs. v1.0)

### 5.7 Wochenvolumen-Ampel (unverändert vs. v1.0)

Integration in bestehende `MuscleHeatmapView` via Toggle.

---

## 6. Equipment-Setup-Flow

Einmaliges Onboarding nach Update + jederzeit in Settings erreichbar. Default-Seeder legt Studio "Mein Studio" an mit Bartos 5 Geräten. Barto editiert nach Bedarf.

---

## 7. Phasen-Roadmap

### Phase 1 — Smart Progression

1. Neue Modelle: `Studio`, `StudioEquipment`, `ExerciseProgressionState` + Enums
2. `Exercise`-Cleanup (entfernte + neue Felder)
3. `ExerciseSet`-Erweiterung (`isLastSetOfExercise`)
4. **Entfernung aller Legacy-Progression-Files**
5. Neue schlanke `ProgressionCalcEngine`
6. `RollbackDetectionCalcEngine`
7. Studio-Setup + Onboarding + Default-Seeder
8. Medikamenten-Schalter in Settings (passiv)
9. Quick-Config-Sheet
10. Smart-Fill im aktiven Training
11. Feintuning-Button
12. RIR-Sheet am letzten Satz
13. Rollback-Flow
14. `SessionQualityCalcEngine`
15. Supabase-Schema

### Phase 2 — Readiness

(unverändert vs. v1.0)

### Phase 3 — Dynamic Hints & Volumen

(unverändert vs. v1.0)

---

## 8. Migration

### 8.1 Was wird gelöscht
- Keine persistenten Daten werden gelöscht
- Entfernte Exercise-Felder via SwiftData-Schema-Update transparent ignoriert
- `ExerciseRating` bleibt komplett erhalten

### 8.2 Was wird initialisiert
- Studio "Mein Studio" + Default-Equipment
- Exercises bekommen `progressionMode = .smart`, `studioEquipmentID = nil`
- `ExerciseProgressionState` lazy bei erstem Set-Abschluss

---

## 9. Offene Punkte

1. **`TrendPoint`-Typ:** Prüfen ob außerhalb von `ProgressionTypes.swift` genutzt (z.B. `StatisticTrendChart`), ggf. vor Löschung extrahieren
2. **`AnalyseSegment`-Enum:** Auf `.heatmap` reduzieren oder Enum entfernen
3. **`ProgressionBannerView` im aktiven Training:** Komplett entfernt, Smart-Fill übernimmt die Funktion
4. **Medikamenten-Schalter Location:** Claude-Code-Planner wählt Settings-Sektion
5. **Watch-Schema:** Neue Felder lesend einbinden
6. **`PlanUpdateCalcEngine`:** Bleibt intakt, keine Doppel-Hinweise bei ähnlichen Bedingungen

---

## 10. Glossar, Risiken, DoD

Siehe v1.0 — unverändert, mit zusätzlichen Risiken:

| Risiko | Mitigation |
|---|---|
| Löschung von `ProgressionCalcEngine` bricht Watch | Quality-Gate prüft Cross-Dependencies |
| `TrendPoint` woanders genutzt | Code-Search vor Löschung |
| Sessions zeigen Daten seltsam nach Feld-Entfernung | SwiftData lightweight migration |

---

**Ende Concept v1.1**
