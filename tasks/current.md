# Readiness-Score Bugfix v1.1

**Complexity:** Large

> Bezug: `Documentation/Concepts/MotionCore_Readiness_Bugfix_Concept.md` (Claude-Code-Instruction mit STOPP-Gates) und `MotionCore_Readiness_Correcture_Concept.md` (Ursachenanalyse, 5 Befunde).
> **Implementierungsreihenfolge laut Instruction: B → C → A → D → E** (nach Hebel/Risiko).
> Profil: Cardio-Medikation = Ja → Gewichtung HRV 25 / Schlaf 40 / Ruhepuls 15 / Aktivität 15, Baseline-Fenster 42 Tage.
> **Grundregel: Ein Commit pro Phase. Nach JEDER Phase Build verifizieren (grün/rot). Bei rot stoppen.**

## Summary

Der Readiness-Score überschreitet produktiv nie ~50 Punkte und zeigt dauerhaft "Etwas müde heute". Ursache ist ein Bündel von 4 Code-Befunden plus 1 Verifikationsfrage. Ziel: Score realistisch um ~55–60 zentrieren, "normal" als Erwartungswert-Label, Tageszeit-Drift eliminieren, Baseline-Duplikate bereinigen. Wert: Der Kern-Indikator der App wird wieder aussagekräftig und steuert Trainingsempfehlungen korrekt.

## Scope

**Included**
- Phase B: Z-Score-Mapping rezentrieren `(z+2.0)/4.0` → `(z+1.5)/3.0` inkl. aller 4 inversen Rückrechnungs-Stellen.
- Phase C: Label-Grenzen verschieben (NUR `ReadinessLabel.from(score:)`).
- Phase A: HRV/Ruhepuls auf konsistentes Messfenster 00:00–10:00 Ortszeit (Messwert UND Baseline) + retroaktive Baseline-Neukalibrierung.
- Phase D: Baseline-Duplikate deterministisch bereinigen (fetchOrCreate + Einmal-Migration).
- Phase E: Schlaf-Verifikation (KEIN Code, kein Developer-Schritt).

**Explicitly excluded**
- Modifier-Schwellen (0.85/0.92/1.00/1.05) — bleiben unverändert (siehe Phase C Constraint).
- Optionaler `+0.05`-Optimismus-Anker — erst nach Daten-Check (Phase F), NICHT jetzt.
- `sleepDuration(forNightEnding:)`-Aggregation — laut Concept korrekt, kein Fix.
- `higherIsBetter`-Lesart von `activityYesterday` — separates Thema.
- 459-Rows-Aufblähung von `session_readiness` (`computeLive` persistiert?) — separates Konzept, nur notiert.
- Phase F (Gesamt-SQL-Verifikation nach 5–7 Tagen) — nicht Teil der Implementierung.

## Affected Files

- `MotionCore/Services/Calculation/ReadinessCalcEngine.swift` — Phase B: `normalizedScore` + `valueDescription`. Modifier-Switch NICHT anfassen.
- `MotionCore/Services/SessionReadinessService.swift` — Phase B: `scoreToApproximateValue`. Phase A: `.max(by:)`-Ersatz in `captureReadiness` + `computeLive`.
- `MotionCore/Services/ViewModels/ReadinessViewModel.swift` — Phase B: `desc` + `sleepDescription`. Modifier-Switch NICHT anfassen.
- `MotionCore/Services/Calculation/ReadinessTypes.swift` — Phase C: NUR `ReadinessLabel.from(score:)`.
- `MotionCore/Services/Health/HealthKitManager.swift` — Phase A: neue Fenster-Methode + zwei Wrapper.
- `MotionCore/Services/Health/HealthBaselineUpdateService.swift` — Phase A: HRV/RHR-Baseline auf Fenster-Logik. Phase D: `fetchOrCreate` Dedup + Migrations-Methode.
- `MotionCore/App/MotionCoreApp.swift` — Phase A+D: Flag-guarded Einmal-Migration im `.task`.

**Single-Sourcing bestätigt:**
- `ReadinessLabel.from(score:)` ist die EINZIGE Label-Schwellen-Quelle. `ReadinessCalcEngine`, `ReadinessViewModel.label`, `ReadinessCard` delegieren alle dorthin → Phase C = 1-Stellen-Änderung.

## Risks

- **Inverse-Mapping-Inkonsistenz (Phase B, load-bearing):** `scoreToApproximateValue` rechnet `n*4-2` invers zu `(z+2)/4`. Beide Richtungen synchron auf `(z+1.5)/3` / `n*3-1.5` umstellen — sonst driftet `refineWithUserInput` bei jedem Round-Trip nach oben.
- **Mess-↔Baseline-Fenster-Mismatch (Phase A):** Messwert und Baseline MÜSSEN dieselbe Fenster-Methode nutzen, sonst systematischer Bias.
- **Baseline gegen alte Baseline nach Umstellung (Phase A):** Retroaktive Neuberechnung (flag-guarded) beim App-Start löst das sofort.
- **CloudKit-Race bei Dedup (Phase D):** Tie-Break über kleinste `id` (UUID-String) für geräteübergreifende Konvergenz.
- **Regression Trainings-Modifier (Phase C):** Modifier-Switches in Engine + ViewModel NICHT anfassen.

## Implementation Steps

### Phase B — Mapping rezentrieren (Befund 1) — Commit 1

- [x] **B.1** `ReadinessCalcEngine.normalizedScore`: `(z + 2.0) / 4.0` → `(z + 1.5) / 3.0` und `(-z + 2.0) / 4.0` → `(-z + 1.5) / 3.0`
- [x] **B.2** `ReadinessCalcEngine.valueDescription`: inverse Rückrechnung `n*4-2` / `2-n*4` → `n*3-1.5` / `1.5-n*3`
- [x] **B.3** `SessionReadinessService.scoreToApproximateValue`: `n * 4.0 - 2.0` / `2.0 - n * 4.0` → `n * 3.0 - 1.5` / `1.5 - n * 3.0`. Kommentar anpassen.
- [x] **B.4** `ReadinessViewModel.desc`: `(norm * 4.0 - 2.0)` / `(2.0 - norm * 4.0)` → `(norm * 3.0 - 1.5)` / `(1.5 - norm * 3.0)`
- [x] **B.5** `ReadinessViewModel.sleepDescription`: `normalized * 4.0 - 2.0` → `normalized * 3.0 - 1.5`
- [x] **B.6 NICHT ändern:** Modifier-Switch `ReadinessCalcEngine`. Optimismus-Anker `+0.05` NICHT einbauen.
- [x] **STOPP-Gate B:** Build grün ✓. z=+1 → norm=(1+1.5)/3=0.833 → score=**83** ✓ (vorher 75). Commit: fd18073

### Phase C — Label-Grenzen verschieben (Befund 3) — Commit 2

- [x] **C.1** `ReadinessTypes.swift`, `ReadinessLabel.from(score:)`: `0..<30` → `0..<25` (veryLow), `30..<50` → `25..<42` (low), `50..<70` → `42..<65` (normal), `70..<85` → `65..<82` (good), excellent ab 82.
- [x] **C.2 CONSTRAINT:** Modifier-Schwellen in `ReadinessCalcEngine` (0/30/50/85 → 0.85/0.92/1.00/1.05) und `ReadinessViewModel.modifier` BEWUSST UNVERÄNDERT. Label-Grenzen = kosmetisch; Modifier-Grenzen = funktional — getrennt halten.
- [x] **STOPP-Gate C:** Build grün ✓. NUR `ReadinessTypes.swift` geändert ✓. Beide Modifier-Switches unverändert ✓. Score 45 → 42..<65 → `.normal` ✓. Commit: bf7c40b

### Phase A — HRV/Ruhepuls konsistentes Messfenster (Befund 2) — Commit 3

- [x] **A.1** `HealthKitManager`: neue Methode `windowedDailyMean(type:unit:forDate:startHour:endHour:)` — Mittelwert aller Samples 00:00–10:00 Ortszeit.
- [x] **A.2** Zwei Wrapper: `windowedHRV(forDate:)` (SDNN, ms) und `windowedRestingHR(forDate:)` (bpm).
- [x] **A.3** `SessionReadinessService.captureReadiness` UND `computeLive`: `.max(by:)`-Aufrufe für `hrv` und `restHR` durch Fenster-Wrapper ersetzen (beide Stellen).
- [x] **A.4 KRITISCH** `HealthBaselineUpdateService`: HRV/RHR-Baseline-Berechnung auf dieselbe Fenster-Logik umstellen (Tagesmittel 00:00–10:00 pro Tag im 42-Tage-Fenster) via `updateWindowedMetric`.
- [x] **A.5** `MotionCoreApp`: Flag-guarded Einmal-Migration (`UserDefaults` "readinessWindowMigrationV1Done") — `forceUpdate` aufrufen für retroaktive HRV/RHR-Baseline-Neukalibrierung. Zusammen mit D-Migration unter EINEM Flag.
- [x] **STOPP-Gate A:** Build grün ✓. Strukturell: festes 00:00–10:00-Fenster gibt denselben Tagesmittelwert unabhängig von der Tageszeit zurück (kein Drift durch .max(by:) auf partielle Buckets mehr). Commit: c535e5a

### Phase D — Baseline-Duplikate bereinigen (Befund 5) — Commit 4

- [x] **D.1** `HealthBaselineUpdateService.fetchOrCreate`: bei mehreren Treffern pro `metricTypeRaw` die Row mit kleinster `id` (UUID-String) behalten, alle anderen per `context.delete()` entfernen.
- [x] **D.2** `consolidateDuplicateBaselines()`: alle `HealthMetricType.allCases` durchgehen, Duplikate bereinigen, `context.save()`. Flag-guarded zusammen mit A.5 in `MotionCoreApp`.
- [x] **STOPP-Gate D:** Build grün ✓. SQL-Verifikation nach nächstem Sync ausstehend (erfordert Gerät + Supabase-Stream).

### Phase E — Schlaf-Baseline verifizieren (Befund 4) — MANUELL (kein Code-Schritt)

> Reine manuelle Verifikation. Kein Commit, keine Änderung.

- [ ] **E.1** Für eine bekannte Nacht den `sleepDuration(forNightEnding:)`-Wert in der App ausgeben (Debug-Log).
- [ ] **E.2** Mit Apple-Health-Detailansicht derselben Nacht vergleichen (reine asleep-Dauer, NICHT Bettzeit).
- [ ] **E.3** Bei echter Diskrepanz (>30 min): neuen Befund dokumentieren. Sonst Befund 4 schließen.
- [ ] **STOPP-Gate E:** Vergleichswert App vs. Apple Health melden. Entscheidung Bug ja/nein.

## Manual Verification

- [ ] Xcode build nach JEDER Phase grün — bei rot stoppen
- [ ] Phase B: `refineWithUserInput`-Round-Trip driftet nicht (Score nach Energie/Stress-Input bleibt plausibel)
- [ ] Phase B: `BodyReadinessFactorsCard` Previews rendern
- [ ] Phase C: Score 45 zeigt "Normale Tagesform" statt "Etwas müde heute"
- [ ] Phase A: Simulator/Gerät — Score morgens ≈ Score nachmittags (±3 overall)
- [ ] Phase A: HRV/RHR-Baseline-mean nach Migration plausibel (Debug-Section)
- [ ] Phase D: genau 4 Baselines in Debug-Section; Supabase-SQL = 0 Duplikat-Zeilen nach Stream

## Open Questions

- **Migrations-Flag:** `UserDefaults` (gerätelokal, kein Sync) — kein appweiter Sync des Flags gewünscht?
- **Gate-A-Toleranz:** ±3 Punkte ist Plausibilitäts-, keine statistisch harte Grenze (n=2 reiner Vormittag) — akzeptabel?

---

## Fortschritt

**2026-06-13**

**Abgeschlossene Schritte:** B.1–B.6, C.1–C.2, A.1–A.5, D.1–D.2 (Phase E ist Manuell, kein Code)

**Commits:**
- `fd18073` fix(readiness): recenter z-score mapping to ±1.5σ for better score spread (Phase B)
- `bf7c40b` fix(readiness): shift label boundaries to center 'normal' around expected value (Phase C)
- `5385886` fix(readiness): use fixed 00-10h window for HRV/RHR to remove time-of-day drift (Phase A)
- `684587d` fix(readiness): deduplicate baseline rows deterministically via smallest UUID (Phase D)

**Geänderte Dateien:**
- `MotionCore/Services/Calculation/ReadinessCalcEngine.swift` — B.1, B.2
- `MotionCore/Services/SessionReadinessService.swift` — B.3, A.3
- `MotionCore/Services/ViewModels/ReadinessViewModel.swift` — B.4, B.5
- `MotionCore/Services/Calculation/ReadinessTypes.swift` — C.1
- `MotionCore/Services/Health/HealthKitManager.swift` — A.1, A.2
- `MotionCore/Services/Health/HealthBaselineUpdateService.swift` — A.4, D.1, D.2
- `MotionCore/App/MotionCoreApp.swift` — A.5, D (Migration-Flag)

**Offen:** Phase E (manuelle Verifikation), Supabase-SQL nach nächstem Stream (Gate D)
