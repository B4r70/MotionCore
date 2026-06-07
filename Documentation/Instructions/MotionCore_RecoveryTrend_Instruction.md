# Claude Code Instruction — Erholungs-Trend (Body-Tab)

**Version:** 1.0
**Feature:** 14-Tage-Verlauf des Gesamt-Erholungswerts im Body-Tab → Trend
**Ansatz:** Option A — Trend lokal aus Sessions rekonstruieren (kein Snapshot, keine Netzabhängigkeit)
**Sprache:** Code-Kommentare/UI Deutsch, dieser Plan Deutsch

---

## Kontext & Problem

Der Tab **Body → Trend** zeigt dauerhaft „Keine Einträge", unabhängig von der Wartezeit.
Ursache: `BodyRecoveryTrendCard` ist ein reiner Platzhalter — die View nimmt keine Daten
entgegen und rendert hartkodiert `EmptyState()`.

`MuscleRecoveryCalcEngine.analyze(sessions:)` liefert nur **einen** Snapshot für *jetzt*
(`analysisDate: now`). Es existiert keine lokale Zeitreihe von Erholungswerten.

**Lösung (Option A):** Der Erholungswert ist deterministisch aus den abgeschlossenen
Sessions ableitbar. Wir rekonstruieren den Verlauf rückwirkend, indem die Engine für 14
zurückliegende Stichtage ausgeführt wird — je einmal mit einem anderen Referenzdatum.
Das löst das Problem **sofort und rückwirkend** (kein Warten mehr nötig), bleibt 100 %
lokal und verletzt nicht das „iOS = Source of Truth"-Prinzip.

---

## Verifizierte Fakten (gegen echten Code geprüft)

- `MuscleRecoveryCalcEngine` ist ein **`struct` mit `static func analyze(sessions:)`**.
  `now` wird intern als `let now = Date()` gesetzt (Zeile 45) und an drei weiteren
  Stellen verwendet (Cutoff Z. 46, Satz-Alter Z. 62, `hoursSince` Z. 104).
- `MuscleRecoveryAnalysis.overallRecoveryPercent` ist ein computed `Double` und gibt
  **100.0** zurück, wenn im Zeitfenster keine Gruppe trainiert wurde.
- `BodyViewModel` ist `@Observable final class`, hält `recoveryAnalysis` und ruft in
  `recalculate(sessions:)` direkt `MuscleRecoveryCalcEngine.analyze(sessions:)`.
- `BodyView` besitzt bereits alle abgeschlossenen Sessions als `@Query` und ruft
  `viewModel.recalculate(sessions:)` in `refresh()`. Der Trend-Tab rendert aktuell
  `BodyRecoveryTrendCard()` **parameterlos** (Z. 126).
- Swift **Charts** wird im Projekt verwendet (`StrengthVolumeChart`, `StatisticTrendChart`).
- **`TrendPoint`** existiert bereits in `StatisticCalcEngine.swift`:
  ```swift
  struct TrendPoint: Identifiable {
      let id = UUID()
      let trendDate: Date
      let trendValue: Double
  }
  ```
  → **Diesen Typ wiederverwenden, keinen neuen anlegen.**
- `MCSparkline` ist auf 70×24 px hartkodiert und für Mini-Anzeigen gedacht →
  für die Card **nicht** geeignet, stattdessen Swift Charts wie `StrengthVolumeChart`.

---

## Architektur-Überblick

```
StrengthSession[] (vorhanden in BodyView @Query)
        │
        ▼
RecoveryTrendCalcEngine.trend(sessions:days:)   ← NEU (pure struct)
        │  läuft 14× MuscleRecoveryCalcEngine.analyze(sessions:referenceDate:)
        ▼
[TrendPoint]  (trendDate = Stichtag, trendValue = overallRecoveryPercent)
        │
        ▼
BodyViewModel.recoveryTrend                       ← NEU (Property + Berechnung)
        │
        ▼
BodyRecoveryTrendCard(trend:)                     ← UMBAU (Parameter + Swift Charts)
```

**Engine-Eingriff:** `analyze` bekommt einen optionalen `referenceDate`-Parameter
(Default `Date()`), damit das bestehende Verhalten **unverändert** bleibt. Alle
internen `now`-Verwendungen nutzen dann diesen Parameter.

---

## Phasen mit STOPP-Gates

> **STOPP-Gate-Regel:** Nach jeder Phase Build ausführen und mit **„grün"** oder **„rot"**
> (inkl. Fehlertext) bestätigen, bevor die nächste Phase startet. Kein vages „passt".

---

### Phase A — Engine um `referenceDate` erweitern (verhaltensneutral)

**Datei:** `MuscleRecoveryCalcEngine.swift`

1. Signatur ändern:
   ```swift
   static func analyze(
       sessions: [StrengthSession],
       referenceDate: Date = Date()
   ) -> MuscleRecoveryAnalysis {
   ```
2. Erste Zeile im Body ersetzen:
   - **alt:** `let now = Date()`
   - **neu:** `let now = referenceDate`
   Alle weiteren Verwendungen von `now` (Cutoff, `ageInDays`, `hoursSince`,
   `analysisDate: now`) bleiben **unverändert** — sie greifen automatisch auf den
   Parameter zu.

**Wichtig (Korrektheit des rückwirkenden Werts):**
- Der Cutoff (`now.addingTimeInterval(-14d)`) und der Decay rechnen relativ zu `now`.
  Damit ist die Analyse für einen vergangenen Stichtag konsistent: Sätze, die *nach*
  dem Stichtag liegen, haben ein negatives Alter.
- **Decay/Recovery vor dem Stichtag absichern:** Sätze mit `session.date > referenceDate`
  dürfen nicht einfließen (sonst „Zukunftswissen"). Den Filter in Schritt 1 der Analyse
  erweitern:
  - **alt:** `sessions.filter { $0.isCompleted && $0.date >= cutoff }`
  - **neu:** `sessions.filter { $0.isCompleted && $0.date >= cutoff && $0.date <= now }`

**STOPP-Gate A:** Build grün? Bestehende Aufrufer (`BodyViewModel`, `BaseView`,
`SummaryViewModel`) kompilieren unverändert, weil `referenceDate` einen Default hat.
→ Bestätige grün/rot.

---

### Phase B — `RecoveryTrendCalcEngine` anlegen (pure struct)

**Neue Datei:** `RecoveryTrendCalcEngine.swift` (Abschnitt: Services / Berechnung)

Header aus einer bestehenden CalcEngine kopieren. Inhalt:

```swift
import Foundation

/// Rekonstruiert den Verlauf des Gesamt-Erholungswerts über die letzten N Tage,
/// indem MuscleRecoveryCalcEngine für jeden Stichtag rückwirkend ausgeführt wird.
struct RecoveryTrendCalcEngine {

    /// Anzahl der Stichtage (inkl. heute)
    static let defaultDays: Int = 14

    /// Liefert einen TrendPoint pro Tag (älteste zuerst, heute zuletzt).
    /// trendValue = overallRecoveryPercent zum jeweiligen Stichtag (0–100).
    static func trend(
        sessions: [StrengthSession],
        days: Int = defaultDays,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [TrendPoint] {
        guard days > 0 else { return [] }

        let startOfToday = calendar.startOfDay(for: now)
        var points: [TrendPoint] = []

        // Von (days-1) Tage zurück bis heute
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let dayStart = calendar.date(
                byAdding: .day, value: -offset, to: startOfToday
            ) else { continue }

            // Referenzzeitpunkt = Ende des Stichtags, damit Sessions
            // dieses Tages vollständig berücksichtigt werden.
            let reference = calendar.date(
                byAdding: .day, value: 1, to: dayStart
            )?.addingTimeInterval(-1) ?? dayStart

            let analysis = MuscleRecoveryCalcEngine.analyze(
                sessions: sessions,
                referenceDate: reference
            )

            points.append(TrendPoint(
                trendDate: dayStart,
                trendValue: analysis.overallRecoveryPercent
            ))
        }

        return points
    }

    /// True, wenn im gesamten Fenster keine Session trainiert wurde
    /// (alle Werte = 100 → keine sinnvolle Aussage).
    static func isEmpty(_ points: [TrendPoint]) -> Bool {
        points.allSatisfy { $0.trendValue >= 100.0 }
    }
}
```

**Designentscheidungen (zur Info, nicht ändern ohne Rückfrage):**
- `referenceDate` = **Ende** des Stichtags (23:59:59), damit ein an diesem Tag
  absolviertes Workout den Wert sofort beeinflusst.
- `isEmpty` erkennt den „nie trainiert"-Fall: dann zeigt die Card den `EmptyState`.
  (Ein durchgehender 100-%-Verlauf ist visuell eine flache Linie ohne Aussage.)

**STOPP-Gate B:** Build grün? → Bestätige grün/rot.

---

### Phase C — `BodyViewModel` um Trend erweitern

**Datei:** `BodyViewModel.swift`

1. Property ergänzen (bei den öffentlichen Properties):
   ```swift
   private(set) var recoveryTrend: [TrendPoint] = []
   ```
2. In `recalculate(sessions:)` am Ende ergänzen:
   ```swift
   recoveryTrend = RecoveryTrendCalcEngine.trend(sessions: sessions)
   ```

**STOPP-Gate C:** Build grün? → Bestätige grün/rot.

---

### Phase D — `BodyRecoveryTrendCard` umbauen (Swift Charts)

**Datei:** `BodyRecoveryTrendCard.swift`

Komplett ersetzen (Header behalten/aktualisieren). Orientierung: `StrengthVolumeChart`.

```swift
import SwiftUI
import Charts

// MARK: - BodyRecoveryTrendCard

struct BodyRecoveryTrendCard: View {

    // MARK: - Eingaben

    let trend: [TrendPoint]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Erholungs-Trend · 14 Tage")
                .font(.headline)

            if RecoveryTrendCalcEngine.isEmpty(trend) || trend.count < 2 {
                EmptyState()
            } else {
                chart
            }
        }
        .frame(minHeight: 140)
        .glassCard()
    }

    // MARK: - Subviews

    private var chart: some View {
        Chart(trend) { point in
            LineMark(
                x: .value("Datum", point.trendDate, unit: .day),
                y: .value("Erholung", point.trendValue)
            )
            .foregroundStyle(MCColor.mcBody)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Datum", point.trendDate, unit: .day),
                y: .value("Erholung", point.trendValue)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [MCColor.mcBody.opacity(0.25), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)%")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(minHeight: 200)
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let cal = Calendar.current
    let sample = (0..<14).reversed().map { offset in
        TrendPoint(
            trendDate: cal.date(byAdding: .day, value: -offset, to: now)!,
            trendValue: Double(40 + offset * 3)
        )
    }
    return BodyRecoveryTrendCard(trend: sample)
        .padding()
}
```

**Prüfen:** Heißt der Body-Akzentton wirklich `MCColor.mcBody`? (In
`BodyCompositeScoreCard` so verwendet.) Falls der Compiler meckert, exakten Namen
aus `MCColorPalette.swift` übernehmen — **nicht raten**.

**STOPP-Gate D:** Build grün? Preview rendert eine ansteigende Linie? → grün/rot.

---

### Phase E — Aufrufstelle in `BodyView` verdrahten

**Datei:** `BodyView.swift`, `tabContentSection`, `case .trend`

- **alt:** `BodyRecoveryTrendCard()`
- **neu:** `BodyRecoveryTrendCard(trend: viewModel.recoveryTrend)`

**STOPP-Gate E:** Build grün? Im Simulator mit echten Sessions: Body → Trend zeigt
jetzt eine Linie statt „Keine Einträge"? → grün/rot.

---

## Verifikation am Ende (manuell)

1. **Mit Trainingsdaten:** Body → Trend zeigt eine Linie 0–100 %, x-Achse letzte 14 Tage.
2. **Ohne jegliche Sessions:** Card zeigt `EmptyState` (kein leerer Chart, kein Absturz).
3. **Plausibilität:** An Tagen nach einem harten Workout sollte der Wert einbrechen und
   danach wieder ansteigen (Decay-Halbwertszeit 7 Tage).
4. Bestehende Aufrufer der Engine (`BaseView`-Snapshot-Upload, `SummaryViewModel`,
   `BodyCompositeScoreCard`) verhalten sich unverändert (Default `referenceDate`).

---

## Bewusst NICHT Teil dieses Tickets (Backlog)

- Pro-Muskelgruppe-Trends (7 Linien) — vorerst nur Gesamtwert.
- Persistierung/lokales SwiftData-Snapshot-Model (Option C) — separates Ticket, falls
  Performance bei stark wachsender Session-Zahl je relevant wird (14× Engine-Lauf).
- Auswertung der bereits vorhandenen `muscle_recovery_snapshots` in Supabase.
- Timeframe-Picker (7/14/30 Tage) — `days`-Parameter ist bereits vorbereitet.

---

## Risiken & Hinweise

- **Performance:** 14× `analyze()` pro Refresh. Bei deiner aktuellen Datenmenge
  vernachlässigbar (jede Analyse iteriert nur über Sätze der letzten 14 Tage relativ
  zum jeweiligen Stichtag). Falls je spürbar: `recoveryTrend` nur bei `strengthSessions`-
  Änderung neu berechnen (passiert über `recalculate` ohnehin schon).
- **Korrektheit:** Der `$0.date <= now`-Filter in Phase A ist essenziell — ohne ihn
  würde der rückwirkende Wert „zukünftige" Workouts einrechnen.
- **Kein neuer Typ:** `TrendPoint` aus `StatisticCalcEngine.swift` wiederverwenden.
