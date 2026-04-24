# MotionCore — Phase 1.5: Smart Progression Refinements
## Concept-Dokument v1.0

**Autor:** Barto Stryjewski (mit Claude)
**Datum:** 24. April 2026
**Bezug:** `MotionCore_SmartProgression_Concept_v1.1.md`
**Status:** Entwurf zur Freigabe
**Scope:** 4 Bugfixes + 1 Feature-Ergänzung
**Geschätzter Umfang:** ~5-6 Schritte, 3-4 Tage

---

## 0. Kontext

Phase 1 ist implementiert und in Nutzung. Nach der Testphase wurden vier konkrete Probleme identifiziert, die die Qualität von Smart Progression beeinträchtigen. Diese Phase adressiert ausschließlich diese Probleme, keine neuen Features.

---

## 1. Die vier Probleme

### Problem 1: Höchstgewicht statt Modus-Gewicht als Baseline

**Beobachtet bei:** Kabelzug seitliche Raises (Satz 1: 7.5kg, Satz 2+3: 8.2kg)

**Aktuelles Verhalten:** Die Engine nimmt das höchste Gewicht der Session als Baseline für `workingWeight`-Ableitung. Das führt zu verfrühter Progression, wenn der User nur in einzelnen Sätzen spontan steigert, aber das eigentliche Arbeitsgewicht niedriger ist.

**Gewünschtes Verhalten:** Die Engine identifiziert das **Modus-Gewicht** (am häufigsten verwendetes Gewicht) als Baseline. Ausreißer nach oben oder unten im einzelnen Satz werden nicht als neues Arbeitsgewicht interpretiert.

### Problem 2: `isLastSetOfExercise`-Flag wird nicht reaktiv evaluiert

**Beobachtet bei:** Face Pulls (ursprünglich 4 Sätze geplant, auf 3 reduziert)

**Aktuelles Verhalten:** Das Flag `isLastSetOfExercise` wird einmalig beim Abschluss eines Satzes gesetzt. Wenn der User nachträglich die Satzanzahl reduziert, wird der jetzt tatsächlich letzte Satz nicht nachträglich als solcher markiert. Das RIR-Sheet wird nie ausgelöst.

**Gewünschtes Verhalten:**
- Wenn Satzanzahl reduziert wird, wird das Flag reaktiv neu evaluiert
- Der jetzt letzte Satz bekommt `isLastSetOfExercise = true`
- RIR-Prompt wird nachgeholt, falls User noch bei dieser Übung ist
- Falls User bereits bei nächster Übung: „RIR nachtragen"-Option im Satz-Kontextmenü

### Problem 3: Mehrdeutige Semantik von `rpe = 0`

**Beobachtet:** Konflikt zwischen Code-Interpretation und Engine-Logik

**Aktuelles Verhalten:**
- `rpe` hat Default-Wert 0 (bedeutet in RPE-Skala „gar keine Anstrengung", also RIR 10)
- Code interpretiert `rpe = 0` als bewusste User-Angabe („keine Angabe = Angabe")
- Engine interpretiert `rpe = 0` laut Concept als „unbekannt/nicht angegeben"
- Beim Skip wird `rpe = 0` geschrieben → Engine wertet als RIR 10 → aggressive Progressions-Vorschläge möglich

**Gewünschtes Verhalten:** Neues Feld `rpeRecorded: Bool` disambiguiert die beiden Fälle:
- `rpeRecorded = false` → keine User-Angabe, Engine arbeitet konservativ
- `rpeRecorded = true, rpe = 0` → User sagt explizit „war easy" (RIR 10), bigIncrease möglich
- `rpeRecorded = true, rpe = 10` → User sagt „war am Limit" (RIR 0), normale Progression

### Problem 4: `workingWeight` wird nicht automatisch aktualisiert

**Beobachtet:** Übungs-Insights zeigen „Bereit für Steigerung?", aber User muss manuell in den Plan gehen und Gewichte ändern.

**Aktuelles Verhalten:** Die Engine ermittelt, dass ein Progressionsschritt fällig ist, aber das `workingWeight` im `ExerciseProgressionState` wird nicht geändert. Der Placeholder im nächsten Training zeigt weiterhin das alte Gewicht.

**Gewünschtes Verhalten (Option 3 aus Diskussion):**
- Automatische Erhöhung des `workingWeight` nach definierten Kriterien (2 Sessions in Folge RIR 0-2 + alle Ziel-Reps erreicht)
- Retrospektive Insight-Karte: „Arbeitsgewicht erhöht auf X kg" mit Undo-Option
- Plan-Template bleibt unverändert (das ist Aufgabe der `PlanUpdateCalcEngine`, die bei längeren stabilen Trends triggert)

---

## 2. Zielbild und Design-Prinzipien

Die Grundprinzipien aus dem Haupt-Concept bleiben unverändert. Phase 1.5 ergänzt:

1. **Ambiguitätsfreiheit** — Ein-Bit-Flag (`rpeRecorded`) eliminiert semantische Mehrdeutigkeit
2. **Reaktivität** — Zustände werden bei Änderungen neu evaluiert, nicht nur beim Erstellen
3. **Transparenz vor Bestätigung** — Automatische Änderungen werden retrospektiv kommuniziert, nicht vorher abgefragt
4. **Trennung von Arbeitsgewicht und Plan-Template** — Zwei verschiedene Ebenen mit unterschiedlichen Update-Frequenzen

---

## 3. Datenmodell-Änderungen

### 3.1 `ExerciseSet` erweitern

```swift
// NEU
var rpeRecorded: Bool = false
```

**Migration:** Lightweight. Bestehende Sets erhalten `rpeRecorded = false`. Optional kann beim Schema-Update eine Heuristik laufen: Wenn `rpe > 0`, dann `rpeRecorded = true` (für historische Sets).

### 3.2 `ExerciseProgressionState` erweitern

```swift
// NEU
var lastAutoProgressionDate: Date?       // Zeitpunkt der letzten automatischen Erhöhung
var lastAutoProgressionAmount: Double?   // Wie viel erhöht wurde (für Undo)
var autoProgressionUndoable: Bool = false  // True bis zur nächsten Session
```

**Zweck:** Tracking der automatischen Erhöhungen für Insight-Karte und Undo-Funktion.

### 3.3 Keine weiteren Modell-Änderungen

Alle anderen Fixes sind Logik-Änderungen in CalcEngines und UI.

---

## 4. Logik-Änderungen

### 4.1 `ProgressionCalcEngine` — Modus-Gewicht

**Neue Helper-Funktion:**

```swift
private static func modeWeight(from sets: [ExerciseSet]) -> Double? {
    guard !sets.isEmpty else { return nil }

    // Zähle Häufigkeit pro Gewicht
    let weightCounts = sets.reduce(into: [Double: Int]()) { counts, set in
        counts[set.weight, default: 0] += 1
    }

    // Finde Maximum-Häufigkeit
    guard let maxCount = weightCounts.values.max() else { return nil }

    // Alle Gewichte mit maximaler Häufigkeit
    let modeWeights = weightCounts.filter { $0.value == maxCount }.map { $0.key }

    // Bei Gleichstand: niedrigstes Gewicht nehmen (konservativ)
    return modeWeights.min()
}
```

**Integration:** In `calculate(input:)` wird statt „höchstem Gewicht der letzten Session" das `modeWeight` genutzt.

**RIR-Bewertung ebenfalls angepasst:** Der letzte Satz, der mit dem Modus-Gewicht trainiert wurde, ist der maßgebliche für die RIR-Auswertung. Falls der allerletzte Satz ein abweichendes Gewicht hat (z.B. Steigerung oder Reduktion), wird dessen RIR ignoriert für die Baseline-Entscheidung.

### 4.2 `isLastSetOfExercise`-Reaktivität

**Neue Logik in ActiveWorkoutViewModel (oder Equivalent):**

Ein zentraler Helper wird bei jeder Änderung der Set-Liste einer Übung aufgerufen:

```swift
func updateLastSetFlags(forExerciseGroup groupKey: String, in session: StrengthSession) {
    let setsForGroup = session.safeExerciseSets
        .filter { $0.groupKey == groupKey && $0.setKind == .work }
        .sorted { $0.setNumber < $1.setNumber }

    // Alle vorherigen Flags zurücksetzen
    setsForGroup.forEach { $0.isLastSetOfExercise = false }

    // Letzten Satz markieren
    setsForGroup.last?.isLastSetOfExercise = true
}
```

**Trigger-Events:**
- Satz hinzugefügt
- Satz gelöscht
- Satzanzahl über UI reduziert/erhöht
- Satz-Reihenfolge geändert

**Fallback „RIR nachtragen":**
- Im Satz-Kontextmenü (3-Punkt-Menü auf einem Satz) neue Option „RIR nachtragen"
- Verfügbar für jeden Satz, der `isLastSetOfExercise = true` und `rpeRecorded = false` hat
- Öffnet RIR-Sheet ohne RestTimer

### 4.3 RIR-Skip-Logik

Im `RIRInputSheet`:

```swift
// Bei Tap auf Button:
set.rpe = 10 - selectedRIR    // (bei 4+ → rpe = 6)
set.rpeRecorded = true
sheet.dismiss()

// Bei Tap auf "Überspringen":
// rpe bleibt unverändert, rpeRecorded bleibt false
sheet.dismiss()
```

**Engine-Anpassung:**

```swift
// Vorher:
let lastSetRIR = 10 - lastSet.rpe

// Nachher:
guard lastSet.rpeRecorded else {
    // Engine arbeitet konservativ: kein bigIncrease, nur holdWeight bei Ziel-Reps-Erreichen
    return handleWithoutRIRSignal(...)
}
let lastSetRIR = 10 - lastSet.rpe
```

### 4.4 Auto-Progression des `workingWeight`

**Neue CalcEngine: `AutoProgressionCalcEngine`**

```swift
struct AutoProgressionCalcEngine {
    struct Input {
        let progressionState: ExerciseProgressionState
        let recentSessions: [[ExerciseSet]]     // Neueste zuerst, min. 2 Sessions
        let studioEquipment: StudioEquipment?
        let exerciseFallbackStep: Double
    }

    struct Output {
        let shouldAutoProgress: Bool
        let newWorkingWeight: Double?
        let previousWorkingWeight: Double
        let reasoning: AutoProgressionReason
    }

    enum AutoProgressionReason {
        case consistentReadiness       // 2+ Sessions mit RIR 0-2 + Ziel-Reps erreicht
        case bigIncreaseSignal         // Letzte Session RIR 3+ + deutlich über Ziel-Reps
        case notEnoughData             // Zu wenig Sessions oder kein RIR
        case recentlyProgressed        // Kürzlich bereits erhöht (Cooldown)
        case rollbackContext           // Nach Rollback-Situation vorsichtiger sein
    }

    static func evaluate(input: Input) -> Output { ... }
}
```

**Trigger-Kriterien für `shouldAutoProgress = true`:**

1. Mindestens 2 Sessions mit dieser Übung vorhanden
2. In beiden Sessions: Modus-Gewicht = aktuelles `workingWeight`
3. In beiden Sessions: alle Sätze mit Modus-Gewicht erreichten `targetReps` oder mehr
4. In beiden Sessions: letzter Satz mit Modus-Gewicht `rpeRecorded = true` und RIR ≤ 2
5. `lastAutoProgressionDate` ist mindestens 7 Tage her (Cooldown gegen zu schnelle Erhöhungen)
6. `lastRollbackDate` ist mehr als 14 Tage her (nach Rollback vorsichtiger)

**Auslösungs-Zeitpunkt:** Nach Session-Abschluss, als Teil des bestehenden `WorkoutCompletionFlow`.

**Speicherung der Auto-Progression:**

```swift
progressionState.previousWorkingWeight = progressionState.workingWeight
progressionState.workingWeight = output.newWorkingWeight
progressionState.lastAutoProgressionDate = Date()
progressionState.lastAutoProgressionAmount = output.newWorkingWeight - output.previousWorkingWeight
progressionState.autoProgressionUndoable = true
progressionState.lastProgressionDate = Date()
```

**UI-Feedback:**

Neue Insight-Karte auf `SummaryView` nach Session-Abschluss, falls eine oder mehrere Auto-Progressionen stattfanden:

```
┌──────────────────────────────────────────┐
│  ⚡ Arbeitsgewichte erhöht                │
│                                           │
│  • Kabelzug Trizeps-Pushdown: 35 → 37.5kg │
│  • Kurzhantel-Bankdrücken: 22 → 24kg      │
│  • Kurzhantel Schrägbank Hammer Curl:     │
│    24 → 26kg                              │
│                                           │
│  [Details anzeigen]  [Rückgängig]         │
└──────────────────────────────────────────┘
```

**Undo-Verhalten:**

- Setzt `workingWeight` zurück auf `previousWorkingWeight`
- Setzt `autoProgressionUndoable = false` für alle betroffenen States
- `consecutiveSuccessCount` wird auf 0 zurückgesetzt (damit Auto-Progression nicht sofort wieder triggert)
- Undo-Option verschwindet nach Beginn der nächsten Session

**Details-Button:**

Öffnet eine Detail-View mit pro-Übung:
- Altes und neues Gewicht
- Begründung („2 Sessions in Folge RIR 1, alle Ziel-Reps erreicht")
- Einzeln-Undo-Option pro Übung

---

## 5. Abgrenzung zu `PlanUpdateCalcEngine`

Die `PlanUpdateCalcEngine` bleibt bestehen und unverändert. Sie arbeitet auf anderer Ebene:

| Aspekt | Auto-Progression (neu) | PlanUpdateCalcEngine (bestehend) |
|---|---|---|
| Ebene | `workingWeight` in `ExerciseProgressionState` | Plan-Template im `TrainingPlan` |
| Trigger-Schwelle | 2 Sessions | 5+ Sessions mit stabilem Trend |
| Autonomie | Automatisch, retrospektive Info | User-Bestätigung erforderlich |
| Wirkung | Placeholder im Training | Plan-Template-Vorgabe |

**Zusammenspiel:** Wenn Auto-Progression das `workingWeight` über längere Zeit stabil über dem Plan-Template-Wert hält, triggert PlanUpdateCalcEngine irgendwann den Vorschlag, das Plan-Template selbst zu aktualisieren. Das ist dann die Gelegenheit, das „offizielle" Plan-Gewicht anzupassen.

---

## 6. UI-Änderungen

### 6.1 RIR-Sheet

Keine strukturellen Änderungen, aber:
- Überspringen-Link wird klarer formuliert: „Ohne RIR fortfahren"
- Interne Logik setzt `rpeRecorded` korrekt

### 6.2 Satz-Kontextmenü (3-Punkt-Menü am Satz)

Neue Option **„RIR nachtragen"**, sichtbar wenn:
- `isLastSetOfExercise = true`
- `rpeRecorded = false`

Öffnet ein reduziertes RIR-Sheet (ohne RestTimer-Integration).

### 6.3 Summary-Insight-Karte „Arbeitsgewichte erhöht"

Neue Karte in `SummaryView`, erscheint nach Sessions mit Auto-Progression. Verschwindet bei Start der nächsten Session oder bei Undo.

### 6.4 Auto-Progression-Details-View

Eigene Sheet/View mit Liste aller automatischen Erhöhungen der letzten Session, pro Übung:
- Übungsname
- Altes → Neues Gewicht
- Begründung
- Einzeln-Undo-Button

---

## 7. Supabase-Schema-Erweiterung

Neue Spalten auf `exercise_sets`:
- `rpe_recorded BOOLEAN DEFAULT FALSE`

Neue Spalten auf `exercise_progression_states`:
- `last_auto_progression_date TIMESTAMPTZ`
- `last_auto_progression_amount DOUBLE PRECISION`
- `auto_progression_undoable BOOLEAN DEFAULT FALSE`

Migration ist additiv, keine Löschungen.

---

## 8. Definition of Done

- [ ] `rpeRecorded` korrekt gesetzt bei RIR-Eingabe und Skip
- [ ] Engine respektiert `rpeRecorded = false` (konservatives Verhalten)
- [ ] `isLastSetOfExercise` wird bei Satzanzahl-Änderung reaktiv neu gesetzt
- [ ] „RIR nachtragen" im Satz-Kontextmenü funktioniert
- [ ] Engine nutzt Modus-Gewicht statt Höchstgewicht
- [ ] Auto-Progression triggert nach 2 sauberen Sessions
- [ ] Insight-Karte erscheint auf Summary nach Auto-Progression
- [ ] Undo funktioniert und setzt State korrekt zurück
- [ ] Supabase-Schema erweitert, Backup-Service überträgt neue Felder
- [ ] Bestehende Sessions und Insights funktionieren unverändert

---

## 9. Risiken

| Risiko | Mitigation |
|---|---|
| Auto-Progression erhöht zu aggressiv | 7-Tage-Cooldown + 14-Tage-Rollback-Abstand |
| User erwartet Bestätigungs-Prompt | Erste Auto-Progression: einmaliger Toast „So funktioniert Auto-Progression" |
| Undo-Logik und neue Sessions kollidieren | `autoProgressionUndoable` wird bei Session-Start auf `false` gesetzt |
| Modus-Gewicht bei sehr ungleichmäßigen Sessions (alle unterschiedlich) | Fallback auf Median, wenn kein eindeutiger Modus |
| Reaktive Flag-Evaluation triggert UI-Flackern | `updateLastSetFlags` wird batch-artig aufgerufen, nicht pro Set-Änderung |

---

## 10. Abhängigkeiten

- Benötigt: Phase 1 vollständig abgeschlossen ✓
- Blockiert: Phase 2 (Readiness) — saubere Engine-Logik ist Voraussetzung für Readiness-Integration

---

**Ende Concept Phase 1.5 v1.0**
