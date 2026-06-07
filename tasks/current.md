# Erholungs-Trend (Body-Tab)

**Complexity:** Medium

> Spezifikation: `Documentation/Instructions/MotionCore_RecoveryTrend_Instruction.md` (v1.0). Bei Detailfragen zur Chart-View oder Engine-Logik das Instruction-Dokument konsultieren.

## Summary

Der Body-Tab-Reiter "Trend" zeigt dauerhaft "Keine Einträge", weil `BodyRecoveryTrendCard` ein reiner Platzhalter ist. Der Erholungswert ist deterministisch aus abgeschlossenen Sessions rekonstruierbar. Lösung: `MuscleRecoveryCalcEngine.analyze` für 14 zurückliegende Stichtage ausführen und den Verlauf als Swift-Charts-Linie darstellen. Funktioniert sofort und rückwirkend, bleibt 100% lokal.

## Scope

**Included**
- `MuscleRecoveryCalcEngine`: `referenceDate`-Parameter + Zukunfts-Filter (verhaltensneutral für bestehende Aufrufer)
- `RecoveryTrendCalcEngine`: Neue pure CalcEngine, wiederverwendet `TrendPoint` aus `StatisticCalcEngine.swift`
- `BodyViewModel`: `recoveryTrend`-Property + Berechnung in `recalculate`
- `BodyRecoveryTrendCard`: Umbau von Platzhalter zu Swift Charts (LineMark + AreaMark)
- `BodyView`: Verdrahtung `trend: viewModel.recoveryTrend`

**Explizit ausgeschlossen**
- Pro-Muskelgruppe-Trends (7 Linien)
- Persistierung / SwiftData-Snapshot-Model
- Supabase `muscle_recovery_snapshots` Auswertung
- Timeframe-Picker (7/14/30 Tage) — `days`-Parameter ist vorbereitet

## Affected Files

- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift` — `referenceDate`-Parameter + `$0.date <= now` Filter
- `MotionCore/Services/Calculation/RecoveryTrendCalcEngine.swift` — **NEU** — Pure struct, 14× Engine-Lauf, liefert `[TrendPoint]`
- `MotionCore/Views/Body/BodyViewModel.swift` — `recoveryTrend: [TrendPoint]` Property + Aufruf in `recalculate`
- `MotionCore/Views/Body/BodyRecoveryTrendCard.swift` — Kompletter Umbau: `trend`-Parameter, Swift Charts, EmptyState-Logik
- `MotionCore/Views/Body/BodyView.swift` — `BodyRecoveryTrendCard(trend: viewModel.recoveryTrend)`

## Risks

- **Xcode-Target-Membership:** `RecoveryTrendCalcEngine.swift` muss dem MotionCore-iOS-Target zugewiesen sein
- **Korrektheit Zukunfts-Filter:** `$0.date <= now` in Phase A ist essenziell — ohne ihn würden rückwirkende Analysen "zukünftige" Workouts einrechnen
- **Performance:** 14× `analyze()` pro Refresh — bei aktueller Datenmenge vernachlässigbar

## Implementation Steps

### Phase A — Engine um `referenceDate` erweitern (verhaltensneutral)

- [x] **A.1** `MuscleRecoveryCalcEngine.swift` — Signatur ändern: `referenceDate: Date = Date()` Parameter hinzufügen
- [x] **A.2** `let now = Date()` ersetzen durch `let now = referenceDate`
- [x] **A.3** Zukunfts-Filter: `&& $0.date <= now` zum Session-Filter hinzufügen

> **STOPP-Gate A:** Build grün. Bestehende Aufrufer kompilieren unverändert.

### Phase B — `RecoveryTrendCalcEngine` anlegen

- [x] **B.1** Neue Datei `RecoveryTrendCalcEngine.swift` erstellen (pure struct, `trend()` + `isEmpty()`)
- [x] **B.2** Xcode-Target-Membership prüfen

> **STOPP-Gate B:** Build grün.

### Phase C — `BodyViewModel` um Trend erweitern

- [x] **C.1** `recoveryTrend: [TrendPoint]` Property ergänzen
- [x] **C.2** In `recalculate(sessions:)` am Ende `RecoveryTrendCalcEngine.trend(sessions:)` aufrufen

> **STOPP-Gate C:** Build grün.

### Phase D — `BodyRecoveryTrendCard` umbauen (Swift Charts)

- [x] **D.1** Kompletter Umbau: `trend`-Parameter, LineMark + AreaMark, EmptyState-Logik, `.glassCard()`
- [x] **D.2** Preview mit Sample-Daten aktualisiert

> **STOPP-Gate D:** Build grün. Preview rendert Chart.

### Phase E — Aufrufstelle in `BodyView` verdrahten

- [x] **E.1** `BodyRecoveryTrendCard(trend: viewModel.recoveryTrend)` statt parameterlos

> **STOPP-Gate E:** Build grün. Body → Trend zeigt Linie.

## Manual Verification

- [x] Xcode Build `Cmd+B` grün nach jeder Phase
- [ ] **Mit Trainingsdaten:** Body → Trend zeigt Linie 0–100%, x-Achse letzte 14 Tage
- [ ] **Ohne Sessions:** Card zeigt EmptyState
- [ ] **Plausibilität:** Nach hartem Workout bricht der Wert ein, steigt danach wieder an
- [ ] **Bestehende Aufrufer:** SummaryViewModel und BodyViewModel Recovery-Analyse unverändert

---

## Fortschritt

**07.06.2026 — 18:59 Uhr**

Abgeschlossene Schritte: A.1, A.2, A.3, B.1, B.2, C.1, C.2, D.1, D.2, E.1

Modifizierte Dateien:
- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift` — referenceDate-Parameter + Zukunfts-Filter
- `MotionCore/Services/Calculation/RecoveryTrendCalcEngine.swift` — NEU angelegt
- `MotionCore/Views/Body/BodyViewModel.swift` — recoveryTrend Property + Berechnung
- `MotionCore/Views/Body/BodyRecoveryTrendCard.swift` — Komplettumbau zu Swift Charts
- `MotionCore/Views/Body/BodyView.swift` — trend-Parameter verdrahtet

Alle Build-Gates A–E: grün. Verbleibend: manuelle Verifikation im Simulator/Gerät.

## Open Questions

Keine.
