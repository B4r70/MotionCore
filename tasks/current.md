# Realistischere Muskel-Erholungsberechnung (v1.1)

**Complexity:** Medium

> Konzept: `Documentation/Concepts/MotionCore_Muscle Recovery Adaption_Concept.md` (v1.1). Bei Detailfragen zu Formel-Herleitung und Beispielwerten das Konzept konsultieren.

## Summary

Die Muskel-Erholung fällt heute nach jedem Training auf ~0%, unabhängig von Härte/Dauer, und Bodyweight-Übungen erzeugen wegen des `70.0`-Fallbacks die maximal mögliche Volumen-Fatigue. Drei zusammenhängende, reine Änderungen in `MuscleRecoveryCalcEngine` beheben das: Fatigue bestimmt den Tiefpunkt (Startwert) statt nur die Erholungsdauer, der harte Volumen-Cap wird durch eine glatte Sättigungskurve ersetzt, und der Körpergewicht-Fallback wird mit einem Lasthebelfaktor gedämpft. Plus eine DEBUG-Sektion in den Einstellungen, die die Roh-Fatigue pro Muskel anzeigt — Grundlage für die spätere Konstanten-Kalibrierung. Keine API-, DTO-, Schema- oder Signatur-Änderung.

## Scope

**Included**
- `MuscleRecoveryCalcEngine`: neue Recovery-Formel mit `initialDeficit` (3.1)
- `MuscleRecoveryCalcEngine`: `normalizedVolume` als Sättigungskurve statt hartem Clip (3.2)
- `MuscleRecoveryCalcEngine`: Bodyweight-Lasthebel `bodyweightLeverage = 0.35` auf Körpergewicht-Fallback (3.3-A)
- Zwei neue Konstanten: `fatigueSaturation = 8.0` (Domain-korrigiert, s.u.), `volumeSaturation = 600.0`
- Bodyweight-Lasthebel `bodyweightLeverage = 0.50` (Domain-korrigiert, s.u.)

> **Domain-Korrektur (motioncore-fitness-expert, vom User bestätigt):** Die Konzept-Werte `fatigueSaturation = 4.0` und `bodyweightLeverage = 0.35` saturieren zu früh bzw. unterschätzen große BW-Verbundübungen. Implementiert werden **`fatigueSaturation = 8.0`** (differenziert den realen 5–14-Satz-Bereich statt alles auf ~0% zu quetschen) und **`bodyweightLeverage = 0.50`** (Erwartungswert über BW-Spektrum statt Crunch-spezifisch). Befund: `tasks/domain/muscle_recovery_adaption_validation.md`. Bleiben provisorische Startwerte für die spätere DEBUG-Kalibrierung.
- Neue DEBUG-Settings-Sektion: Roh-Fatigue (`totalFatigueScore`) pro Muskel, read-only

**Explizit ausgeschlossen**
- **3.3-B (Pro-Übung-Lasthebel aus Exercise-DB):** zurückgestellt bis zur Exercise-Data-Quality-Initiative → siehe Backlog
- **Konstanten-Kalibrierung (Konzept-Phase 4):** separater Durchlauf nach 2–3 realen Sessions. Die Konstanten shippen bewusst provisorisch; finale Werte folgen aus den geloggten Realdaten.
- Set-Count-basierte Fatigue (überschneidet sich mit Volume-Landmarks-Feature) — Konzept §6
- `targetRIR`-Fallback-Intensität für nicht-erfasste Sätze — Konzept §6
- Keine Änderung an `MuscleRecoveryTypes.swift`, `RecoveryTrendCalcEngine.swift`, DTOs, Supabase-Schema, UI der bestehenden Recovery-Views

## Affected Files

- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift` — Kern aller drei Formel-Änderungen + zwei neue Konstanten
- `MotionCore/Views/Settings/View/DebugMuscleFatigueSection.swift` — **NEU** — DEBUG-Sektion (analog `DebugReadinessSection.swift`), eigene `@Query StrengthSession`, listet `analyze().detailedScores` als Muskel→`totalFatigueScore`
- `MotionCore/Views/Settings/View/MainSettingsView.swift` — `DebugMuscleFatigueSection()` im bestehenden `#if DEBUG`-Block (L154–157, neben `DebugReadinessSection`)

**Geprüft, keine Änderung nötig:**
- `MuscleRecoveryTypes.swift` — `totalFatigueScore` existiert bereits auf `DetailedMuscleRecovery` (L23)
- `RecoveryTrendCalcEngine.swift` — nutzt `analyze` unverändert
- `SupabaseMuscleRecoverySnapshot.swift` — persistiert nur berechnete Recovery-Werte, kein Fatigue-Feld → kein Schema-Impact

## Exakte Codestellen (verifiziert)

- **Neue Konstanten:** Block `// MARK: - Konstanten` (L17–32), neben `decayHalfLifeDays` (L31–32). `import Foundation` (L13) deckt `exp()` ab — kein neuer Import.
- **`normalizedVolume`:** L228–238. `effectiveWeight` L235, Rückgabe `return min(1.0, raw / 500.0)` L237 → wird ersetzt.
- **Recovery-Formel:** L108–112. Insert vor/an L112 (`let recoveryPercent = min(100.0, (hoursSince / adjusted) * 100.0)`).
- **`fatigueMultiplier` (L240–244):** **bleibt unverändert.** Das hartkodierte `5.0` (L242) ist ein eigener Knopf (Refill-Dauer) und darf NICHT mit dem neuen `fatigueSaturation = 4.0` (Start-Defizit) zusammengeführt/„harmonisiert" werden.

## Risks

- **Trend-Form ändert sich rückwirkend (erwartet, keine Regression):** `RecoveryTrendCalcEngine` rekonstruiert den 14-Tage-Body-Tab-Verlauf über `analyze`. Nach diesem Ship sieht die historische Kurve anders aus (höhere Tiefpunkte bei leichten Sessions, differenziertere Werte). Das ist beabsichtigtes Verhalten, nicht zu jagen.
- **Provisorische Konstanten:** `fatigueSaturation`/`volumeSaturation` sind Bauchgefühl-Startwerte. Bewusst akzeptiert — Kalibrierung ist separate Phase, dafür die DEBUG-Sektion.
- **`fatigueMultiplier`-5.0-Falle:** siehe oben — Refactor-Versuchung „beide auf 4.0 vereinheitlichen" wäre ein Fehler.
- **Mathematik:** `recoveryFraction ≤ 1.0` immer (`initialDeficit ∈ [0,1]`, `timeRecovered ∈ [0,1]`), `adjusted > 0` immer, gelistete Muskeln haben stets `totalFatigue > 0` → kein degenerierter Fall, kein zusätzlicher Guard nötig.

## Implementation Steps

### Phase 1 — Konstanten + `normalizedVolume` (3.2 + 3.3-A)

- [x] **1.1** Zwei `static let`-Konstanten im `// MARK: - Konstanten`-Block ergänzen: `fatigueSaturation: Double = 8.0`, `volumeSaturation: Double = 600.0` (jeweils mit Doc-Kommentar; Doc-Kommentar bei `fatigueSaturation` vermerkt: Domain-korrigierter Startwert, Kalibrierung folgt)
- [x] **1.2** `normalizedVolume` (L228–238) umbauen: `bodyweightLeverage = 0.50` auf den Körpergewicht-Fallback anwenden (`effectiveWeight = weight > 0 ? weight : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0) * bodyweightLeverage`); Rückgabe `return 1.0 - exp(-raw / Self.volumeSaturation)` statt `min(1.0, raw / 500.0)`
- [x] **1.3** `fatigueMultiplier` (L240–244) NICHT anfassen — visuell bestätigt, `5.0` unverändert

> **STOPP-Gate 1:** Build grün (`Cmd+B`).

### Phase 2 — Recovery-Formel (3.1)

- [x] **2.1** In `analyze` (L108–112) die Recovery-Berechnung ersetzen: `initialDeficit = min(totalFatigue / Self.fatigueSaturation, 1.0)`, `timeRecovered = min(1.0, hoursSince / adjusted)`, `recoveryFraction = (1.0 - initialDeficit) + initialDeficit * timeRecovered`, `recoveryPercent = min(100.0, recoveryFraction * 100.0)`. `adjusted` (L111, via `fatigueMultiplier`) bleibt als Refill-Dauer-Steuerung erhalten.

> **STOPP-Gate 2:** Build grün. Spot-Check Konzept §3.1: `totalFatigue = 0.5` → Start ~87%; `totalFatigue ≥ 4` → Start ~0%.

### Phase 3 — DEBUG-Sektion: Roh-Fatigue pro Muskel (Kalibrier-Grundlage)

- [x] **3.1** Neue Datei `DebugMuscleFatigueSection.swift` (`#if DEBUG`, analog `DebugReadinessSection.swift`): eigene `@Query(sort: \StrengthSession.date, order: .reverse) var sessions`, ruft `MuscleRecoveryCalcEngine.analyze(sessions:)` einmal auf, listet `detailedScores` als read-only Zeilen `muscle.displayName → totalFatigueScore` (z.B. 2 Dezimalstellen), absteigend sortiert; Footer-Hinweis auf Kalibrierungs-Zweck. Keine Controls.
- [x] **3.2** `DebugMuscleFatigueSection()` in `MainSettingsView` im bestehenden `#if DEBUG`-Block neben `DebugReadinessSection` eingehängt
- [x] **3.3** `#Preview` mit `PreviewData.sharedContainer` + `AppSettings.shared`

> **STOPP-Gate 3:** Build grün. DEBUG-Build: Einstellungen zeigen Fatigue-Liste mit plausiblen Werten.

### Backlog (NICHT in diesem Durchlauf umsetzen)

- **3.3-B — Pro-Übung-Lasthebel:** `bodyweightLoadFactor`-Feld in `motioncore.exercises`, in `normalizedVolume` statt Pauschal-`0.35` nutzen. Erfordert Schema-Erweiterung + Datenpflege. Erst zusammen mit der Exercise-Data-Quality-Initiative.
- **Kalibrierung (Konzept-Phase 4):** Nach 2–3 realen Sessions die DEBUG-Werte prüfen — harte Sessions sollten `≥ fatigueSaturation` erreichen, leichte deutlich darunter — dann `fatigueSaturation`/`volumeSaturation` nachjustieren.

## Manual Verification

- [x] Xcode Build `Cmd+B` grün nach jeder Phase
- [ ] **Leichtes Mini-Workout (2 Sätze):** trainierte Gruppe fällt nur leicht (~80–90%), nicht auf 0%
- [ ] **Hartes Workout (viele/schwere Sätze):** trainierte Gruppe weiterhin nahe 0%
- [ ] **Bodyweight-Übung (Crunch o.ä., `weight = 0`):** Volumen-Beitrag plausibel < 1.0, nicht mehr maximal
- [ ] **DEBUG-Sektion:** Einstellungen → Fatigue-Liste rendert, Werte differenzieren zwischen Muskeln
- [ ] **Body-Tab-Trend:** Kurve rendert weiterhin (Form darf sich ändern — erwartet), keine Crashs/NaN
- [ ] **Bestehende Recovery-Views:** `MuscleRecoveryDetailView` + Donut rendern unverändert, keine NaN-Prozente

## Open Questions

Keine blockierenden. Provisorische Konstanten sind by-design; finale Werte folgen aus der separaten Kalibrierungs-Phase mit den DEBUG-Daten.

## Rejected Alternatives

- **In-Engine `#if DEBUG print` der Roh-Fatigue:** verworfen. `analyze` läuft 14× pro Body-Tab-Trend-Render → Konsolen-Spam bei jedem Render, und braucht angeschlossenes Xcode. Das untergräbt das eigentliche Ziel (Fatigue nach realen Gym-Sessions on-device ablesen). Die opt-in DEBUG-Settings-Sektion liest dieselben Werte on-demand, spamfrei, ohne Xcode.

---

## Fortschritt

**2026-06-09**

Abgeschlossene Schritte: 1.1, 1.2, 1.3, 2.1, 3.1, 3.2, 3.3

Geänderte Dateien:
- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift` — drei neue `static let` (`fatigueSaturation`, `volumeSaturation`, `bodyweightLeverage`), `normalizedVolume` auf Sättigungskurve + BW-Leverage, Recovery-Formel mit `initialDeficit`/`timeRecovered`/`recoveryFraction`
- `MotionCore/Views/Settings/View/DebugMuscleFatigueSection.swift` — NEU, `#if DEBUG`, `@Query StrengthSession`, listet Fatigue absteigend, Preview mit `PreviewData.sharedContainer`
- `MotionCore/Views/Settings/View/MainSettingsView.swift` — `DebugMuscleFatigueSection()` im `#if DEBUG`-Block

Build-Status: grün nach jeder Phase (Phase 1, 2, 3)

Verbleibend: Manuelle Verifikation (Trainer-Tests), Kalibrierung nach realen Sessions (separater Durchlauf)
