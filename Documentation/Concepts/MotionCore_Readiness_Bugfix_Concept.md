# Claude Code Instruction — Readiness Bugfix v1.1

**Bezug:** Konzept "ReadinessCalcEngine Bugfix v1.1"
**Profil:** Cardio-Medikation = Ja → Gewichtung HRV 25 / Schlaf 40 / Ruhepuls 15 / Aktivität 15, Baseline-Fenster 42 Tage
**Sprache:** Code/Comments Englisch wo neu, bestehende deutsche Comments beibehalten
**Architektur:** CalcEngine bleibt pure struct (kein SwiftUI, keine Side-Effects). Messfenster-Logik gehört in HealthKitManager/Service, NICHT in die Engine.

> **Grundregel:** Nach JEDER Phase Build verifizieren und explizit "grün" oder "rot" melden. Bei "rot" stoppen und Fehler berichten, nicht weiterbauen. Verifikations-SQL läuft gegen Supabase erst, nachdem die App neue Daten gestreamt hat (nächste Session).

> **Reihenfolge nach Hebel:** B (Mapping) und C (Labels) bringen am meisten und sind am risikoärmsten — daher zuerst. A (HRV-Fenster) ist die saubere Mechanik-Korrektur. D (Dedup) ist Hygiene. E (Schlaf) ist nur Verifikation, kein Code.

---

## Phase 0 — Orientierung (kein Code)

1. Lies via `project_knowledge_search` die aktuellen Implementierungen:
   - `ReadinessCalcEngine.swift` (besonders `normalizedScore`, Mapping `(z + 2.0) / 4.0`)
   - `ReadinessTypes.swift` (`ReadinessLabel.from(score:)`)
   - `SessionReadinessService.swift` (`.max(by:)`-Sample-Auswahl für hrv/restHR)
   - `HealthBaselineUpdateService.swift` (`fetchOrCreate`, `updateMetric`)
   - `HealthKitManager.swift` (`hrvSamples`, `restingHRSamples`, `dailySamples`)
2. Notiere die exakten Signaturen. Plane keine Änderung an `sleepDuration` (laut Concept korrekt).

→ **STOPP-Gate 0:** Kurze Bestätigung, dass alle 5 Dateien gelesen wurden und die Mapping-/Sample-Stellen gefunden sind. Keine Änderung ohne diese Bestätigung.

---

## Phase B — Mapping rezentrieren (Befund 1, Hauptursache)

**Ziel:** Ein durchschnittlicher Tag (z=0) soll nicht 50, sondern ~55 ergeben; gute Tage sollen 70+ leichter erreichen.

1. In `ReadinessCalcEngine.normalizedScore(...)` das Mapping anpassen:
   - Aktuell: `let raw = higherIsBetter ? (z + 2.0) / 4.0 : (-z + 2.0) / 4.0`
   - Neu: Spreizung auf `± 1.5 σ` als Voll-Ausschlag statt `± 2.0 σ`:
     `let raw = higherIsBetter ? (z + 1.5) / 3.0 : (-z + 1.5) / 3.0`
   - Effekt: z=0 → 0,5 bleibt, aber z=+1 → 0,83 statt 0,75; gute Tage erreichen schneller hohe Scores. Schlechte Tage fallen ebenfalls schneller — das ist gewollt (mehr Spreizung, weniger Klumpen um 50).
2. **Optionaler Optimismus-Anker** (nur falls nach Verifikation gewünscht, NICHT sofort): konstanter `+0.05`-Offset auf `baseNormalized` vor `*100`. Erst nach Daten-Check entscheiden — nicht in diesem Schritt einbauen.
3. Die Testszenarien-Kommentare in der Engine aktualisieren, falls vorhanden.

→ **STOPP-Gate B:** Build grün. Unit-Test oder Debug-Override: ein synthetischer Tag mit z=+1 auf allen Metriken liefert overall_score ~80 (vorher ~75). Melde den konkreten Wert.

---

## Phase C — Label-Grenzen verschieben (Befund 3)

**Ziel:** "normal" um den realistischen Erwartungswert zentrieren, "müde" nicht als Dauerzustand.

1. In `ReadinessTypes.swift`, `ReadinessLabel.from(score:)` UND in `ReadinessViewModel.modifier` / `ReadinessCalcEngine` (alle Stellen mit denselben Schwellen!) konsistent anpassen:
   - Aktuell: veryLow 0-30, low 30-50, normal 50-70, good 70-85, excellent 85+
   - Neu: veryLow 0-25, low 25-42, normal 42-65, good 65-82, excellent 82+
2. **WICHTIG — Modifier-Grenzen separat prüfen:** Der Trainings-Modifier (0.85/0.92/1.00/1.05) hat eigene Schwellen in `ReadinessCalcEngine` UND `ReadinessViewModel.modifier`. Diese steuern die Trainingsgewichts-Anpassung und sollten NICHT 1:1 mit den Label-Grenzen wandern — sonst ändert sich ungewollt das Trainingsverhalten. Label-Grenzen (kosmetisch) und Modifier-Grenzen (funktional) getrennt halten. Im Zweifel Modifier-Schwellen unverändert lassen und nur die Label-Schwellen verschieben.

→ **STOPP-Gate C:** Build grün. Liste der geänderten Stellen mit Datei + alter/neuer Schwelle. Bestätige explizit, dass die Modifier-Schwellen bewusst (un)verändert sind.

---

## Phase A — HRV/Ruhepuls konsistentes Messfenster (Befund 2)

**Ziel:** Score tagesstabil machen; Mess- und Baseline-Fenster vereinheitlichen.

1. In `HealthKitManager` zwei neue Methoden (oder Parameter an bestehenden), die HRV/Ruhepuls **für ein definiertes Fenster** liefern — Vorschlag: Mittelwert aller Samples zwischen 00:00 und 10:00 Ortszeit des Stichtags. Begründung: stabilstes, schlafnahes Fenster, am ehesten vergleichbar zwischen Tagen.
2. In `SessionReadinessService` (`captureForSession` UND `computeLive`) den `.max(by:)`-Aufruf ersetzen durch die neue Fenster-Methode.
3. **KRITISCH — Baseline-Konsistenz:** `HealthBaselineUpdateService.updateMetric(.hrv / .restingHR)` muss dasselbe Fenster nutzen. Aktuell ruft es `hrvSamples(daysBack:)` (Tagessamples, gemischt). Wenn der Messwert aus dem 00:00-10:00-Fenster kommt, die Baseline aber aus gemischten Tagessamples, entsteht ein systematischer Bias. Beide auf dieselbe Fenster-Logik umstellen.
4. **Baseline danach neu kalibrieren** — sonst vergleicht der neue Fenster-Messwert gegen die alte gemischte Baseline. Entweder Reset (42 Tage neu) oder retroaktive Neuberechnung aus HealthKit-Historie. Empfehlung: retroaktiv, falls `hrvSamples` historische Daten liefert; sonst Reset + Hinweis-UI.

→ **STOPP-Gate A:** Build grün. Test: Score-Berechnung morgens vs. nachmittags am selben Tag liefert (annähernd) denselben HRV/Ruhepuls-Wert (±3 Punkte im overall_score). Melde beide Werte.

---

## Phase D — Baseline-Duplikate bereinigen (Befund 5)

**Ziel:** Genau 1 HealthBaseline-Row pro metricType; deterministische Auswahl.

1. In `HealthBaselineUpdateService.fetchOrCreate(_:)`: bei mehreren Treffern für denselben `metricTypeRaw` die neueste (`lastUpdated` max) behalten, ältere via `context.delete()` entfernen.
2. Einmal-Migration beim App-Start (oder im UpdateService): alle metricTypes durchgehen, Duplikate konsolidieren.
3. Beachte CloudKit: Löschungen syncen. Sicherstellen, dass nicht beide Geräte gleichzeitig löschen und neu anlegen (Race). Im Zweifel deterministisch die Row mit kleinster `id` (UUID-String) behalten statt `lastUpdated`, um geräteübergreifend dasselbe Ergebnis zu erzwingen.

→ **STOPP-Gate D:** Build grün. Verifikations-SQL nach nächstem Stream:
```sql
SELECT metric_type, count(*) FROM public.health_baselines GROUP BY 1 HAVING count(*) > 1;
```
Muss 0 Zeilen liefern. Melde Ergebnis.

---

## Phase E — Schlaf-Baseline verifizieren (Befund 4, KEIN Code)

**Ziel:** Klären, ob 5,77h ein echtes Problem ist — vor jeglicher Änderung.

1. In der App (Debug-View oder Log) für eine konkrete, dir bekannte Nacht den von `sleepDuration(forNightEnding:)` gelieferten Wert ausgeben.
2. Vergleiche mit der Apple-Health-Detailansicht **derselben Nacht** — und zwar mit der reinen "Schlaf"-Dauer (asleep-Phasen), NICHT der Bettzeit.
3. Nur falls echte Diskrepanz (>30 min unerklärt): neuen Befund dokumentieren, separate Phase planen. Sonst: Befund 4 schließen, 5,77h ist die reale erfasste asleep-Dauer.

→ **STOPP-Gate E:** Vergleichswert App vs. Apple Health melden. Entscheidung dokumentieren: Bug ja/nein.

---

## Phase F — Gesamt-Verifikation (nach einigen Tagen)

Nach 5-7 Tagen mit neuer Logik:
```sql
SELECT count(*) n, round(avg(overall_score),1) avg,
       min(overall_score) min, max(overall_score) max
FROM public.session_readiness
WHERE is_calibrating = false AND captured_at > '2026-06-13';
```
Zielkorridor: avg ~55-60, weiterhin volle Spanne (min<30, max>80), kein Klumpen mehr exakt um 50.

Optional Tageszeit-Recheck (Befund 2 Wirkung):
```sql
WITH local AS (
  SELECT overall_score, extract(hour FROM (captured_at AT TIME ZONE 'Europe/Berlin')) h
  FROM public.session_readiness
  WHERE is_calibrating=false AND captured_at > '2026-06-13'
)
SELECT CASE WHEN h<12 THEN 'vm' ELSE 'nm' END, count(*), round(avg(overall_score),1)
FROM local GROUP BY 1;
```
Differenz vm/nm sollte deutlich kleiner sein als vorher (~11).

---

## Hinweis (separates Thema, NICHT Teil dieser Phase)
`session_readiness` hat 459 Rows bei ~15-20 Sessions. Vermutlich persistiert `computeLive` jeden ReadinessCard-Aufruf. Vor Trend-Features klären, ob das gewollt ist — sonst bläht es die Tabelle und verzerrt Auswertungen. Eigener Konzept-Eintrag.

## Commit-Konvention
Conventional Commits, Englisch. Ein Commit pro Phase, z.B.:
`fix(readiness): recenter z-score mapping to reduce clustering at 50`
`fix(readiness): use fixed 00-10h window for HRV/RHR to remove time-of-day drift`