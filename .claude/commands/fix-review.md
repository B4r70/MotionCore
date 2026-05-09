---
description: "Übergibt ausgewählte Review-Findings strukturiert an motioncore-developer zur Umsetzung. Findings mit 'Diskussion erwünscht: Ja' werden abgelehnt — diese erst manuell mit Claude besprechen."
argument-hint: "<ID1> [ID2] [ID3] ... (z.B. L3-007 L3-012 L4-003)"
---

# /fix-review {{args}}

Du orchestrierst die Umsetzung ausgewählter Review-Findings durch
`motioncore-developer`. Du selbst implementierst nichts.

## Argument-Parsing

Argumente: eine oder mehrere Issue-IDs im Format `L{1-5}-{3-stellig}`,
z.B. `L3-007 L3-012 L4-003`.

Falls keine ID übergeben wurde: Frage Bartosz, welche Findings umgesetzt
werden sollen, und breche ab. Starte den Developer NICHT spekulativ.

Falls eine ID nicht dem Format entspricht: Fehlermeldung anzeigen und
abbrechen.

## Ablauf

### 1. Findings sammeln

Lies alle Review-Dateien unter:

`~/developments/MotionCore/.claude/reviews/review-L*-*.md`

Suche jede angeforderte ID. Für jede ID:

- **Gefunden** → extrahiere den kompletten Finding-Block (von `### [ID] ...`
  bis zum nächsten `### ` oder Datei-Ende)
- **Nicht gefunden** → notiere in einer Liste "Nicht gefundene IDs"
- **Mehrfach gefunden** (z.B. weil zwei Reviews überlappen) → nimm das
  Finding aus der neuesten Review-Datei

### 2. Gates prüfen

Bevor irgendetwas an den Developer geht, prüfe für jedes gefundene Finding:

#### Gate A: Diskussion erwünscht
Wenn das Feld `Diskussion erwünscht:` den Wert `Ja` hat → **ablehnen**.
Begründung an Bartosz: "Finding {ID} ist als diskussionswürdig markiert.
Bitte zuerst manuell mit Claude besprechen, dann erneut /fix-review aufrufen."

#### Gate B: Gesperrte Bereiche
Wenn der Fix strukturell `ExerciseRating` oder `PlanUpdateCalcEngine`
betrifft → **ablehnen**, auch wenn der Reviewer ihn nicht so markiert hat.
Begründung: "Finding {ID} betrifft gesperrten Bereich. Bug-Fix nur als
minimaler Patch — nicht über /fix-review."

#### Gate C: Severity-Plausibilität
Wenn die Liste mehr als ein 🔴 Critical enthält und Bartosz nicht
ausdrücklich `--force` als letztes Argument übergeben hat → **warnen**:
"{n} Critical-Findings auf einmal. Empfehlung: einzeln umsetzen mit
Build-Verify dazwischen. Soll ich trotzdem fortfahren?"
Auf Antwort warten.

### 3. Cluster-Gruppierung

Wenn mehrere IDs übergeben wurden, prüfe das `Verwandte Findings:`-Feld
jedes Findings. Bilde Gruppen:

- IDs, die sich gegenseitig referenzieren → eine Gruppe
- Alle anderen → eigene Einzelgruppen

Beispiel:
- `L3-007` listet "Verwandte: L3-012"
- `L3-012` listet "Verwandte: L3-007"
- `L4-003` listet keine Verwandten
→ Zwei Gruppen: `{L3-007, L3-012}` und `{L4-003}`

### 4. Auftrag an motioncore-developer

Pro Gruppe ein separater Aufruf an den Developer (sequenziell, nicht
parallel). Auftrags-Template:

```
Phase {n} von {gesamt}: Umsetzung Review-Findings {ID-Liste der Gruppe}

Quelle: ~/developments/MotionCore/.claude/reviews/{Review-Datei}

Eingebetteter Finding-Block:
---
{kompletter Finding-Block, kopiert aus der Review-Datei}
---

Auftrag:
1. Setze ALLE Findings dieser Gruppe in einem zusammenhängenden Edit um.
2. Halte dich exakt an den "Konkreter Fix"-Vorschlag, sofern technisch
   möglich. Bei Abweichungen: kurz begründen.
3. Halte die MotionCore-Konventionen ein (siehe swift-standards-skill,
   File-Size-Disziplin, ExerciseRating/PlanUpdateCalcEngine unangetastet).
4. Nach jeder Datei-Änderung: kurzer Statusbericht mit Pfad und
   Zeilenbereich.
5. NICHT bauen, NICHT testen — das macht Bartosz manuell. STOPP-Gate.

Beachte: Wenn du beim Umsetzen feststellst, dass der Fix-Vorschlag
fehlerhaft ist oder ein Folgeproblem entstehen würde: STOPP, beschreibe
das Problem und warte auf Anweisung. Nicht eigenmächtig umplanen.
```

### 5. Nach jeder Phase: STOPP-Gate

Nach jeder abgeschlossenen Developer-Phase:

- Zeige Bartosz: welche Findings umgesetzt wurden, welche Dateien geändert
  wurden, welche noch offen sind
- Frage explizit: "Phase {n} abgeschlossen. Bitte manuell builden und testen.
  Soll ich Phase {n+1} starten, oder wartest du mit dem nächsten Schritt?"
- **Nicht** automatisch zur nächsten Phase springen.

### 6. Abschluss

Wenn alle Phasen durch sind:

- Liste der erledigten IDs
- Liste der abgelehnten IDs (mit Begründung pro ID)
- Hinweis: "Erledigte Findings sollten in der Review-Datei markiert werden.
  Soll ich `~/developments/MotionCore/.claude/reviews/{Datei}` patchen und
  die IDs als `**Status:** ✅ Umgesetzt am {Datum}` markieren?"

Auf Antwort warten — markiere nur nach Bestätigung.

## Wichtig

- Du selbst (Claude Code Hauptkonversation) modifizierst KEINE Source-Files.
- Du orchestrierst, der Developer setzt um, Bartosz verifiziert.
- Niemals zwei Phasen ohne STOPP-Gate hintereinander.
- Bei Unsicherheit über einen Finding-Inhalt: an Bartosz zurück, nicht an
  den Developer weitergeben.
- Wenn der Developer einen Fix anders umsetzen will als im Finding
  vorgeschlagen: STOPP, an Bartosz zur Entscheidung.