# MotionCore — Phase 2: Readiness Implementation
## Claude-Code-Instruktionsdokument v1.0

**Bezug:** `MotionCore_SmartProgression_Concept_v1.1.md` (Kapitel 4.2, 7 Phase 2)
**Datum:** 24. April 2026
**Zielagenten:** motioncore-planner (opus) → motioncore-developer (sonnet) → motioncore-quality-gate (sonnet)
**Komplexität:** Medium-Large (8 Schritte, HealthKit-Integration)
**Voraussetzung:** Phase 1 ✓, Phase 1.5 ✓

---

## 🛑 GRUNDREGELN

Identisch zu Phase 1 und 1.5. Ergänzung für diese Phase:

### Spezielle HealthKit-Regeln
- Permissions werden **inkrementell** angefragt, nicht alle auf einmal
- Fehlende Permissions dürfen die App **nicht blockieren** — Fallback auf partielle Daten
- Alle HealthKit-Aufrufe sind `async throws`
- Kein Force-Unwrap bei HealthKit-Daten

### Spezielle Testing-Regeln für Phase 2
- **HealthKit-Daten werden auf dem Simulator gemockt** — echte Daten nur auf Gerät
- Barto trägt Apple Watch Series 10 durchgehend (nachts + Alltag) → HRV-Daten verfügbar
- Barto nimmt Bisoprolol + Candesartan → Medikamenten-Schalter muss greifen

---

## 📋 PHASENÜBERSICHT

| Schritt | Thema | Abhängig von |
|---|---|---|
| 2.1 | HealthKit-Service erweitern | — |
| 2.2 | HealthBaseline-Model befüllen + Update-Service | 2.1 |
| 2.3 | ReadinessCalcEngine | 2.2 |
| 2.4 | SessionReadiness-Speicherung | 2.3 |
| 2.5 | Readiness-Karte (kompakt) | 2.4 |
| 2.6 | Readiness-Expanded-View + optionale Fragen | 2.5 |
| 2.7 | Verdrahtung mit ProgressionCalcEngine | 2.3, Phase 1.5 ✓ |
| 2.8 | Kalibrierungs-Hinweis-UI | 2.2 |

**Empfohlene Reihenfolge:** strikt sequenziell

**Hinweis:** Models `HealthBaseline`, `HealthMetricType`, `SessionReadiness` wurden bereits in Phase 1 Schritt 1.5 und 1.6 angelegt (vorbereitend). Diese Phase nutzt sie.

---

## Schritt 2.1 — HealthKit-Service erweitern

**Ziel:** Service-Layer für HRV, Schlaf, Ruhepuls, Aktivität.

**Dateien:**
- ÄNDERN oder NEU: `MotionCore/Services/HealthKitService.swift` (je nach bestehender Struktur)
- NEU falls sinnvoll: `MotionCore/Services/HealthMetricsProvider.swift`

**Anforderungen:**

**Benötigte HealthKit-Permissions (Read):**
- `HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)`
- `HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)`
- `HKQuantityType.quantityType(forIdentifier: .restingHeartRate)`
- `HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)`

**Permissions-Flow:**
- Prüfen mit `authorizationStatus(for:)`
- Wenn unbestimmt: Info.plist-Strings sind bereits für bestehende HealthKit-Nutzung da — ergänzen falls fehlend
- Request on-demand beim ersten Baseline-Update, nicht proaktiv beim App-Start

**API-Methoden:**

```swift
extension HealthKitService {
    /// Returns HRV (SDNN in ms) values for last N days
    func hrvSamples(daysBack: Int) async throws -> [Date: Double]

    /// Returns total sleep duration in hours for a specific night
    func sleepDuration(forNightEnding date: Date) async throws -> Double?

    /// Returns resting HR for last N days (daily averages)
    func restingHRSamples(daysBack: Int) async throws -> [Date: Double]

    /// Returns total active energy burned on a specific day
    func activeEnergy(forDate date: Date) async throws -> Double?
}
```

**Error-Handling:**
- Neue Error-Enum `HealthKitServiceError`: `.notAuthorized`, `.noData`, `.queryFailed(Error)`
- Alle Methoden `throws`, kein Force-Unwrap

**Build-Check:**
- iOS build green
- Simulator-Test (Fallback: Methoden werfen `.noData` oder leere Dictionaries)
- Kein Crash bei fehlender Authorization

**🛑 STOPP 2.1**

---

## Schritt 2.2 — HealthBaseline-Update-Service

**Ziel:** Baselines werden täglich aktualisiert und in SwiftData persistiert.

**Dateien:**
- NEU: `MotionCore/Services/HealthBaselineUpdateService.swift`
- ÄNDERN: `MotionCoreApp.swift` — App-Foreground-Hook

**Anforderungen:**

**Service-API:**

```swift
@MainActor
final class HealthBaselineUpdateService {
    init(
        healthKit: HealthKitService,
        modelContext: ModelContext,
        takesCardioMedication: Bool
    )

    /// Aktualisiert alle Baselines wenn letztes Update > heute
    func updateIfNeeded() async

    /// Erzwingt Aktualisierung (für Debug / manuelle Trigger)
    func forceUpdate() async
}
```

**Logik pro Metrik:**

```swift
let windowDays = takesCardioMedication ? 42 : 28
let rawData = try await healthKit.hrvSamples(daysBack: windowDays)

guard !rawData.isEmpty else {
    // Baseline bleibt, sampleCount aktualisieren
    return
}

let values = Array(rawData.values)
let mean = values.reduce(0, +) / Double(values.count)
let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
let stdDev = sqrt(variance)

// In SwiftData persistieren
let baseline = fetchOrCreateBaseline(for: .hrv)
baseline.rollingMean = mean
baseline.rollingStdDev = stdDev
baseline.sampleCount = values.count
baseline.lastUpdated = Date()
```

**Trigger-Logik:**
- In `MotionCoreApp.swift`: `.onChange(of: scenePhase)` beim Wechsel auf `.active`
- Prüft: `baseline.lastUpdated` ist heute? → skip, sonst update
- Kein Blocking der UI — Service läuft im Background

**Calibration-Threshold:**
- `sampleCount < 14` → Baseline ist in Kalibrierung (wird von ReadinessCalcEngine genutzt)

**Build-Check:**
- Baseline-Entries werden erstellt beim ersten Start mit Daten
- Update am nächsten Tag überschreibt vorhandene Einträge
- Ohne HealthKit-Berechtigung: keine Fehler, Baselines bleiben leer

**🛑 STOPP 2.2**

---

## Schritt 2.3 — ReadinessCalcEngine

**Ziel:** Core-Engine für Readiness-Score.

**Dateien:**
- NEU: `MotionCore/CalcEngines/ReadinessCalcEngine.swift`
- NEU: `MotionCore/CalcEngines/ReadinessTypes.swift`

**Anforderungen:**
- Pure Struct, keine Side Effects, keine SwiftUI-Imports
- API gemäß Concept v1.1 Kapitel 4.2

**Kern-Logik:**

**1. Kalibrierungs-Check (zuerst):**
```swift
let allBaselines = [hrvBaseline, sleepBaseline, restingHRBaseline, activityBaseline]
let hasEnoughData = allBaselines.allSatisfy { ($0?.sampleCount ?? 0) >= 14 }

if !hasEnoughData {
    return Output(score: 50, label: .normal, breakdown: [], modifier: 1.0, isCalibrating: true)
}
```

**2. Per-Metrik-Scores (0.0 bis 1.0):**

Für jede Metrik:
```swift
let zScore = (todayValue - baseline.rollingMean) / baseline.rollingStdDev
let normalized: Double

// Für HRV + Activity: höher = besser
// Für Sleep: höher = besser (aber begrenzt)
// Für RestingHR: niedriger = besser (invertieren)

switch metricType {
case .hrv, .activity, .sleep:
    normalized = (zScore + 2.0) / 4.0  // z-Score ±2 → 0–1
case .restingHR:
    normalized = (-zScore + 2.0) / 4.0  // Invertiert
}

let clamped = min(max(normalized, 0.0), 1.0)
```

**3. Gewichtung:**

```swift
let weights: (hrv: Double, sleep: Double, restingHR: Double, activity: Double)
if takesCardioMedication {
    weights = (0.25, 0.40, 0.15, 0.15)  // User-Input-Bonus kommt separat
} else {
    weights = (0.40, 0.30, 0.20, 0.10)
}
```

**4. User-Input-Integration:**

```swift
// Optional Energy (1-5 scale) — beeinflusst Score um ±5 Punkte
if let energy = input.userEnergy {
    let energyAdjustment = (Double(energy) - 3.0) * 2.5  // -5 bis +5
    finalScore += energyAdjustment
}

// Optional Stress — beeinflusst um -5 / 0 / +3
if let stress = input.userStressRaw {
    switch stress {
    case "low": finalScore += 3
    case "medium": break
    case "high": finalScore -= 5
    default: break
    }
}
```

**5. Modifier-Ableitung:**

```swift
let modifier: Double
switch finalScore {
case 0..<30: modifier = 0.85
case 30..<50: modifier = 0.92
case 50..<85: modifier = 1.00
case 85...100: modifier = 1.05
default: modifier = 1.00
}
```

**6. Breakdown für UI:**

Pro Metrik ein `ReadinessFactor` mit:
- `name`: „HRV", „Schlaf", „Ruhepuls", „Aktivität (gestern)"
- `valueDescription`: z.B. „leicht über Baseline", „deutlich unter Baseline"
- `weight`: Gewichtung als Prozent

**Manuelle Testszenarien:**
1. Keine Baselines → `isCalibrating = true`, Score 50
2. Alle Metriken ±0 von Baseline → Score ~50
3. Alle Metriken +2 StdDev → Score ~85+
4. Alle Metriken -2 StdDev → Score ~15-
5. Medikamenten-Schalter on, HRV über Baseline, Schlaf unter → Schlaf wiegt mehr
6. User-Input hohe Energie + niedriger Stress → Score boost um ~7.5

**Build-Check:**
- Test-View mit den 6 Szenarien zeigt plausible Outputs
- Engine pure (kein Import UIKit/SwiftUI)

**🛑 STOPP 2.3**

---

## Schritt 2.4 — SessionReadiness-Speicherung

**Ziel:** Bei Workout-Start wird ein `SessionReadiness`-Snapshot erzeugt.

**Dateien:**
- ÄNDERN: `ActiveWorkoutViewModel.swift` (oder wo Sessions gestartet werden)
- NEU falls sinnvoll: `MotionCore/Services/SessionReadinessService.swift`

**Anforderungen:**

**Workflow beim Start eines Workouts:**

```swift
// 1. Baselines aktualisieren (wenn nicht bereits heute)
await baselineUpdateService.updateIfNeeded()

// 2. Heutige HealthKit-Werte holen
let hrvToday = try? await healthKit.hrvSamples(daysBack: 1).values.last
let sleepToday = try? await healthKit.sleepDuration(forNightEnding: .now)
let restingHRToday = try? await healthKit.restingHRSamples(daysBack: 1).values.last
let activityYesterday = try? await healthKit.activeEnergy(forDate: .now.addingTimeInterval(-86400))

// 3. Readiness berechnen
let output = ReadinessCalcEngine.calculate(input: ...)

// 4. SessionReadiness persistieren
let readiness = SessionReadiness()
readiness.sessionUUID = session.uuid
readiness.hrvScore = ...
readiness.sleepScore = ...
// etc.
readiness.overallScore = output.score
readiness.isCalibrating = output.isCalibrating

modelContext.insert(readiness)
session.sessionReadinessID = readiness.id
```

**Wichtig:** Die Readiness-Messung erfolgt **einmalig** beim Workout-Start, nicht kontinuierlich.

**Build-Check:**
- Nach Workout-Start: `SessionReadiness` existiert
- Verlinkung via `session.sessionReadinessID` funktioniert
- Bei Fehlern: neutrale Readiness (Score 50) als Fallback

**🛑 STOPP 2.4**

---

## Schritt 2.5 — Readiness-Karte (kompakt)

**Ziel:** Kompakte Karte auf Workout-Start-Screen mit Score + Label.

**Dateien:**
- NEU: `MotionCore/Views/Readiness/ReadinessCard.swift`
- NEU: `MotionCore/ViewModels/ReadinessViewModel.swift`
- ÄNDERN: Workout-Start-Screen oder HomeView (wo der User Training startet)

**Anforderungen:**

**UI-Design (siehe Concept v1.1 Kapitel 5.6):**

```
┌──────────────────────────────┐
│  🟢 Heute gut drauf           │
│  Readiness: 78/100            │
│  Tap für Details ↓            │
└──────────────────────────────┘
```

**Farbcodierung nach Label:**
- `veryLow` → 🔴 rot
- `low` → 🟠 orange
- `normal` → 🟡 gelb
- `good` → 🟢 grün
- `excellent` → 🟢 grün mit Sternakzent

**Labels (deutsch):**
- `veryLow`: „Heute besser schonen"
- `low`: „Etwas müde heute"
- `normal`: „Normale Tagesform"
- `good`: „Heute gut drauf"
- `excellent`: „Top-Tag heute"

**Kalibrierungs-Zustand:**

Während `isCalibrating = true`:
```
┌──────────────────────────────┐
│  ⏳ Kalibriere noch           │
│  Noch X Tage bis volle Daten  │
│  Tap für Details ↓            │
└──────────────────────────────┘
```

**Styling:** `.glassCard()`-Pattern konsistent zu anderen Cards.

**Tap-Verhalten:** Öffnet `ReadinessDetailView` (Schritt 2.6).

**Build-Check:**
- Karte erscheint auf Workout-Start
- Score + Label stimmen mit `SessionReadiness` überein
- Tap öffnet Detail-View (später in 2.6)

**Screenshots:** Karte in 3 Varianten (low/normal/good), Kalibrierungs-Zustand.

**🛑 STOPP 2.5**

---

## Schritt 2.6 — Readiness-Expanded-View + optionale Fragen

**Ziel:** Tap auf Karte öffnet Detail mit Breakdown + optionalen Tap-Fragen.

**Dateien:**
- NEU: `MotionCore/Views/Readiness/ReadinessDetailView.swift`

**Anforderungen:**

**UI-Struktur:**

```
┌──────────────────────────────┐
│  Readiness: 78/100            │
│                               │
│  ● HRV: leicht über Baseline  │
│  ● Schlaf: 7h 20min (gut)     │
│  ● Ruhepuls: 58 (normal)      │
│  ● Aktivität gestern: normal  │
│                               │
│  ─── Verfeinern (optional) ── │
│                               │
│  Energie:                     │
│  [1] [2] [3] [4] [5]          │
│                               │
│  Stress:                      │
│  [niedrig] [mittel] [hoch]    │
│                               │
│  [Übernehmen]                 │
└──────────────────────────────┘
```

**Verhalten:**
- Eingaben werden in `SessionReadiness.userEnergyLevel` und `userStressLevelRaw` geschrieben
- Bei „Übernehmen": `ReadinessCalcEngine` neu aufrufen mit User-Input, neuer Score gespeichert
- Bei Kalibrierung: nur Breakdown zeigen, keine User-Input-Felder (da Score sowieso neutral)

**Breakdown-Texte:**

| z-Score | Text |
|---|---|
| > 1.5 | „deutlich über Baseline" |
| 0.5 bis 1.5 | „leicht über Baseline" |
| -0.5 bis 0.5 | „normal" |
| -1.5 bis -0.5 | „leicht unter Baseline" |
| < -1.5 | „deutlich unter Baseline" |

Spezielle Werte bei Schlaf (Dauer):
- < 5h: „sehr wenig"
- 5–6h: „wenig"
- 6–7h: „okay"
- 7–8h: „gut"
- > 8h: „sehr gut"

**Build-Check:**
- Detail öffnet bei Tap
- Breakdown zeigt pro Metrik den korrekten Text
- User-Inputs ändern Score merklich
- „Übernehmen" schließt Sheet und aktualisiert Card

**Screenshots:** Detail-View ohne User-Input, mit User-Input, Kalibrierungs-Zustand.

**🛑 STOPP 2.6**

---

## Schritt 2.7 — Verdrahtung mit ProgressionCalcEngine

**Ziel:** `readinessModifier` wird endlich dynamisch statt immer 1.0.

**Dateien:**
- ÄNDERN: `ActiveWorkoutViewModel.swift` (oder wo die ProgressionCalcEngine aufgerufen wird)

**Anforderungen:**

**Beim Workout-Start** (nach `SessionReadiness` erstellt):

```swift
// Readiness in ViewModel-State speichern
self.currentReadinessModifier = sessionReadiness.modifier
```

**Bei jedem ProgressionCalcEngine-Aufruf:**

```swift
let input = ProgressionCalcEngine.Input(
    progressionState: ...,
    lastSessionSets: ...,
    studioEquipment: ...,
    exerciseFallbackStep: ...,
    readinessModifier: self.currentReadinessModifier,  // <-- NEU
    currentSessionSetIndex: ...,
    currentSessionPreviousSets: ...
)
```

**UI-Feedback für `readinessReduced`-Reasoning:**

Wenn die Engine ein reduziertes Gewicht vorschlägt (Modifier < 1.0), zeigt das UI einen kleinen Hinweis neben dem Gewichtsfeld:

```
60kg (-5% Readiness)
```

oder als Badge:

```
💤 Reduziert wegen Tagesform
```

**Build-Check:**
- Bei niedriger Readiness: Placeholder-Gewicht ist niedriger als workingWeight
- UI zeigt Hinweis
- Auto-Progression (Phase 1.5) respektiert ebenfalls Readiness — oder ist das separat? → **Klärung im Planner**: Auto-Progression sollte bei niedriger Readiness verzögert werden. Wenn `readinessModifier < 1.0` in der Session, kein Auto-Progression-Trigger.

**🛑 STOPP 2.7**

---

## Schritt 2.8 — Kalibrierungs-Hinweis-UI-Feinschliff

**Ziel:** Kalibrierungs-Phase in allen relevanten UI-Bereichen transparent.

**Dateien:**
- ÄNDERN: `ReadinessCard.swift` (falls noch nicht vollständig in 2.5)
- ÄNDERN: `ReadinessDetailView.swift` (Detail-Aufschlüsselung)

**Anforderungen:**

**Kalibrierungs-Card:**
```
┌──────────────────────────────┐
│  ⏳ Kalibriere noch           │
│  Sammle deine Tagesform-Daten │
│  Noch etwa X Tage             │
│                               │
│  Pro Metrik:                  │
│  HRV:      ▓▓▓▓░░░ 14/28      │
│  Schlaf:   ▓▓▓▓▓░░ 18/28      │
│  Puls:     ▓▓▓░░░░ 10/28      │
│  Aktivität:▓▓▓▓░░░ 14/28      │
└──────────────────────────────┘
```

**Berechnung Restzeit:**
```swift
let neededSamples = takesCardioMedication ? 42 : 28
let minSamples = baselines.map { $0.sampleCount }.min() ?? 0
let remainingDays = max(0, 14 - minSamples)  // 14 ist Minimum-Threshold
```

**Text-Formulierung (deutsch):**
- „Sammle deine Tagesform-Daten"
- „Noch etwa {X} Tage, bis die Auswertung voll verfügbar ist."
- „Der Score bleibt solange bei neutral (50)."

**Build-Check:**
- Bei frisch installierter App: Kalibrierungs-UI sichtbar
- Progress-Bars korrekt gefüllt
- Nach 14+ Tagen Daten: normale Card erscheint

**🛑 STOPP 2.8 — Ende Phase 2**

---

## 🎯 Phase-2-Abschluss

### Definition of Done
- [ ] HealthKit-Permissions granted + werden genutzt
- [ ] Baselines werden täglich aktualisiert
- [ ] ReadinessCalcEngine liefert plausible Scores
- [ ] Medikamenten-Schalter ändert Gewichtung messbar
- [ ] Kalibrierungsphase ist transparent
- [ ] Readiness-Card erscheint auf Workout-Start
- [ ] Detail-View mit Breakdown + optionalen Fragen funktioniert
- [ ] Progression reagiert auf Readiness-Modifier
- [ ] Auto-Progression (Phase 1.5) wird bei niedriger Readiness nicht getriggert

### User-Test-Phase (mind. 2 Wochen)
Diese Phase braucht **längere Testzeit** als frühere, weil die Kalibrierungsphase echte Zeit braucht:
- Woche 1–2: Kalibrierungs-UI sichtbar, Daten werden gesammelt
- Ab Woche 3: echte Readiness-Scores, Vergleich mit subjektivem Empfinden
- Woche 3–4: Beobachten, ob Readiness-Score mit Tagesform übereinstimmt

**🛑 GROSSER STOPP vor Phase 3**

---

## ANHANG

### A. Abhängigkeiten Phase 2

```
2.1 ──► 2.2 ──► 2.3 ──► 2.4 ──► 2.5 ──► 2.6 ──► 2.7 ──► 2.8
```

### B. Testing-Helfer

Für manuelle Tests in der Entwicklungsphase empfohlen:

- **Debug-Button „Baseline mocken"**: setzt alle `HealthBaseline` auf plausible Werte (nur im DEBUG-Build)
- **Debug-Button „Readiness-Score überschreiben"**: erlaubt manuell einen Score zu setzen, um Engine-Verhalten zu testen

Diese Debug-Tools bleiben im Code, aber nur unter `#if DEBUG` kompiliert.

### C. Kommunikation

Phase 2 ist weniger destruktiv als Phase 1 (keine Datenstrukturen werden entfernt). Dennoch:
- Bei HealthKit-Permission-Ablehnung: freundliche Fallback-Meldung
- Keine „Error"-Popups für fehlende Gesundheitsdaten — einfach neutrale Anzeige

### D. Notfall-Kriterien

Spezielle Stopper für Phase 2:
1. HealthKit-Permissions können nicht erlangt werden
2. Baseline-Berechnung liefert NaN oder Infinity (fehlerhafte Statistik)
3. Readiness-Score schwankt extrem zwischen Sessions am selben Tag
4. Medikamenten-Schalter zeigt keine messbare Wirkung auf Score

---

**Ende Instruction Phase 2 v1.0**
