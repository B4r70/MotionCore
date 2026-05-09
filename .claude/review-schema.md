# MotionCore Review Schema

Verbindliches Format für alle Review-Findings, erstellt durch den
`motioncore-reviewer`-Agent. Jedes Finding folgt exakt diesem Schema,
damit der Output sowohl maschinell parsebar (für `motioncore-developer`)
als auch im Chat lesbar bleibt.

---

## Datei-Struktur

Jede Review-Datei wird abgelegt unter:

`~/developments/MotionCore/.claude/reviews/review-L{layer}-{YYYY-MM-DD}.md`

Aufbau der Datei:

1. **Header-Block** mit Metadaten
2. **Executive Summary** (max. 10 Bullets + Severity-Counts + Top-3-Themen + Top-3-Wins)
3. **Findings** — gruppiert nach Datei, sortiert nach Severity innerhalb der Datei

---

## Header-Block (Pflicht, oben in der Datei)

```markdown
# Code Review — Layer {N}: {Layer-Name}

**Datum:** YYYY-MM-DD
**Reviewer:** motioncore-reviewer (Opus)
**Scope:** {kurze Beschreibung der untersuchten Bereiche}
**Codebase-Stand:** {Git-Commit-Hash oder Branch}
**Gelesene Dateien:** {Anzahl}
**Gefundene Issues:** {Gesamtzahl}
```

---

## Executive Summary (Pflicht, direkt nach Header)

```markdown
## Executive Summary

### Severity-Verteilung
- 🔴 Critical: {n}
- 🟠 High: {n}
- 🟡 Medium: {n}
- 🔵 Low: {n}
- ⚪ Info: {n}

### Top-3-Themen (was zieht sich durch?)
1. {Thema} — betrifft {n} Findings
2. {Thema} — betrifft {n} Findings
3. {Thema} — betrifft {n} Findings

### Top-3-Wins (was ist gut gemacht?)
1. {konkrete Beobachtung mit Datei-Verweis}
2. {konkrete Beobachtung mit Datei-Verweis}
3. {konkrete Beobachtung mit Datei-Verweis}

### Empfehlung
{1–3 Sätze: Was sollte zuerst angegangen werden? Welche Findings
können warten? Gibt es Cluster, die zusammen gefixt werden sollten?}
```

---

## Finding-Schema (für jeden Befund identisch)

````markdown
### [L{layer}-{seq:03d}] {kurze prägnante Überschrift}

**Severity:** {🔴 Critical | 🟠 High | 🟡 Medium | 🔵 Low | ⚪ Info}
**Kategorie:** {z.B. "CalcEngine-Reinheit", "SwiftUI-State", "Persistenz"}
**Datei:** {relativer Pfad ab MotionCore/}:{startZeile}–{endZeile}
**Verwandte Findings:** {optional: [L3-002], [L3-005] wenn Cluster}

**Fundstelle:**
```swift
{Code-Ausschnitt — max. 15 Zeilen, der die Stelle eindeutig zeigt}
```

**Problem:**
{1–3 Sätze: Was ist das technische Problem? Sachlich, ohne Wertung.}

**Auswirkung:**
- {Konkrete Folge 1, z.B. "Tests werden flaky"}
- {Konkrete Folge 2, z.B. "Crash bei leerem Plan"}
- {Konkrete Folge 3, falls relevant}

**Empfohlene Korrektur:**
{1–3 Sätze: Welche Strategie löst das Problem? Warum diese und keine andere?}

**Konkreter Fix:**
```swift
{Patch-fertiger Code, der direkt eingespielt werden kann.
 Bei größeren Änderungen: nur die relevanten Zeilen, Rest mit
 // ... unverändert markieren.}
```

**Aufwand:** {<5 Min | ~10 Min | ~30 Min | ~1h | mehrere Stunden}
**Risiko:** {Niedrig | Mittel | Hoch}
**Diskussion erwünscht:** {Ja | Nein}
**Begründung Diskussion:** {nur wenn "Ja": kurzer Hinweis, was unklar ist}
````

---

## Regeln für Findings

### Severity-Kalibrierung

| Severity | Wann verwenden | Beispiele |
|---|---|---|
| 🔴 Critical | Datenverlust, Crash, Sync-Korruption, Memory Leak in Hot Path | `try?` schluckt CloudKit-Save-Error; Force-Unwrap auf Optional aus Netzwerk |
| 🟠 High | Etablierte Konvention verletzt, klare Bug-Falle, spürbare Performance-Falle | CalcEngine schreibt UserDefaults; `@Published` triggert View-Storm |
| 🟡 Medium | Code-Smell, mittlere Wartbarkeitsgrenze, Inkonsistenz mit Nachbar-Code | Datei 750 Zeilen; doppelte Logik in zwei Views |
| 🔵 Low | Stilistisch, Namensgebung, Kommentar-Qualität | `func calc()` statt `func calculateScore()` |
| ⚪ Info | Beobachtung, kein Handlungsbedarf — nur zur Awareness | "Modul könnte später Watch-tauglich werden" |

**Wichtig:** Severity nicht inflationieren. Wenn alles "High" ist, ist nichts mehr "High".

### Diskussion erwünscht: Ja vs. Nein

- **Nein** = klare Konventions-Verletzung, eindeutiger Bug, mechanischer Fix
- **Ja** = echter Architektur-Trade-off, mehrere valide Lösungen, Auswirkung auf andere Module unklar, oder Findings, die mit gesperrten Bereichen (ExerciseRating, PlanUpdateCalcEngine) angrenzen

Bei "Ja" muss die Begründung *konkret* sein ("Lösung A spart Tokens, Lösung B ist robuster — Trade-off offen"), nicht generisch ("könnte man diskutieren").

### Gesperrte Bereiche

Findings in folgenden Modulen werden **nur als Bug-Hinweis** geführt,
nie als Refactoring-Vorschlag:

- `ExerciseRating` und alle groupKey-basierten Matchings
- `PlanUpdateCalcEngine` (strukturelle Änderungen)
- Bewusste German/English-Mischung (UI=Deutsch, Identifier=Englisch, Comments=Deutsch, Agent-Prompts=Englisch)

Wenn dort echte Bugs auffallen: Severity vergeben, aber im Fix-Vorschlag
explizit anmerken: "Strukturelle Änderung gesperrt — minimaler Patch:"

### Code-Snippet-Regeln

- Maximal 15 Zeilen pro Fundstelle
- Keine Auslassung mit `...` mitten im Code, der das Problem zeigt
- Bei langen Methoden: nur die problematische Region zitieren, mit Kommentar `// ... Setup oben ausgelassen`

---

## Beispiel-Finding (Vorlage zum Abgleich)

````markdown
### [L3-007] ProgressionCalcEngine: Side-Effect über UserDefaults

**Severity:** 🟠 High
**Kategorie:** CalcEngine-Reinheit
**Datei:** Services/Calculation/ProgressionCalcEngine.swift:142–158
**Verwandte Findings:** —

**Fundstelle:**
```swift
static func calculate(input: Input) -> Output {
    let result = computeProgression(input)
    UserDefaults.standard.set(Date(), forKey: "lastProgression")
    return result
}
```

**Problem:**
CalcEngines sind laut Projekt-Konvention pure Structs ohne Side Effects.
Der UserDefaults-Schreibzugriff bricht diese Garantie.

**Auswirkung:**
- Engine ist nicht mehr deterministisch testbar (Tests werden flaky)
- Engine kann nicht in SwiftUI-Previews verwendet werden
- Zustand leakt zwischen Sessions, ohne dass es im Aufrufer sichtbar ist

**Empfohlene Korrektur:**
Side-Effect aus dem Engine herausziehen. Engine liefert nur das Ergebnis,
der Caller (`WorkoutSessionManager.finishSession`) übernimmt die
UserDefaults-Persistenz.

**Konkreter Fix:**
```swift
// In ProgressionCalcEngine.calculate(): UserDefaults-Zeile entfernen
static func calculate(input: Input) -> Output {
    return computeProgression(input)
}

// In WorkoutSessionManager.finishSession(): nach Aufruf hinzufügen
let result = ProgressionCalcEngine.calculate(input: progressionInput)
UserDefaults.standard.set(Date(), forKey: "lastProgression")
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein
````

---

## Datei-Schluss (Pflicht)

Am Ende der Review-Datei:

```markdown
---

## Statistik

- Gelesene Dateien: {n}
- Untersuchte Zeilen (gesamt): {n}
- Findings pro 1.000 Zeilen: {n}
- Reviewer-Laufzeit: {falls bekannt}

## Nächste Schritte

Für `motioncore-developer`:
- Empfohlene Fix-Reihenfolge: {Liste der IDs in sinnvoller Reihenfolge}
- Cluster, die zusammen gefixt werden sollten: {ID-Gruppen}
- Findings, die manuelles Testen brauchen: {Liste}

Für Bartosz (Diskussion):
- Issues mit "Diskussion erwünscht: Ja": {Liste der IDs}
```