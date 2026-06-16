# Quality Gate — Readiness-Score Bugfix v1.1

**Status:** Approved with minor notes
**Datum:** 2026-06-13
**Commits:** fd18073 (B), bf7c40b (C), c535e5a (A), 684587d (D)

---

## Findings

### [Medium] `HealthBaseline.id` — CloudKit UUID Default Bug, Dedup-Tie-Break degeneriert

- **Datei:** `MotionCore/Models/Core/HealthBaseline.swift` Z.19
- **Problem:** `var id: UUID = UUID()` ist ein property-level Default ohne explizites `self.id = UUID()` im `init`. Exakt das Muster aus CLAUDE.md "CloudKit UUID Default Bug" — `UUID()` wird einmal beim Schema-Migration evaluiert, nicht per-Instanz. CloudKit-synchronisierte Geräte können Rows mit identischer `id` erzeugen. Der Tie-Break in `fetchOrCreate` (`$0.id.uuidString < $1.id.uuidString`) ist dann geräteübergreifend non-deterministisch.
- **Fix:** In `HealthBaseline.init(metricType:)` explizit `self.id = UUID()` hinzufügen.
- **Severity für Einzelgerät-Nutzer:** Niedrig (Dedup wirkt lokal korrekt). Für robuste Multi-Device-Konvergenz: Medium.

### [Low] `windowedDailyMean` — `.strictStartDate` könnte RHR-Samples am Fensterrand verpassen

- **Datei:** `MotionCore/Services/Health/HealthKitManager.swift` (windowedDailyMean)
- **Problem:** `HKQuery.predicateForSamples(withStart:end:options:.strictStartDate)` schließt Samples mit `startDate == windowStart` aus. Apple Watch schreibt RHR-Samples teils mit `startDate` = Mitternacht exakt.
- **Empfehlung:** Beim manuellen Phase-A-Gate prüfen ob `windowedRestingHR` für gestern einen Wert liefert. Falls nil: `options: []` testen.

### [Low] `updateSleepMetric` — `to: Date()` statt `to: cal.startOfDay(for: Date())`

- **Datei:** `MotionCore/Services/Health/HealthBaselineUpdateService.swift` (updateSleepMetric)
- **Problem:** Inkonsistent mit `updateWindowedMetric`, das `startOfDay` verwendet. Kein echter Bug (sleepDuration verwendet selbst startOfDay), aber schlechtere Konsistenz.
- **Empfehlung:** `to: cal.startOfDay(for: Date())` angleichen.

### [Low] Migrations-Flag gesetzt auch bei fehlender HealthKit-Autorisierung

- **Datei:** `MotionCore/App/MotionCoreApp.swift`
- **Problem:** Flag wird nach `forceUpdate` gesetzt unabhängig davon ob HK-Auth erteilt war. Betrifft nur Erstinstallationen ohne bestehende HK-Auth (nicht die Migrations-Zielgruppe).
- **Empfehlung:** Akzeptabler Trade-off, kein Blocker.

### [Info] Label/Modifier-Trennung bewusst, kein Bug

- Score 45 → Label `.normal`, aber Modifier 0.92 — per Plan C.2 absichtlich so. Kein Handlungsbedarf.

### [Info] Grep-Scan nach alten Formeln nicht vollständig automatisiert

- Die 7 geänderten Dateien und View-Delegaten (`ReadinessCard`, `BodyReadinessFactorsCard`) wurden gelesen und sind sauber. Weitere Readiness-Views nicht geprüft.
- **Empfehlung:** Globale Xcode-Suche nach `* 4.0 - 2` und `z + 2` als 30-Sekunden-Check vor Merge.

---

## Positives

- Alle 5 Mapping-Stellen konsistent auf `(z+1.5)/3` / `n*3-1.5` umgestellt. Round-Trip-Parität mathematisch verifiziert.
- Fenster-Konsistenz: `SessionReadinessService` und `HealthBaselineUpdateService` nutzen identische `windowedHRV`/`windowedRestingHR`-Methoden — kein Mismatch.
- `fetchOrCreate` Dedup-Logik korrekt: `sorted`, `dropFirst()`, `context.delete()`, `context.save()`.
- Migrations-Idempotenz korrekt (`guard !UserDefaults.standard.bool(forKey: flagKey) else { return }`).
- Modifier-Schutz eingehalten: beide Switches (Engine + ViewModel) unverändert.
- `windowedDailyMean` korrekt implementiert (Calendar.current, startOfDay, arithmetisch sauber).
- Phase C: Änderung auf eine Datei beschränkt (Single-Source bestätigt).

---

## Manual Verification Required

- [ ] Xcode build (`Cmd+B`) grün
- [ ] `BodyReadinessFactorsCard` und `ReadinessCard` Previews rendern
- [ ] `refineWithUserInput`-Round-Trip: kein Upward-Drift nach mehrmaligem Aufrufen
- [ ] Phase A Gate: Score morgens ≈ Score nachmittags (±3 Punkte) nach Migration
- [ ] `windowedRestingHR` liefert Wert für gestern (strictStartDate-Check)
- [ ] Phase D Gate: genau 4 `HealthBaseline`-Rows in Debug nach Migration
- [ ] Supabase-SQL nach nächstem Stream: 0 Duplikat-Zeilen in `health_baselines`
- [ ] Globale Xcode-Suche nach `* 4.0 - 2` und `z + 2`

---

## Gesamtbewertung

**Approved.** Implementierung inhaltlich solide. Das `HealthBaseline.id`-Finding (Medium) sollte vor dem nächsten Deployment behoben werden — es ist der aus CLAUDE.md bekannte CloudKit UUID Default Bug, direkt im Modell hinter der neuen Dedup-Logik.
