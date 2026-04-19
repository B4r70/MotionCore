# MotionCore — RecoveryCalcEngine Konzeptdokument

## 1. Zusammenfassung

Die `RecoveryCalcEngine` berechnet pro Muskelgruppe einen Erholungsstatus (0–100%), basierend auf den StrengthSessions der letzten 7 Tage. Sie nutzt Volumen, Intensität (RPE/RIR) und den Zeitabstand seit der letzten Belastung. Sekundäre Muskelbeteiligung wird mit 30% gewichtet. Die Engine berechnet intern auf `DetailedMuscle`-Ebene (39 Muskeln) und aggregiert im UI auf `MuscleGroup`-Ebene. Langfristig lernt die Engine individuell aus dem Trainingsverhalten.

---

## 2. Entscheidungen

| Frage | Entscheidung |
|---|---|
| Granularität | DetailedMuscle intern, MuscleGroup im UI |
| Zeitfenster | Letzte 7 Tage (kumulativ) |
| UI-Platzierung | TrainingDetailView + SummaryView |
| Darstellungsform | Prozent (0–100%) |
| Intensitäts-Gewichtung | Volumen + RPE/RIR kombiniert |
| Adaptives Modell | Ja, individuell lernen (Phase 2) |
| Sekundäre Beteiligung | 30% Gewichtung |
| Kontext-Hinweise | Nein, nur Score |
| Muskel-Auflösung | MuscleHeatmapCalcEngine-Fallback-Kette wiederverwenden |
| Architektur | Eigene RecoveryCalcEngine (standalone) |

---

## 3. Architektur

### 3.1 Neue Dateien

```
RecoveryCalcEngine.swift     — Pure struct, Berechnung
RecoveryTypes.swift          — Ergebnis-Typen
SummaryRecoveryCard.swift    — SummaryView-Card
PlanRecoveryCard.swift       — TrainingDetailView-Card
```

### 3.2 Bestehende Dateien (Änderungen)

```
TrainingDetailView.swift     — PlanRecoveryCard einbinden (zwischen PlanStatisticsCard und PlanUpdateBanner)
SummaryView.swift            — SummaryRecoveryCard einbinden (nach Muskel-Heatmap)
SummaryViewModel.swift       — RecoveryCalcEngine aufrufen, Ergebnisse cachen
```

### 3.3 Kein neues SwiftData-Model in Phase 1

Die Engine berechnet alles on-the-fly aus bestehenden `StrengthSession`/`ExerciseSet`-Daten. Kein neues persistentes Model nötig. Das adaptive Modell (Phase 2) wird später ein leichtgewichtiges Model oder UserDefaults-Speicher benötigen.

---

## 4. Datenmodell — RecoveryTypes.swift

```swift
import Foundation

// MARK: - Recovery-Score pro DetailedMuscle

struct MuscleRecoveryData: Identifiable {
    let id: String                      // = DetailedMuscle.rawValue
    let muscle: DetailedMuscle
    let recoveryPercent: Double         // 0.0–100.0 (100 = voll erholt)
    let lastTrainedDate: Date?          // Wann zuletzt belastet
    let totalFatigueScore: Double       // Kumulative Ermüdung (intern)
    
    /// Deutscher Anzeigename — Forwarding auf DetailedMuscle.displayName
    var displayName: String { muscle.displayName }
    
    /// Zugehörige MuscleGroup (für Aggregation)
    var muscleGroup: MuscleGroup { muscle.parentGroup }
}

// MARK: - Aggregierter Recovery-Score pro MuscleGroup

struct MuscleGroupRecoveryData: Identifiable {
    let id: String                      // = MuscleGroup.rawValue
    let muscleGroup: MuscleGroup
    let recoveryPercent: Double         // 0.0–100.0 (Durchschnitt der DetailedMuscles)
    let muscleDetails: [MuscleRecoveryData]  // Einzelne Muskeln in dieser Gruppe
    let lastTrainedDate: Date?          // Neuestes Datum aus den Details
    
    var displayName: String { muscleGroup.description }
    
    /// Sortier-Helfer: niedrigste Erholung zuerst
    var isFullyRecovered: Bool { recoveryPercent >= 95.0 }
}

// MARK: - Gesamt-Analyse

struct RecoveryAnalysis {
    let analysisDate: Date
    let muscleGroupScores: [MuscleGroupRecoveryData]    // Alle MuscleGroups
    let detailedScores: [MuscleRecoveryData]             // Alle 39 DetailedMuscles
    
    /// Sortiert nach niedrigstem Recovery-Score (am meisten ermüdet zuerst)
    var leastRecoveredGroups: [MuscleGroupRecoveryData] {
        muscleGroupScores
            .filter { $0.recoveryPercent < 95.0 }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
    }
    
    /// Alle voll erholten Gruppen
    var fullyRecoveredGroups: [MuscleGroupRecoveryData] {
        muscleGroupScores.filter { $0.isFullyRecovered }
    }
    
    /// Durchschnittliche Gesamterholung (über alle trainierten Gruppen)
    var overallRecoveryPercent: Double {
        let trained = muscleGroupScores.filter { $0.lastTrainedDate != nil }
        guard !trained.isEmpty else { return 100.0 }
        return trained.map(\.recoveryPercent).reduce(0, +) / Double(trained.count)
    }
}

// MARK: - Plan-spezifische Erholung

struct PlanRecoveryAnalysis {
    let plan: TrainingPlan
    let involvedGroups: [MuscleGroupRecoveryData]   // Nur die im Plan vorkommenden Gruppen
    
    /// Niedrigster Recovery-Score unter den Plan-Muskeln
    var lowestRecoveryPercent: Double {
        involvedGroups.map(\.recoveryPercent).min() ?? 100.0
    }
    
    /// Durchschnittlicher Recovery-Score der Plan-Muskeln
    var averageRecoveryPercent: Double {
        guard !involvedGroups.isEmpty else { return 100.0 }
        return involvedGroups.map(\.recoveryPercent).reduce(0, +) / Double(involvedGroups.count)
    }
    
    /// Gibt true zurück wenn alle involvierten Muskeln ≥ 80% erholt sind
    var isReadyToTrain: Bool {
        involvedGroups.allSatisfy { $0.recoveryPercent >= 80.0 }
    }
}
```

---

## 5. Berechnungslogik — RecoveryCalcEngine.swift

### 5.1 Signatur

```swift
struct RecoveryCalcEngine {

    // MARK: - Konstanten (Phase 1: statisch, Phase 2: adaptiv)

    /// Basis-Erholungszeiten in Stunden pro MuscleGroup
    /// Große Muskeln brauchen länger, kleine erholen sich schneller
    static let baseRecoveryHours: [MuscleGroup: Double] = [
        .chest:     60,     // 2.5 Tage
        .back:      72,     // 3 Tage
        .shoulders: 48,     // 2 Tage
        .arms:      48,     // 2 Tage
        .legs:      72,     // 3 Tage
        .glutes:    72,     // 3 Tage
        .core:      36,     // 1.5 Tage
        .other:     48,     // 2 Tage (Nacken etc.)
        .fullBody:  72      // 3 Tage
    ]

    /// Sekundäre Muskelbeteiligung — Gewichtungsfaktor
    static let secondaryWeight: Double = 0.30

    // MARK: - Haupt-Analyse (globaler Recovery-Status)

    func analyze(sessions: [StrengthSession]) -> RecoveryAnalysis { ... }

    // MARK: - Plan-spezifische Analyse

    func analyzeForPlan(
        plan: TrainingPlan,
        sessions: [StrengthSession]
    ) -> PlanRecoveryAnalysis { ... }
}
```

### 5.2 Algorithmus — `analyze(sessions:)`

```
Eingabe:  [StrengthSession] (alle Sessions)
Ausgabe:  RecoveryAnalysis

1. Sessions filtern: nur letzte 7 Tage, nur isCompleted == true

2. Pro Session → Pro ExerciseSet (nur work-Sets, isCompleted):
   a) DetailedMuscles auflösen via resolveDetailedMuscles() 
      (identische Fallback-Kette wie MuscleHeatmapCalcEngine)
   b) Ermüdungswert (fatigue) pro Set berechnen:
      
      fatiguePerSet = volumeFactor × intensityFactor
      
      volumeFactor = effectiveWeight × reps  (normalisiert auf 0–1 Skala)
        → effectiveWeight = set.weight > 0 ? set.weight : session.bodyWeight (Fallback 70kg)
      intensityFactor = intensityFromRIR(set)  (0.5–1.5 Skala)
      
   c) Primary-Muskeln: volles fatigue
      Secondary-Muskeln: fatigue × 0.30

3. Pro DetailedMuscle: kumulative fatigue über alle Sets der letzten 7 Tage
   → Dictionary [DetailedMuscle: (totalFatigue: Double, lastTrainedDate: Date)]

4. Recovery-Score berechnen:
   
   Für jeden DetailedMuscle mit Belastung:
   
   hoursSinceLastTraining = Date().timeIntervalSince(lastTrainedDate) / 3600
   baseHours = baseRecoveryHours[muscle.parentGroup]
   
   // Ermüdung skaliert die benötigte Erholungszeit
   // Höhere kumulative Ermüdung → längere Erholung nötig
   adjustedRecoveryHours = baseHours × fatigueMuliplier(totalFatigue)
   
   recoveryPercent = min(100, (hoursSinceLastTraining / adjustedRecoveryHours) × 100)

5. DetailedMuscle-Scores aggregieren zu MuscleGroup:
   recoveryPercent(MuscleGroup) = Durchschnitt aller DetailedMuscle-Scores in der Gruppe
   (Nur Muskeln mit tatsächlicher Belastung fließen ein — untrainierte = 100%)

6. RecoveryAnalysis zusammenbauen und zurückgeben
```

### 5.3 Hilfsfunktionen

```swift
// MARK: - Intensität aus RPE/RIR

/// Wandelt RPE/RIR in einen Intensitätsfaktor um (0.5–1.5)
/// Niedriger RIR (= nah am Versagen) → höherer Faktor → mehr Ermüdung
private func intensityFromRIR(_ set: ExerciseSet) -> Double {
    let rir: Int
    if set.rpe > 0 {
        rir = max(0, 10 - set.rpe)      // RPE 10 → RIR 0, RPE 7 → RIR 3
    } else if set.targetRIR > 0 {
        rir = set.targetRIR              // Fallback auf Plan-Target
    } else {
        return 1.0                       // Kein RPE/RIR → neutraler Faktor
    }
    
    // RIR 0 (Versagen) → 1.5, RIR 4+ → 0.5, linear dazwischen
    // Formel: 1.5 - (rir × 0.25), geclamped auf [0.5, 1.5]
    return max(0.5, min(1.5, 1.5 - Double(rir) * 0.25))
}

// MARK: - Volumen-Normalisierung

/// Normalisiert das Volumen eines Sets auf eine 0–1 Skala
/// Bei Bodyweight-Übungen (weight == 0) wird session.bodyWeight als Ersatz genutzt,
/// Fallback auf 70kg falls auch kein Körpergewicht eingetragen.
private func normalizedVolume(weight: Double, reps: Int, sessionBodyWeight: Double) -> Double {
    let effectiveWeight = weight > 0 ? weight : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0)
    let rawVolume = effectiveWeight * Double(reps)
    let referenceVolume = 1000.0     // Typischer Work-Set: ~100kg × 10 Reps
    return min(1.0, rawVolume / referenceVolume)
}

// MARK: - Ermüdungs-Multiplikator

/// Skaliert die Erholungszeit basierend auf kumulativer Ermüdung
/// Wenig Ermüdung (1 leichter Satz) → kaum Verlängerung
/// Hohe Ermüdung (viele schwere Sätze) → bis zu 1.5× längere Erholung
private func fatigueMultiplier(_ totalFatigue: Double) -> Double {
    // totalFatigue ist kumulativ über alle Sets der Woche
    // Typischer Bereich: 0.5 (1 leichter Satz) bis 5.0+ (schweres Volumen-Training)
    // Mapping: 0 → 0.8×, 2.0 → 1.0×, 5.0+ → 1.5×
    let normalized = min(totalFatigue / 5.0, 1.0)
    return 0.8 + (normalized * 0.7)     // Bereich: 0.8 – 1.5
}

// MARK: - Muskel-Auflösung (Wiederverwendung)

/// Identische Fallback-Kette wie MuscleHeatmapCalcEngine.resolveDetailedMuscles()
/// TODO: In Phase 2 in einen SharedHelper extrahieren, wenn sich das Pattern bewährt
private func resolveDetailedMuscles(for set: ExerciseSet, type: MuscleType) -> [DetailedMuscle] {
    // 1. exercise?.detailedPrimaryMuscles (feingranular)
    // 2. exercise?.primaryMuscles → alle DetailedMuscle mit passendem parentGroup
    // 3. ExerciseSet.primaryMuscleGroup (Name-basiert, letzter Fallback)
    // → Exakt dieselbe Implementierung wie in MuscleHeatmapCalcEngine
}
```

### 5.4 Plan-Analyse — `analyzeForPlan(plan:sessions:)`

```
Eingabe:  TrainingPlan, [StrengthSession]
Ausgabe:  PlanRecoveryAnalysis

1. Globale RecoveryAnalysis berechnen (via analyze())

2. Aus plan.safeTemplateSets die involvierten MuscleGroups ermitteln:
   Für jeden TemplateSet → resolveDetailedMuscles (primary + secondary)
   → Set<MuscleGroup> aller involvierten Gruppen

3. Aus der globalen Analyse nur die relevanten MuscleGroupRecoveryData filtern

4. PlanRecoveryAnalysis zusammenbauen (inkl. isReadyToTrain, lowestRecovery, etc.)
```

---

## 6. Adaptives Modell (Phase 2 — später)

### 6.1 Konzept

Die Engine lernt aus dem tatsächlichen Trainingsverhalten:
- Wenn Barto regelmäßig Brust nach 48h statt 60h wieder trainiert und dabei gute RPE/RIR-Werte erzielt, senkt die Engine die Basis-Erholungszeit für Brust.
- Umgekehrt: Trainiert er nach 48h und die Performance sinkt (geringere Gewichte/Reps im Vergleich), erhöht die Engine die Erholungszeit.

### 6.2 Datenbasis

```
Signal "erholt genug":
  - Session gestartet für MuscleGroup X
  - Performance ≥ vorherige Session (Gewicht/Reps stabil oder besser)
  → Tatsächliche Pause (Stunden) war offenbar ausreichend
  → Basis-Erholungszeit für X kann Richtung tatsächliche Pause tendieren

Signal "zu früh":
  - Session gestartet für MuscleGroup X  
  - Performance < vorherige Session (Gewicht/Reps gesunken, höherer RPE)
  → Tatsächliche Pause war zu kurz
  → Basis-Erholungszeit für X erhöhen
```

### 6.3 Speicherung

Leichtgewichtiges Persistenz-Model oder UserDefaults:
```swift
// Mögliche Struktur
struct AdaptiveRecoveryProfile: Codable {
    var adjustedRecoveryHours: [String: Double]  // MuscleGroup.rawValue → angepasste Stunden
    var dataPoints: Int                           // Anzahl ausgewerteter Sessions
    var lastUpdated: Date
}
```

### 6.4 Abgrenzung Phase 1 vs Phase 2

| Aspekt | Phase 1 | Phase 2 |
|---|---|---|
| Recovery-Zeiten | Statische Defaults pro MuscleGroup | Individuell angepasst |
| Persistenz | Keine (on-the-fly) | AdaptiveRecoveryProfile |
| Lernlogik | — | Performance-Vergleich zwischen Sessions |
| UI-Indikator | — | Optional: "Personalisiert" Badge |

---

## 7. UI-Integration

### 7.1 TrainingDetailView — PlanRecoveryCard

Platzierung: **zwischen `PlanStatisticsCard` und `PlanUpdateBanner`** (ca. Zeile 44–48).

```swift
// In TrainingDetailView.swift, nach PlanStatisticsCard:

// Recovery-Status für diesen Plan
PlanRecoveryCard(analysis: planRecoveryAnalysis)
    .padding(.horizontal)
```

Die Card zeigt:
- **Header:** "Erholung" + Durchschnittswert in Prozent
- **Liste:** Jede involvierte MuscleGroup mit ihrem Recovery-Prozent
- **Farbkodierung:** Prozent-Text eingefärbt (≥80% grün, 50–79% orange, <50% rot)
- **Ready-Indikator:** Wenn `isReadyToTrain` == true → dezenter grüner Hinweis "Bereit für Training"

Visuelle Referenz: Ähnlich kompakt wie `PlanStatisticsCard`, eine Row pro MuscleGroup.

### 7.2 SummaryView — SummaryRecoveryCard

Platzierung: **nach der Muskel-Heatmap** (ca. Zeile 133).

```swift
// In SummaryView.swift, nach SummaryMuscleHeatmapCard:

// Recovery-Übersicht
if let recovery = viewModel.recoveryAnalysis {
    SummaryRecoveryCard(analysis: recovery)
}
```

Die Card zeigt:
- **Header:** "Muskel-Erholung" + Gesamt-Durchschnitt
- **Liste:** Alle trainierten MuscleGroups mit Prozent (sortiert: niedrigste zuerst)
- **Progress-Bars** oder **Zahlen** pro Zeile (wie bei PlanStatisticsCard)
- Untrainierte Gruppen werden NICHT angezeigt (wären alle 100%)

### 7.3 Berechnung in SummaryViewModel

```swift
// SummaryViewModel.swift — neue Properties

var recoveryAnalysis: RecoveryAnalysis?

// In recalculate():
let recoveryEngine = RecoveryCalcEngine()
recoveryAnalysis = recoveryEngine.analyze(sessions: strengthSessions)
```

### 7.4 Berechnung in TrainingDetailView

Da `TrainingDetailView` kein eigenes ViewModel hat, wird die Berechnung als `@State` mit `.task {}` gelöst:

```swift
@State private var planRecoveryAnalysis: PlanRecoveryAnalysis?

@Query(sort: \StrengthSession.date, order: .reverse)
private var strengthSessions: [StrengthSession]

// Im body: .task {} für initiale Berechnung
.task {
    let engine = RecoveryCalcEngine()
    planRecoveryAnalysis = engine.analyzeForPlan(
        plan: plan,
        sessions: strengthSessions
    )
}
```

---

## 8. Implementierungsreihenfolge

### Phase 1 — Kern (statisches Modell)

| Schritt | Datei | Beschreibung |
|---|---|---|
| 1 | `RecoveryTypes.swift` | Alle Ergebnis-Typen anlegen |
| 2 | `RecoveryCalcEngine.swift` | Engine mit analyze() + analyzeForPlan() |
| 3 | **STOPP** | Build prüfen, CalcEngine mit Beispieldaten mental durchgehen |
| 4 | `PlanRecoveryCard.swift` | TrainingDetailView-Card |
| 5 | `TrainingDetailView.swift` | Card einbinden + @Query + .task {} |
| 6 | **STOPP** | Build + visuell testen auf TrainingDetailView |
| 7 | `SummaryRecoveryCard.swift` | SummaryView-Card |
| 8 | `SummaryViewModel.swift` | recoveryAnalysis Property + Berechnung |
| 9 | `SummaryView.swift` | Card einbinden |
| 10 | **STOPP** | Build + visuell testen auf SummaryView |

### Phase 2 — Adaptives Modell (später, eigenes Konzept)

| Schritt | Beschreibung |
|---|---|
| 11 | `AdaptiveRecoveryProfile` Codable Struct + UserDefaults-Storage |
| 12 | Lernlogik in RecoveryCalcEngine: Performance-Vergleich zwischen Sessions |
| 13 | Basis-Erholungszeiten dynamisch aus Profil laden statt statische Defaults |
| 14 | Optional: "Personalisiert"-Badge im UI |

---

## 9. Abhängigkeiten & Risiken

| Risiko | Mitigation |
|---|---|
| Muscle-Resolution dupliziert aus MuscleHeatmapCalcEngine | Phase 1: Copy-Paste mit TODO. Phase 2: SharedHelper extrahieren |
| RPE/RIR-Daten fehlen bei manchen Sets | Fallback auf neutralen Faktor (1.0) — Engine funktioniert trotzdem |
| Viele Sessions = langsame Berechnung | 7-Tage-Filter reduziert die Datenmenge erheblich. Dictionary-basiertes O(1) Caching im ViewModel |
| Statische Recovery-Zeiten zu pauschal | Phase 1 akzeptabel, Phase 2 behebt es |
| @Query in TrainingDetailView neu hinzufügen | Nötig, aber unkritisch — nur StrengthSessions lesen |

---

## 10. Geklärte Design-Entscheidungen

1. **Volumen-Normalisierung bei Bodyweight:** ✅ Ja — wenn `set.weight == 0`, wird `session.bodyWeight` als Ersatzgewicht genutzt. Falls auch dieses 0 ist (kein Körpergewicht eingetragen), wird ein konservativer Fallback von 70kg verwendet. Die Formel: `effectiveWeight = set.weight > 0 ? set.weight : (session.bodyWeight > 0 ? session.bodyWeight : 70.0)`

2. **Mehrere Sessions am selben Tag:** ✅ Einfache Kumulation — keine Sonderbehandlung. Morgens Push + Abends Pull addiert die Ermüdung für alle beteiligten Muskeln normal auf.

3. **Card-Design:** ✅ Bestehendes `.glassCard()` Styling verwenden — konsistent mit allen anderen Cards in der App.
