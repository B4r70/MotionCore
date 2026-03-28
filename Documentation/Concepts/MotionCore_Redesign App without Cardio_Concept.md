# MotionCore – Migrationskonzept: Cardio-Entfernung & Warmup-Integration

**Version:** 1.0  
**Datum:** 16.03.2026  
**Autor:** Bartosz Stryjewski / Claude  
**Status:** Entwurf – Freigabe ausstehend

---

## 1. Zusammenfassung

Cardio wird als eigenständiger Session-Typ entfernt. Cardio-Übungen (Crosstrainer, Ergometer etc.) werden zukünftig als **Aufwärmübungen** innerhalb des Krafttrainings geführt. Bestehende Cardio-Daten werden einmalig nach `StrengthSession` migriert. Statistiken und Rekorde werden auf Krafttraining umgebaut, bleiben aber strukturell erhalten.

### Entscheidungen (aus der Fragenrunde)

| # | Thema | Entscheidung |
|---|-------|-------------|
| 1 | Historische CardioSessions | Einmalige Migration zu StrengthSessions |
| 2 | Cardio als Aufwärmübung | Beides: neue ExerciseCategory `.warmup` + bestehender SetKind `.warmup` |
| 3 | Cardio-Felder (distance, speed, METs…) | In ExerciseSet als optionale Felder |
| 4 | Supabase `cardio_sessions` | Daten migrieren nach `strength_sessions`, dann Tabelle löschen |
| 5 | StatisticView + RecordView | Auf StrengthSession umbauen, Segmente behalten |
| 6 | CoreSession-Protokoll | Behalten für Strength + Outdoor (zukunftssicher) |
| 7 | SummaryCalcEngine / SummaryView | Multi-type behalten (Strength + Outdoor) |
| 8 | WorkoutTypeFilter in ListView | Cardio-Filter entfernen, Outdoor-Platzhalter für später |
| 9 | Export/Import | Komplett entfernen (CloudKit sichert) |
| 10 | AppSettings Cardio-Defaults | Alle entfernen |

---

## 2. Architektur-Übersicht: Vorher → Nachher

```
VORHER:                              NACHHER:
┌─────────────┐                      ┌─────────────┐
│CardioSession│ ──── entfällt ────>  │ (gelöscht)  │
└─────────────┘                      └─────────────┘

┌──────────────────┐                 ┌──────────────────┐
│ StrengthSession  │                 │ StrengthSession  │
│   └─ ExerciseSet │     ────>       │   └─ ExerciseSet │
│      (nur Kraft) │                 │      ├─ Kraft    │
└──────────────────┘                 │      └─ Warmup   │
                                     │         (duration,│
                                     │          distance)│
                                     └──────────────────┘

┌──────────────────┐                 ┌──────────────────┐
│ OutdoorSession   │     ────>       │ OutdoorSession   │ (bleibt unverändert)
└──────────────────┘                 └──────────────────┘
```

---

## 3. Phasenplan (7 Phasen)

### Phase 1: Datenmodell-Erweiterungen (Fundament)
### Phase 2: Daten-Migration (CardioSession → StrengthSession)
### Phase 3: UI für Warmup-Sets (neue Eingabefelder)
### Phase 4: Statistiken & Rekorde umbauen
### Phase 5: Cardio-Code entfernen (Cleanup)
### Phase 6: Supabase-Migration
### Phase 7: Finale Aufräumarbeiten

---

## Phase 1: Datenmodell-Erweiterungen

**Ziel:** Die bestehenden Models so erweitern, dass Warmup-Übungen abgebildet werden können.

### 1.1 ExerciseCategory erweitern

**Datei:** `ExerciseTypes.swift`

Neue Kategorie `.warmup` hinzufügen:

```swift
enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case compound = "compound"
    case isolation = "isolation"
    case bodyweight = "bodyweight"
    case cardio = "cardio"
    case stretching = "stretching"
    case core = "core"
    case warmup = "warmup"          // NEU: Aufwärmübungen

    var description: String {
        switch self {
        // ... bestehende cases ...
        case .warmup: return "Aufwärmen"
        }
    }

    var icon: String {
        switch self {
        // ... bestehende cases ...
        case .warmup: return "flame.fill"
        }
    }
}
```

> **Hinweis:** `SetKind.warmup` existiert bereits in `StrengthTypes.swift`. Die neue `ExerciseCategory.warmup` beschreibt die **Übung selbst** (z.B. "Crosstrainer" ist eine Warmup-Übung), während `SetKind.warmup` den **Satztyp** beschreibt. Beide arbeiten zusammen: Ein Warmup-Set einer Warmup-Übung bekommt beides.

### 1.2 ExerciseSet: Neue optionale Cardio-Felder

**Datei:** `ExerciseSet.swift`

Die Felder `duration` (Int) und `distance` (Double) existieren bereits im Model! Folgende Felder müssen **neu** hinzugefügt werden:

```swift
// MARK: - Cardio/Warmup-spezifische Felder (NEU)

var averageSpeed: Double = 0.0          // Durchschnittsgeschwindigkeit in m/min
var cardioDeviceRaw: Int = 0            // Gerät: 0=none, 1=Crosstrainer, 2=Ergometer
var trainingProgramRaw: String = ""     // Programm am Gerät (optional)
var difficulty: Int = 0                 // Schwierigkeitsgrad am Gerät (1-25, 0=nicht gesetzt)

// Typisierte Property für cardioDevice
var cardioDevice: CardioDevice {
    get { CardioDevice(rawValue: cardioDeviceRaw) ?? .none }
    set { cardioDeviceRaw = newValue.rawValue }
}

// Typisierte Property für trainingProgram
var trainingProgram: TrainingProgram {
    get { TrainingProgram(rawValue: trainingProgramRaw) ?? .manual }
    set { trainingProgramRaw = newValue.rawValue }
}
```

> **Wichtig für CloudKit:** Alle neuen Felder haben Default-Werte → CloudKit-kompatibel. Keine Migration der SwiftData-Schema nötig, da SwiftData neue optionale/default Felder automatisch hinzufügt.

### 1.3 ExerciseSet: isWarmupExercise Computed Property

```swift
/// Prüft ob dieses Set eine zeitbasierte Aufwärmübung ist
/// (statt gewichtsbasierter Kraftübung)
var isWarmupExercise: Bool {
    // Primär: SetKind ist warmup UND es gibt eine Dauer
    setKind == .warmup && duration > 0
}

/// Prüft ob dieses Set ein Kraft-Aufwärmsatz ist
/// (leichteres Gewicht vor Arbeitssätzen)
var isStrengthWarmup: Bool {
    setKind == .warmup && duration == 0
}
```

> **Unterscheidung:** Ein `.warmup`-Set mit `duration > 0` ist eine Cardio-Aufwärmübung (z.B. 15 Min Crosstrainer). Ein `.warmup`-Set mit `duration == 0` ist ein klassischer Aufwärmsatz mit leichtem Gewicht.

### 1.4 Exercise-Datenbank: Warmup-Übungen anlegen

In Supabase müssen Warmup-Übungen angelegt werden:

| Name | Kategorie | Equipment |
|------|-----------|-----------|
| Crosstrainer | warmup | machine |
| Ergometer | warmup | machine |
| Laufband | warmup | machine |
| Rudergerät | warmup | machine |
| Seilspringen | warmup | bodyweight |
| Jumping Jacks | warmup | bodyweight |

Diese Übungen bekommen in der Supabase-DB die `category = "warmup"`.

### 1.5 Betroffene Dateien in Phase 1

| Datei | Änderung |
|-------|----------|
| `ExerciseTypes.swift` | `ExerciseCategory.warmup` hinzufügen |
| `ExerciseSet.swift` | 4 neue Felder + computed properties |
| `SupabaseExerciseSetDTO` | 4 neue CodingKeys für Supabase-Sync |
| Supabase DB | Warmup-Übungen + Spalten in `exercise_sets` |

---

## Phase 2: Daten-Migration

**Ziel:** Bestehende `CardioSession`-Einträge in `StrengthSession`-Einträge mit Warmup-Sets umwandeln.

### 2.1 Migrationsstrategie

Jede `CardioSession` wird zu:
- **1× StrengthSession** (mit den Basis-Daten: Datum, Dauer, Kalorien, Herzfrequenz, etc.)
- **1× ExerciseSet** (mit SetKind `.warmup`, duration, distance, cardioDevice, etc.)

### 2.2 MigrationService erstellen

**Neue Datei:** `CardioMigrationService.swift`

```swift
@MainActor
final class CardioMigrationService {

    static func migrateAll(in context: ModelContext) throws -> Int {
        let cardioSessions = try context.fetch(FetchDescriptor<CardioSession>())
        guard !cardioSessions.isEmpty else { return 0 }

        var migrated = 0

        for cardio in cardioSessions {
            // 1. StrengthSession erstellen
            let strength = StrengthSession()
            strength.sessionUUID = cardio.sessionUUID    // UUID beibehalten!
            strength.date = cardio.date
            strength.duration = cardio.duration
            strength.calories = cardio.calories
            strength.bodyWeight = cardio.bodyWeight
            strength.heartRate = cardio.heartRate
            strength.maxHeartRate = cardio.maxHeartRate
            strength.notes = cardio.notes
            strength.isCompleted = true
            strength.isLiveSession = cardio.isLiveSession
            strength.startedAt = cardio.startedAt
            strength.completedAt = cardio.completedAt
            strength.perceivedExertion = cardio.perceivedExertion
            strength.energyLevelBefore = cardio.energyLevelBefore
            strength.intensityRaw = cardio.intensityRaw
            strength.deviceSource = cardio.deviceSource
            strength.healthKitWorkoutUUID = cardio.healthKitWorkoutUUID
            strength.syncedToSupabase = false           // Erneut hochladen
            strength.workoutTypeRaw = "cardio_migrated" // Markierung

            context.insert(strength)

            // 2. Warmup-Set erstellen
            let warmupSet = ExerciseSet()
            warmupSet.exerciseName = cardio.cardioDevice.description
            warmupSet.exerciseNameSnapshot = cardio.cardioDevice.description
            warmupSet.setNumber = 1
            warmupSet.setKindRaw = SetKind.warmup.rawValue
            warmupSet.duration = cardio.duration * 60    // Minuten → Sekunden
            warmupSet.distance = cardio.distance * 1000  // km → m
            warmupSet.averageSpeed = cardio.averageSpeed
            warmupSet.cardioDeviceRaw = cardio.cardioDeviceRaw
            warmupSet.trainingProgramRaw = cardio.trainingProgramRaw
            warmupSet.difficulty = cardio.difficulty
            warmupSet.isCompleted = true
            warmupSet.session = strength

            context.insert(warmupSet)

            // 3. Alte CardioSession löschen
            context.delete(cardio)

            migrated += 1
        }

        try context.save()
        return migrated
    }
}
```

### 2.3 Migration auslösen

**Datei:** `BaseView.swift` (im `onAppear`-Block)

```swift
// Einmalige Cardio-Migration
if !UserDefaults.standard.bool(forKey: "migration.cardioToStrength.done") {
    do {
        let count = try CardioMigrationService.migrateAll(in: context)
        if count > 0 {
            print("✅ \(count) CardioSessions migriert")
        }
        UserDefaults.standard.set(true, forKey: "migration.cardioToStrength.done")
    } catch {
        print("❌ Cardio-Migration fehlgeschlagen: \(error)")
    }
}
```

### 2.4 Betroffene Dateien in Phase 2

| Datei | Änderung |
|-------|----------|
| `CardioMigrationService.swift` | **NEU** – Migrationslogik |
| `BaseView.swift` | Migrations-Aufruf im `onAppear` |
| `StrengthTypes.swift` | Optional: `workoutTypeRaw` "cardio_migrated" als erkennbare Markierung |

---

## Phase 3: UI für Warmup-Sets

**Ziel:** Die ActiveWorkoutView und der Trainingsplan müssen Warmup-Übungen anders darstellen als Kraft-Übungen.

### 3.1 Kernproblem: Unterschiedliche Eingabefelder

| Feld | Kraft-Set | Warmup-Set (Cardio) |
|------|-----------|---------------------|
| Gewicht (kg) | ✅ | ❌ |
| Wiederholungen | ✅ | ❌ |
| RIR / RPE | ✅ | ❌ |
| Zielreps (Min/Max) | ✅ | ❌ |
| **Dauer (Min:Sek)** | ❌ (nur Planks) | ✅ **Hauptfeld** |
| **Distanz (km)** | ❌ | ✅ optional |
| **Gerät** | ❌ | ✅ optional |
| **Schwierigkeitsgrad** | ❌ | ✅ optional (Stufe am Gerät) |
| **Trainingsprogramm** | ❌ | ✅ optional |
| Pause nach Set | ✅ | ❌ (kein Rest-Timer) |

### 3.2 ActiveSetCard: Bedingte Anzeige

**Datei:** `ActiveSetCard.swift`

Die `ActiveSetCard` muss per `if/else` entscheiden, welche Felder angezeigt werden:

```swift
if set.isWarmupExercise {
    // Warmup-Modus: Dauer-Timer + optionale Felder
    WarmupSetInputView(set: set)
} else {
    // Kraft-Modus: Gewicht/Reps/RIR (wie bisher)
    StrengthSetInputView(set: set)
}
```

### 3.3 Neue View: WarmupSetInputView

**Neue Datei:** `WarmupSetInputView.swift`

Eingabefelder für eine Aufwärm-Übung innerhalb eines aktiven Workouts:

- **Dauer** (Minuten : Sekunden) – Haupteingabefeld, Timer-Funktion
- **Distanz** (km) – optional, numerisches Textfeld
- **Schwierigkeitsgrad** (1-25) – optional, Stepper oder Wheel
- **Trainingsprogramm** – optional, Picker mit bestehenden `TrainingProgram`-Werten
- **Geräteauswahl** – optional, Picker mit `CardioDevice`-Werten

### 3.4 Trainingsplan: Warmup-Übungen einplanen

**Dateien:** `TrainingFormView.swift`, `PlanExercisesSection.swift`, `SetConfigurationSheet.swift`

Wenn eine Übung mit `category == .warmup` zum Plan hinzugefügt wird:
- SetConfigurationSheet zeigt **Dauer + Distanz + Gerät** statt Gewicht/Reps/RIR
- Default-SetKind ist automatisch `.warmup`
- Kein Rest-Timer nach Warmup-Sets

### 3.5 ExercisePickerSheet: Warmup-Übungen priorisieren

Wenn der User eine Übung zum Plan hinzufügt, könnten Warmup-Übungen in einer eigenen Sektion stehen ("Aufwärmen") – optional aber empfehlenswert.

### 3.6 Betroffene Dateien in Phase 3

| Datei | Änderung |
|-------|----------|
| `WarmupSetInputView.swift` | **NEU** – Eingabe für Warmup-Sets |
| `ActiveSetCard.swift` | Bedingte Anzeige Kraft vs. Warmup |
| `ActiveWorkoutView.swift` | Warmup-Sets korrekt anzeigen |
| `SetConfigurationSheet.swift` | Warmup-Modus für Plan-Konfiguration |
| `PlanExercisesSection.swift` | Warmup-Übungen im Plan darstellen |
| `TrainingFormView.swift` | Warmup-Übungen hinzufügen können |
| `ExercisePickerSheet.swift` | Optional: Warmup-Sektion |
| `RestTimerManager.swift` | Kein Timer nach Warmup-Sets |
| `TemplateSetCard.swift` | Warmup-Sets im Plan anders darstellen |

---

## Phase 4: Statistiken & Rekorde umbauen

**Ziel:** StatisticView und RecordView von CardioSession auf StrengthSession umstellen. StatsAndRecordsView-Segmente bleiben erhalten.

### 4.1 StatisticCalcEngine umbauen

**Datei:** `StatisticCalcEngine.swift`

Komplett umschreiben: Statt `[CardioSession]` als Input nutzt die Engine jetzt `[StrengthSession]`.

**Neue Kennzahlen (Kraft-fokussiert):**

| Kennzahl | Berechnung |
|----------|------------|
| Gesamt Workouts | Anzahl StrengthSessions |
| Gesamt Kalorien | Summe aller session.calories |
| Gesamt Volumen | Summe aller session.totalVolume |
| ⌀ Herzfrequenz | Delegiert an CoreSessionCalcEngine |
| ⌀ Dauer | Delegiert an CoreSessionCalcEngine |
| ⌀ Sätze pro Session | Summe Sets / Anzahl Sessions |
| ⌀ Belastungsintensität | Delegiert an CoreSessionCalcEngine |
| Trainierte Muskelgruppen | Aus ExerciseSets → MuscleGroupMapper |

**Entfallende Cardio-Kennzahlen:**
- totalDistance, averageMETS, averageCaloricDensity
- trendDistance, trendDistanceDevice, trendCaloricDensity
- programDistribution, programData
- workoutCountDevice

### 4.2 RecordCalcEngine umbauen

**Datei:** `RecordCalcEngine.swift`

Statt `[CardioSession]` → `[StrengthSession]`.

**Neue Rekorde (Kraft-fokussiert):**

| Rekord | Berechnung |
|--------|------------|
| Höchstes Volumen (Session) | max(session.totalVolume) |
| Meiste Sätze (Session) | max(session.totalSets) |
| Schwerster Satz | max(set.weight) über alle Sessions |
| Längste Session | Delegiert an CoreSessionCalcEngine |
| Höchste Kalorien | Delegiert an CoreSessionCalcEngine |
| Niedrigstes/Höchstes Körpergewicht | Delegiert an CoreSessionCalcEngine |
| Höchste Herzfrequenz | Delegiert an CoreSessionCalcEngine |

**Entfallende Cardio-Rekorde:**
- bestErgometerWorkout, bestCrosstrainerWorkout
- fastestCardioDevice, longestDistanceWorkout

### 4.3 StatisticView umbauen

**Datei:** `StatisticView.swift`

```swift
// VORHER:
@Query(sort: \CardioSession.date, order: .reverse)
private var allWorkouts: [CardioSession]

// NACHHER:
@Query(sort: \StrengthSession.date, order: .reverse)
private var allSessions: [StrengthSession]
```

Grid-Cards auf die neuen Kraft-Kennzahlen anpassen. Cardio-spezifische Charts (Distanz-Trends, Donut für Programme) entfernen und durch Kraft-Charts ersetzen (Volumen-Trend, Muskelgruppen-Verteilung).

### 4.4 RecordView umbauen

**Datei:** `RecordView.swift`

Analog: Query auf `StrengthSession`, Cards auf Kraft-Rekorde anpassen.

### 4.5 StatsAndRecordsView: Segmente anpassen

**Datei:** `StatsAndRecordsView.swift`

Die drei Segmente bleiben, aber die Bezeichnungen ändern sich:

| Vorher | Nachher |
|--------|---------|
| "Statistiken" (Cardio) | "Statistiken" (Kraft – allgemein) |
| "Rekorde" (Cardio) | "Rekorde" (Kraft) |
| "Kraft" | "Details" oder "Übungen" (Übungs-spezifische 1RM etc.) |

### 4.6 StrengthStatisticView zusammenführen

Die bestehende `StrengthStatisticView` und die umgebaute `StatisticView` haben Überschneidungen. Optionen:
- **Option A:** StatisticView wird die "allgemeine" Kraft-Statistik, StrengthStatisticView wird die "Detail-Statistik" (übungsspezifisch, 1RM-Charts)
- **Option B:** Alles in einer View zusammenführen

**Empfehlung:** Option A – die Segmente "Statistiken" und "Kraft/Details" teilen den Inhalt sinnvoll auf.

### 4.7 Betroffene Dateien in Phase 4

| Datei | Änderung |
|-------|----------|
| `StatisticCalcEngine.swift` | Komplett umschreiben auf StrengthSession |
| `RecordCalcEngine.swift` | Komplett umschreiben auf StrengthSession |
| `StatisticView.swift` | Query + Cards auf Kraft umstellen |
| `RecordView.swift` | Query + Cards auf Kraft umstellen |
| `StatsAndRecordsView.swift` | Segment-Labels anpassen |
| `StatisticDeviceCard.swift` | Entfernen (Cardio-Geräte) |
| `StatisticDeviceRow.swift` | Entfernen |
| `RecordCard.swift` | Anpassen auf StrengthSession |
| `RecordDetailRow.swift` | Anpassen auf StrengthSession |

---

## Phase 5: Cardio-Code entfernen (Cleanup)

**Ziel:** Alle Dateien entfernen oder bereinigen, die nur wegen CardioSession existieren.

### 5.1 Dateien komplett löschen

| Datei | Grund |
|-------|-------|
| `CardioSession.swift` | Model wird nicht mehr benötigt |
| `CardioTypes.swift` | `Intensity` und `TrainingProgram` → siehe 5.2 |
| `SessionUI.swift` | CardioSession-Extensions |
| `WorkoutCard.swift` | Nur für CardioSession-Anzeige |
| `FormView.swift` | Cardio-Eingabeformular |
| `FormViewSection.swift` | Cardio-Formular-Sektionen (48KB!) |
| `Export.swift` | Export-Code komplett entfernt (deine Entscheidung) |
| `IODataManager.swift` | Import/Export komplett entfernt |
| `CardioMigrationService.swift` | Kann nach erfolgreicher Migration entfernt werden |

### 5.2 Enums umziehen: Intensity & TrainingProgram

`Intensity` wird weiterhin im `CoreSession`-Protokoll genutzt (auch von StrengthSession). Muss aus `CardioTypes.swift` in eine andere Datei verschoben werden:

**Empfehlung:** `Intensity` → `ExerciseTypes.swift` oder eigene `SharedTypes.swift`

`TrainingProgram` wird nur noch für Warmup-Sets benötigt (optionales Feld). Kann in `ExerciseTypes.swift` oder `StrengthTypes.swift` verschoben werden.

`CardioDevice` wird ebenfalls nur noch für Warmup-Sets benötigt. Gleiche Behandlung.

### 5.3 Dateien bereinigen (Cardio-Referenzen entfernen)

| Datei | Was entfernen |
|-------|---------------|
| `CoreSession.swift` | `CardioSession: CoreSession` Conformance entfernen |
| `CoreSessionCalcEngine.swift` | Keine Änderung nötig (generisch) |
| `BaseView.swift` | `draft`-Property (CardioSession), `showingAddCardio`, `selectedDeviceFilter`, Cardio-Sheets, `restoreCardioSession()` |
| `NewWorkoutSheet.swift` | `onCardioSelected`-Callback entfernen |
| `ListView.swift` | `WorkoutTypeFilter.cardio` entfernen, `allCardioWorkouts`-Query, `filteredCardioWorkouts`, `MixedWorkoutItem.cardio`, `deleteCardioSession()` |
| `ListViewWrapper.swift` | `selectedDeviceFilter`-Binding entfernen |
| `FilterSection.swift` | `selectedDeviceFilter`-Binding und CardioDevice-Filter |
| `FilterTypes.swift` | `CardioDevice` bleibt (wird von Warmup-Sets genutzt), aber Filter-UI entfällt |
| `SummaryCalcEngine.swift` | `cardioSessions`-Input entfernen, `cardioCalc` entfernen |
| `SummaryView.swift` | `@Query CardioSession` entfernen |
| `TrainingTypes.swift` | `WorkoutType.cardio` entfernen, `PlanType.cardio` entfernen |
| `MotionCoreApp.swift` | `CardioSession.self` aus Schema entfernen |
| `AppSettings.swift` | `defaultDevice`, `defaultProgram`, `defaultDuration`, `defaultDifficulty` entfernen |
| `WorkoutSettingsView.swift` | Komplett umbauen (nur Pause-Timer + Kraft-Defaults) |
| `MainSettingsView.swift` | Prüfen ob Cardio-Referenzen existieren |
| `DataSettingsView.swift` | `@Query CardioSession` + Export/Import-Buttons entfernen |
| `SupabaseSessionService.swift` | `upload(CardioSession)` entfernen |
| `SupabaseSessionModels.swift` | `SupabaseCardioSessionDTO` entfernen |
| `SupabaseResyncService.swift` | CardioSession-Resync-Block entfernen |
| `ActiveSessionManager.swift` | Cardio-Referenzen prüfen |
| `ActiveSessionState.swift` | Cardio-Referenzen prüfen |
| `SessionResumeState.swift` | Cardio-Referenzen prüfen |
| `PhoneSessionManager.swift` | Cardio-Referenzen prüfen |
| `PreviewModelContainer.swift` | CardioSession-Preview-Daten entfernen |
| `WorkoutSessionPreview.swift` | CardioSession-Preview-Daten entfernen |
| `TypesUI.swift` | `TrainingProgram`- und `CardioDevice`-Extensions bleiben (werden von Warmup genutzt) |
| `HealthKitManager.swift` | Prüfen ob Cardio-spezifischer Code existiert |
| `DataRepairService.swift` | Prüfen auf CardioSession-Referenzen |

### 5.4 SwiftData Schema-Änderung

**Datei:** `MotionCoreApp.swift`

```swift
// VORHER:
private static let appSchema = Schema([
    CardioSession.self,      // ← ENTFERNEN
    StrengthSession.self,
    OutdoorSession.self,
    ExerciseSet.self,
    Exercise.self,
    TrainingPlan.self
])

// NACHHER:
private static let appSchema = Schema([
    StrengthSession.self,
    OutdoorSession.self,
    ExerciseSet.self,
    Exercise.self,
    TrainingPlan.self
])
```

> **⚠️ ACHTUNG:** `CardioSession.self` darf erst aus dem Schema entfernt werden, NACHDEM die Migration (Phase 2) auf allen Geräten gelaufen ist! Empfehlung: Erst in einem späteren Release entfernen, oder einen Versions-Check einbauen.

---

## Phase 6: Supabase-Migration

### 6.1 Supabase-Tabelle `exercise_sets` erweitern

Neue Spalten für Warmup-Daten:

```sql
ALTER TABLE exercise_sets
ADD COLUMN average_speed DOUBLE PRECISION DEFAULT 0,
ADD COLUMN cardio_device INTEGER DEFAULT 0,
ADD COLUMN training_program TEXT DEFAULT '',
ADD COLUMN difficulty INTEGER DEFAULT 0;
```

### 6.2 Daten migrieren (cardio_sessions → strength_sessions)

SQL-Script für Supabase:

```sql
-- 1. CardioSessions als StrengthSessions einfügen
INSERT INTO strength_sessions (
    id, date, duration, calories, body_weight, heart_rate, max_heart_rate,
    notes, workout_type, intensity, perceived_exertion, energy_level_before,
    is_completed, is_live_session, started_at, completed_at, device_source,
    healthkit_workout_uuid
)
SELECT
    id, date, duration, calories, body_weight, heart_rate, max_heart_rate,
    notes, 'cardio_migrated', intensity, perceived_exertion, energy_level_before,
    is_completed, is_live_session, started_at, completed_at, device_source,
    healthkit_workout_uuid
FROM cardio_sessions;

-- 2. Warmup-Sets aus CardioSessions erzeugen
INSERT INTO exercise_sets (
    id, session_id, exercise_name, exercise_uuid, set_number, set_kind,
    duration, distance, average_speed, cardio_device, training_program,
    difficulty, is_completed
)
SELECT
    gen_random_uuid(), id,
    CASE cardio_device
        WHEN 1 THEN 'Crosstrainer'
        WHEN 2 THEN 'Ergometer'
        ELSE 'Cardio'
    END,
    '', 1, 'warmup',
    duration * 60,
    distance * 1000,
    CASE WHEN duration > 0 THEN (distance * 1000) / duration ELSE 0 END,
    cardio_device,
    training_program,
    difficulty,
    true
FROM cardio_sessions;

-- 3. Alte Tabelle löschen (erst nach Verifikation!)
-- DROP TABLE cardio_sessions;
```

### 6.3 SupabaseExerciseSetDTO erweitern

**Datei:** `SupabaseSessionModels.swift`

```swift
struct SupabaseExerciseSetDTO: Encodable {
    // ... bestehende Felder ...

    // NEU: Warmup-Felder
    let averageSpeed: Double
    let cardioDevice: Int
    let trainingProgram: String
    let difficulty: Int

    enum CodingKeys: String, CodingKey {
        // ... bestehende Keys ...
        case averageSpeed       = "average_speed"
        case cardioDevice       = "cardio_device"
        case trainingProgram    = "training_program"
        case difficulty
    }
}
```

---

## Phase 7: Finale Aufräumarbeiten

### 7.1 Watch App prüfen

**Dateien:** `WatchActiveWorkoutView.swift`, `WatchSessionManager.swift`, `IdleView.swift`, `ContentView.swift` (Watch)

Prüfen ob Cardio-Referenzen vorhanden sind. Die Watch-App zeigt aktuell nur aktive Workouts an – sollte mit Warmup-Sets kompatibel sein.

### 7.2 Widgets & Live Activities

**Dateien:** `MotionCoreWidgets.swift`, `MotionCoreWidgetsLiveActivity.swift`, `WorkoutActivityAttributes.swift`

Prüfen ob `CardioSession` referenziert wird. Die Live Activities sind aktuell auf den Rest-Timer ausgerichtet (Kraft) und sollten nicht betroffen sein.

### 7.3 Complications

**Dateien:** `StreakComplication.swift`, `WeeklyProgressComplication.swift`, `WatchComplicationService.swift`

Streak-Berechnung basiert auf SummaryCalcEngine → nach Phase 5 automatisch ohne Cardio.

### 7.4 Compiler-Check

Nach allen Änderungen: Build durchführen. Jede verbleibende Referenz auf `CardioSession` wird als Compile-Error auftauchen → systematisch abarbeiten.

---

## Risiken & Empfehlungen

### Risiko 1: CloudKit-Sync nach Schema-Änderung

**Problem:** Wenn `CardioSession` aus dem Schema entfernt wird, bevor alle Geräte migriert haben, können ältere App-Versionen crashen.

**Empfehlung:** 
1. Version N: Migration einbauen + `CardioSession` im Schema belassen (aber nicht mehr nutzen)
2. Version N+1: `CardioSession` aus Schema entfernen (nach sicherer Rollout-Phase)

### Risiko 2: Datenvolumen der Migration

**Problem:** Bei vielen CardioSessions könnte die einmalige Migration beim App-Start spürbar dauern.

**Empfehlung:** Migration asynchron mit einem Progress-Indicator durchführen.

### Risiko 3: Bestehende Supabase-Auswertungen

**Problem:** Falls du Supabase-Dashboards oder RPC-Funktionen hast die `cardio_sessions` abfragen.

**Empfehlung:** Alle RPCs und Views prüfen vor dem DROP TABLE.

---

## Reihenfolge & Abhängigkeiten

```
Phase 1 (Datenmodell)
   ↓
Phase 2 (Migration)     ← hängt von Phase 1 ab
   ↓
Phase 3 (Warmup-UI)     ← hängt von Phase 1 ab, kann parallel zu Phase 2
   ↓
Phase 4 (Statistiken)   ← kann parallel zu Phase 3
   ↓
Phase 5 (Cleanup)       ← hängt von Phase 2 + 4 ab
   ↓
Phase 6 (Supabase)      ← kann parallel zu Phase 5
   ↓
Phase 7 (Feinschliff)   ← nach allem anderen
```

**Geschätzter Aufwand:** 
- Phase 1: Klein (1 Session)
- Phase 2: Mittel (1 Session, aber sorgfältig testen)
- Phase 3: **Groß** (2-3 Sessions – UI-Arbeit)
- Phase 4: Mittel-Groß (2 Sessions)
- Phase 5: Mittel (1-2 Sessions – viele Dateien, aber mechanisch)
- Phase 6: Klein (1 Session)
- Phase 7: Klein (1 Session)

---

## Checkliste für Claude Code Agent

Dieses Dokument kann als Prompt-Basis für den Claude Code Agent (`motioncore_agent_instructions.md`) verwendet werden. Jede Phase kann als eigenständiger Prompt formuliert werden.
