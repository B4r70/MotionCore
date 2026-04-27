# MotionCore — Bugfix: `sleepDuration(forNightEnding:)` liefert falschen Wert

**Scope: 1 Datei, 1 Funktion, 1 STOPP-Gate**

---

## 1. Symptom

In der `BodyView` wird der Tagesform-Faktor "Schlaf" konsistent als **"sehr wenig"** angezeigt, obwohl der tatsächliche Schlaf über mehrere Nächte zwischen 7–9 Stunden lag (verifiziert via Health-App / Schlafindex der Apple Watch).

Der Schlafindex-Screen in der Health-App zeigt für dieselben Nächte korrekte Werte (z.B. 9 Std 9 Min).

## 2. Root Cause

Datei: `MotionCore/HealthKit/HealthKitManager.swift`
Funktion: `sleepDuration(forNightEnding:)` ab Zeile ~514.

Aktueller Code:

```swift
func sleepDuration(forNightEnding date: Date) async throws -> Double? {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthKitManagerError.notAuthorized
    }
    let calendar = Calendar.current
    let endOfDay = calendar.startOfDay(for: date)
    guard let startWindow = calendar.date(byAdding: .hour, value: -20, to: endOfDay) else {
        throw HealthKitManagerError.queryFailed(NSError(domain: "DateCalc", code: -1))
    }
    let predicate = HKQuery.predicateForSamples(withStart: startWindow, end: endOfDay, options: .strictEndDate)
    // ...
}
```

**Probleme:**

1. `endOfDay = calendar.startOfDay(for: date)` ist der **Anfang** des Tages (00:00), nicht das Ende. Trotz Variablennamen.
2. Das Query-Fenster geht damit von **Vortag 04:00 bis Stichtag 00:00**.
3. `.strictEndDate` filtert alle Samples raus, deren Ende nach `endOfDay` (= 00:00 des Stichtags) liegt.
4. Konsequenz: Eine reale Nacht von z.B. 23:00 bis 08:00 morgens wird **komplett verworfen**, weil das Sample-Ende (08:00) hinter dem Window-Ende (00:00) liegt. Übrig bleiben nur Schlaf-Fragmente (Mittagsschlaf etc.) oder gar nichts → `nil` oder unrealistisch niedrige Werte.

Im Gegensatz dazu funktioniert `fetchTodaySleepSummary()` in derselben Datei korrekt, weil sie ein 7-Tage-Fenster nutzt und dynamisch das letzte Schlaf-Sample sucht. Diese Logik ist hier aber nicht direkt übertragbar, weil `sleepDuration(forNightEnding:)` auch für **historische Tage** in `HealthBaselineUpdateService.swift` (Zeile 91) aufgerufen wird, um die Schlaf-Baseline zu berechnen.

## 3. Fix

Window so umstellen, dass es die natürliche Nachtgrenze einer Nacht abdeckt, die **morgens am `date`** endet:

- **Window-Start: 18:00 des Vortags** (deckt frühe Schläfer ab, schließt aber Vortags-Mittagsschlaf aus)
- **Window-Ende: 12:00 des `date`** (deckt späte Aufsteher ab)
- **`options: []`** statt `.strictEndDate` — Default-Behavior reicht völlig: alle Samples, die das Fenster überlappen, werden geliefert.

Ersetze die Funktion komplett durch:

```swift
/// Schlafdauer in Stunden für eine Nacht, die **am Morgen von `date`** endet.
/// Window: 18:00 Vortag bis 12:00 Stichtag.
/// Wird sowohl für die heutige Tagesform als auch für historische Baseline-Berechnung genutzt.
func sleepDuration(forNightEnding date: Date) async throws -> Double? {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthKitManagerError.notAuthorized
    }
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)

    // Fenster: Vortag 18:00 bis Stichtag 12:00
    guard
        let windowStart = calendar.date(byAdding: .hour, value: -6,  to: dayStart),
        let windowEnd   = calendar.date(byAdding: .hour, value: 12, to: dayStart)
    else {
        throw HealthKitManagerError.queryFailed(NSError(domain: "DateCalc", code: -1))
    }

    let predicate = HKQuery.predicateForSamples(
        withStart: windowStart,
        end: windowEnd,
        options: []
    )

    return try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error {
                continuation.resume(throwing: HealthKitManagerError.queryFailed(error))
                return
            }
            guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                continuation.resume(returning: nil)
                return
            }
            var totalSeconds: TimeInterval = 0
            for s in samples {
                guard let value = HKCategoryValueSleepAnalysis(rawValue: s.value) else { continue }
                switch value {
                case .awake, .inBed: break
                default: totalSeconds += s.endDate.timeIntervalSince(s.startDate)
                }
            }
            continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3600.0 : nil)
        }
        healthStore.execute(query)
    }
}
```

**Nicht ändern:**

- `fetchTodaySleepSummary()` — funktioniert bereits korrekt, anderer Use-Case (Schlafphasen-Anzeige).
- `sleepDurationDescription(_:)` in `ReadinessCalcEngine.swift` — die Schwellen sind okay, das Problem war nur der falsche Input-Wert.
- Aufrufer in `SessionReadinessService.swift` und `HealthBaselineUpdateService.swift` — Signatur bleibt identisch, kein Anpassungsbedarf.

## 4. Verifikation

Nach Build:

1. App auf Gerät starten (HealthKit funktioniert nicht im Simulator für reale Daten).
2. **BodyView** → Tab "Tagesform" öffnen.
3. **Erwartet**: "Schlaf"-Faktor zeigt Sub-Label entsprechend der echten Schlafdauer der letzten Nacht (z.B. "gut" oder "sehr gut" bei ~9h, statt "sehr wenig").
4. **Cross-Check**: iOS Health-App → Schlafindex → der dort angezeigte Wert für die letzte Nacht sollte konsistent zur Bar-Position in MotionCore sein.
5. **Edge-Case**: Falls die Apple Watch in der letzten Nacht nicht getragen wurde → Faktor sollte ggf. komplett ausgeblendet werden (Verhalten von `ReadinessCalcEngine` bei `nil`-Input → unverändert).

## 5. Definition of Done

- ✅ Funktion ersetzt, Signatur unverändert
- ✅ Build green, keine neuen Warnings
- ✅ Auf Gerät verifiziert: Schlaf-Faktor zeigt plausible Werte (~7–9h → "gut"/"sehr gut")
- ✅ `HealthBaselineUpdateService` funktioniert weiterhin (Baseline-Update für historische Tage)
- ✅ Keine anderen Dateien angefasst

**STOPP nach Implementation für Build & Geräte-Test durch Barto.**
