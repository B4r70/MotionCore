# Konzept: ReadinessCalcEngine Bugfix v1.1

**Status:** Concept (nicht implementiert)
**Erstellt:** 13.06.2026
**Bezug:** Readiness-Score erreicht produktiv nie >50, "Etwas müde heute" als Dauerzustand
**Profil:** Cardio-Medikation = Ja → Gewichtung HRV 25 / Schlaf 40 / Ruhepuls 15 / Aktivität 15, Baseline-Fenster 42 Tage

---

## 1. Problembeschreibung (Beobachtung)

Seit ~4-5 Wochen produktiv. Score überschreitet nie 50 Punkte, obwohl Apple-Health-Schlafscore regelmäßig 82-98 zeigt. Morgens gelegentlich hoch, nachmittags konstant tief. Dauer-Label: "Etwas müde heute".

## 2. Datenanalyse (Supabase, echte Werte)

Auswertung über `public.session_readiness` (459 Rows, davon 9 calibrating) und `public.health_baselines`:

| Kennzahl | Wert | Interpretation |
|----------|------|----------------|
| avg overall_score | 53,3 | Score zentriert um 50 |
| min / max | 11 / 93 | volle Spanne wird genutzt, aber Mitte dominiert |
| avg hrv_score | 0,600 | leicht positiv |
| avg sleep_score | 0,495 | **exakt neutral — Schlaf zahlt nichts ein** |
| avg resting_hr_score | 0,691 | gut |
| avg activity_score | 0,415 | drückt nach unten |

**Tageszeit-Split (nicht-kalibrierend):**

| Tageszeit | n | avg_score | avg_hrv |
|-----------|---|-----------|---------|
| mittags (11-16) | 28 | 63,9 | 0,714 |
| nachmittags/abends (>=16) | 422 | 52,7 | 0,592 |

→ HRV-getriebener Tageszeit-Abfall von >11 Punkten. Deckt sich exakt mit der Beobachtung.

**Baselines (`health_baselines`):**

| Metrik | rolling_mean | std_dev | CV | sample_count |
|--------|-------------|---------|-----|--------------|
| sleep | **5,77 h** | 1,18 | 0,204 | 42 |
| hrv | 26,53 ms | 5,66 | 0,213 | 43 |
| restingHR | 63,84 bpm | 3,04 | 0,048 | 43 |
| activity | 1095 kcal | 423 | 0,387 | 42 |

→ Zusätzlich: **je 2 Rows** für sleep / activity / restingHR (April + Juni Kalibrierung) in Supabase.

## 3. Root-Cause-Analyse (5 Befunde)

### Befund 1 — Z-Score-Normalisierung zentriert strukturell auf 50 (hoch)
`normalizedScore()`: `raw = (z + 2.0) / 4.0`. Ein durchschnittlicher Tag (z=0 = exakt eigene Baseline) → 0,5 → Score 50. Da die Baseline der eigene Rolling-Mean ist, liegt man per Definition ~50% der Zeit darunter. Für Score 70 ist gewichtet z≈+0,8 über alle Metriken nötig — statistisch selten. Erwartungswert ≈ 50 ist mathematisch eingebaut, kein Zufall.

### Befund 2 — HRV/Ruhepuls: "letzter Sample des Tages" → Tageszeit-Drift (mittel, Mechanik klar / Effektgröße unsicher)
`SessionReadinessService` zieht via `.max(by: { $0.key < $1.key })?.value` den **jüngsten Einzelsample**. Apple Watch misst SDNN über den Tag verstreut; Tageswerte liegen unter Nachtwerten. Morgens ist der jüngste Sample noch der hohe Nachtwert → Score ok; nachmittags ein niedriger Tageswert → Score fällt. Das ist ein **echter Designfehler** (Punktwert statt definiertem Fenster), unabhängig von der Effektgröße.
*Datenlage:* Mittags-Split (n=28) zeigt Score 63,9 / HRV 0,714 vs. Nachmittag (n=422) 52,7 / 0,592 — Trend klar. Reiner Vormittag (<12h) aber nur n=2 → die genaue Effektgröße ist statistisch dünn belegt. Richtung sicher, +11 Punkte eher Obergrenze.

### Befund 3 — Label-Grenzen zu eng (mittel)
`ReadinessLabel`: 30-50 = "Etwas müde heute", 50-70 = "Normale Tagesform". Da der Erwartungswert ~53 ist und der Nachmittags-Drift drückt, landet ein großer Teil der Tage knapp unter 50 → Dauer-Label "müde", obwohl es normale Tage sind.

### Befund 4 — Schlaf-Baseline möglicherweise zu niedrig (UNBESTÄTIGT, zurückgestuft)
`rolling_mean = 5,77h`. **Erste Hypothese (Aggregations-Bug) widerlegt:** Code-Review zeigt, `sleepDuration(forNightEnding:)` summiert korrekt alle asleep-Kategorien (`case .awake, .inBed: break; default: += duration`), Fenster 18:00 Vortag – 12:00 Stichtag. Verteilungs-Check (`width_bucket` über sleep_score): Scores streuen über die volle Spanne (34× ~1.0, 22× ~0), kein Klemmen bei 0,5 — der Faktor funktioniert mechanisch.

**Verbleibende offene Frage:** Ist 5,77h realistisch? Möglich, dass das deine reale *erfasste asleep-Dauer* ist (reine Schlafphasen ohne inBed/awake), die naturgemäß unter der Bettzeit und unter dem Apple-"Schlafscore" liegt. **Aus Supabase nicht final klärbar** (HealthKit-Rohsamples liegen nicht dort). → Kein Fix in dieser Phase; stattdessen Verifikationsschritt: in der App den erfassten asleep-Wert einer bekannten Nacht gegen die Apple-Health-Detailansicht vergleichen. Nur falls dort eine echte Diskrepanz auftritt, wird ein Fix nachgezogen.

*Lehre: Befund 4 war in der ersten Analyse überzogen — als "kaputt" eingestuft auf Basis einer Annahme über die Aggregation, die der Code widerlegt. Datencheck vor Diagnose.*

### Befund 5 — Doppelte Baseline-Rows pro Metrik (mittel) — NEU
Je 2 Einträge für sleep/activity/restingHR (April- + Juni-Kalibrierung). `fetchOrCreate` matcht über `metricTypeRaw`, aber `baselines.first { $0.metricType == type }` ist bei Duplikaten nicht-deterministisch → potenziell wird die alte (schlechtere) Baseline gezogen. Quelle: vermutlich CloudKit-Sync-Duplikat oder alte Kalibrierung nie bereinigt.

> **Hinweis zur Datenmenge:** 459 Rows bei ~15-20 Sessions deutet darauf hin, dass auch Live-Berechnungen (jeder ReadinessCard-Aufruf via `computeLive`?) persistiert werden, nicht nur 1× pro Session. Vor dem Bugfix klären — sonst verzerrt das Trend-Auswertungen und bläht die Tabelle auf. (Separates Thema, nicht Teil dieser Phase, aber notieren.)

## 4. Lösungskonzept

Reihenfolge nach Hebelwirkung: **4 → 2 → 1 → 3 → 5**. Befund 4 zuerst, weil größter Einzelhebel und Voraussetzung für sinnvolles Mapping-Tuning (Befund 1).

### Lösung 4 — Schlaf-Messung korrigieren
HealthKit `HKCategoryValueSleepAnalysis` korrekt aggregieren: alle `asleep*`-Kategorien (`asleepCore`, `asleepDeep`, `asleepREM`, ggf. `asleepUnspecified`) summieren, `inBed` und `awake` ausschließen. Überlappende Samples (Watch + iPhone + Drittapps) deduplizieren (Union der Intervalle, nicht Summe). Danach Baseline **neu kalibrieren** (Reset + 42 Tage, oder retroaktiv aus HealthKit-Historie neu berechnen).
- *Trade-off Reset:* sauber, aber 42 Tage neue Sammelphase. *Retroaktiv:* sofort gültig, aber mehr Code im UpdateService.
- *Verifikation:* Schlaf-Baseline-mean muss nach Fix bei ~7-7,5h liegen.

### Lösung 2 — Konsistentes HRV/Ruhepuls-Messfenster
Statt jüngstem Sample: definiertes Fenster (Vorschlag: Nacht/Morgen 00:00-10:00, Mittelwert). Kritisch: **Baseline aus demselben Fenster bauen** — sonst Messwert ↔ Baseline-Mismatch. Aktuell mischt die Baseline (`hrvSamples(daysBack:)`) Tag+Nacht, verglichen wird aber gegen den Tages-Sample.
- *Trade-off:* Score wird tagesstabil (gleicher Wert morgens wie abends) — für eine "Tagesform" eigentlich korrekt, aber die "Live über den Tag"-Dynamik entfällt. Falls die gewünscht ist: bewusst designen, nicht als Nebeneffekt eines Sample-Glücksspiels.

### Lösung 1 — Mapping spreizen / rezentrieren
Nach Fix 4+2 mit echten Daten neu kalibrieren. Optionen:
- (a) `(z + 1.5) / 3.0`: normaler Tag bleibt 50, gute Tage erreichen 70+ schneller.
- (b) z=0 bewusst auf ~55 mappen (leicht optimistischer Anker).
- *Empfehlung:* erst nach Fix 4+2 entscheiden, dann mit frischen Score-Daten justieren. Vorher kalibrieren wäre auf kaputter Schlafmessung aufgebaut.

### Lösung 3 — Label-Grenzen verschieben
Vorschlag: veryLow <25, low 25-42, **normal 42-65**, good 65-82, excellent >82. "normal" um den realistischen Erwartungswert zentrieren.
- *Trade-off:* kosmetisch, aber sofort spürbar. Unabhängig von 1/2/4 sinnvoll. Risiko: bei zu breitem "normal" wird der Score weniger aussagekräftig — Grenzen an die Verteilung NACH Fix 4+2 anpassen.

### Lösung 5 — Baseline-Duplikate bereinigen
Dedup-Logik im `HealthBaselineUpdateService`: pro `metricType` nur 1 Row, beim Update via `fetchOrCreate` Duplikate löschen (neueste behalten). Einmalige Migration für Altbestand.

### Offen / diskutabel (Bauchgefühl, nicht Fakt)
`activityYesterday` mit `higherIsBetter: true` = "viel Aktivität gestern → bessere Readiness". Whoop/Oura modellieren gestrige Last als Recovery-Bedarf (umgekehrt). Mit 15% Gewicht (Cardio-Profil) relevant. Beide Lesarten vertretbar — bewusst entscheiden, nicht in diese Bugfix-Phase mischen.

## 5. Phasenplan mit STOPP-Gates

> Jede Phase endet mit Build-Verifikation. Grün/Rot explizit, kein vages "passt".

- **Phase A — Schlaf-Messung (Befund 4)**
  HealthKitManager `sleepDuration` korrigieren (alle asleep-Kategorien, Intervall-Union). Unit-Test mit Mock-Samples (überlappende Phasen). → STOPP-Gate: Build grün + Testfall liefert ~7,5h für eine Nacht.

- **Phase B — Schlaf-Baseline neu kalibrieren (Befund 4)**
  Reset oder retroaktive Neuberechnung. → STOPP-Gate: Baseline-mean Schlaf ~7-7,5h verifiziert (Debug-View oder Supabase nach nächstem Stream).

- **Phase C — HRV/Ruhepuls-Fenster (Befund 2)**
  Mess- und Baseline-Fenster vereinheitlichen (00:00-10:00 Mittelwert). → STOPP-Gate: Build grün, Score morgens ≈ Score nachmittags (±3) im Test.

- **Phase D — Baseline-Dedup (Befund 5)**
  Dedup in fetchOrCreate + Einmal-Migration. → STOPP-Gate: genau 1 Row pro metricType.

- **Phase E — Mapping-Tuning (Befund 1)**
  Nach A-D mit frischen Daten Mapping justieren. → STOPP-Gate: avg_score plausibel (Ziel ~55-60 bei normaler Tagesform), Spanne erhalten.

- **Phase F — Label-Grenzen (Befund 3)**
  Grenzen an neue Verteilung anpassen. → STOPP-Gate: Build grün, "normal" deckt den Erwartungswert ab.

## 6. Nächster Schritt
Claude-Code-Instruction-Dokument mit nummerierten Schritten je Phase, STOPP-Gates und Verifikations-SQL gegen Supabase. Erst nach Freigabe dieses Concepts.

## 7. Notion-Tracker (Vorschlag)
- Titel: Readiness-Score Bugfix v1.1
- Type: 🐛 Bug
- Priority: 🟠 High
- Area: Readiness
- Status: Concept
