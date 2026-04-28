# Konzept: Erweiterte Planverwaltung

**Feature:** Plan duplizieren + Plan aus Session aktualisieren (direkt & smart)
**Status:** Konzept — bereit für Claude Code Implementation
**Datum:** 27.04.2026
**Autor:** Barto + Claude

---

## 1. Problemstellung

Aktuell ist es umständlich, Trainingspläne nach einem Workout anzupassen. Wenn eine Übung spontan getauscht oder ergänzt wird, muss der Plan manuell bearbeitet werden. Es fehlen zwei Kernfunktionen:

1. **Plan aus Session aktualisieren** — Änderungen aus einem konkreten Workout direkt in den Plan übernehmen
2. **Plan duplizieren** — schnelle Kopie eines bestehenden Plans

Beide Funktionen müssen mit dem bestehenden Progression-Tracking (`ExerciseProgressionState`, `AutoProgressionApplier`) kompatibel sein.

---

## 2. Design-Entscheidungen

| Frage | Entscheidung |
|---|---|
| Quelle für Plan-Änderungen | **A+B:** Direkte User-Aktion (einzelne Session) + bestehende Smart-Trend-Logik (≥2/3) |
| Wo lebt Option A (direkte Aktion)? | **StrengthDetailView** (Session-History) |
| Option B (Smart-Trend) | Bestehender `PlanUpdateCalcEngine` + Banner — **unverändert** |
| Plan duplizieren: Progression | **Geteilt** — ein `ExerciseProgressionState` pro `exerciseGroupKey`, unabhängig vom Plan |
| Neue Übungen: Progression | Neuer `ExerciseProgressionState` wird angelegt mit Session-Gewicht als `workingWeight` |
| Entfernte Übungen: Progression | `ExerciseProgressionState` bleibt erhalten (inaktiv), wird nicht gelöscht |

---

## 3. Feature A: Plan aus Session aktualisieren (direkte Aktion)

### 3.1 User Flow

Der User öffnet eine abgeschlossene `StrengthSession` in der `StrengthDetailView`. Die Session hat einen `sourceTrainingPlan`. In der **actionsSection** gibt es einen neuen Button:

**"Plan aus dieser Session aktualisieren"**

Tipp: Öffnet ein `SessionPlanSyncSheet` das die Session mit dem Plan vergleicht und die Unterschiede auflistet:

```
┌─────────────────────────────────────────────┐
│  Plan aus Session aktualisieren             │
│  Push Day A ← Session vom 27.04.2026        │
├─────────────────────────────────────────────┤
│                                             │
│  ✅ Neue Übungen                            │
│  ┌─────────────────────────────────────┐    │
│  │ ☑ Butterfly (3×12, 45kg)           │    │
│  │ ☑ Seitheben (3×15, 8kg)            │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  🔄 Geänderte Übungen                      │
│  ┌─────────────────────────────────────┐    │
│  │ ☑ Bankdrücken: 80→85 kg            │    │
│  │ ☑ Schrägbank KH: 3→4 Sätze         │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ❌ Im Plan, aber nicht trainiert           │
│  ┌─────────────────────────────────────┐    │
│  │ ☐ Kabelzug Flys entfernen          │    │
│  │ ☐ Dips entfernen                    │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  [Ausgewählte übernehmen]                   │
└─────────────────────────────────────────────┘
```

**Wichtige UX-Details:**
- Neue Übungen und Gewichts-/Satzänderungen sind **vorselektiert** (☑)
- Entfernungen (Übung aus Plan löschen) sind **nicht vorselektiert** (☐) — bewusste Entscheidung erforderlich
- Jede Änderung ist einzeln an-/abwählbar
- Button nur sichtbar wenn `session.sourceTrainingPlan != nil` und `session.isCompleted`

### 3.2 Vergleichslogik — `SessionPlanSyncCalcEngine`

Neue CalcEngine (pure struct), die eine einzelne Session mit ihrem Source-Plan vergleicht.

**Input:**
```swift
struct SessionPlanSyncCalcEngine {
    struct Input {
        let session: StrengthSession
        let plan: TrainingPlan
    }
}
```

**Vergleichsalgorithmus:**
1. Session-Übungen nach `groupKey` gruppieren (nur abgeschlossene Work-Sets)
2. Plan-Übungen nach `groupKey` gruppieren (nur Work-Sets)
3. Für jede Übung drei Kategorien ermitteln:

| Kategorie | Bedingung | Change-Type |
|---|---|---|
| **Neue Übung** | `groupKey` in Session, aber nicht im Plan | `.exerciseAdded(sets:)` |
| **Gewichtsänderung** | Modus-Gewicht der Session ≠ Plan-Gewicht | `.weightUpdate(from:to:)` |
| **Satzanzahl-Änderung** | Anzahl Work-Sets in Session ≠ im Plan | `.setCountUpdate(from:to:)` |
| **Nicht trainiert** | `groupKey` im Plan, aber nicht in Session | `.exerciseRemoved` (NEU) |

**Wichtig:** Der Vergleich nutzt die **bestehenden** `PlanUpdateChangeType`-Enums wo möglich. Nur `.exerciseRemoved` ist neu (ersetzt semantisch `.exerciseSkipped` für den Einzelsession-Kontext).

**Output:** `PlanUpdateProposal` — identisch zum bestehenden Format, damit `PlanUpdateApplicator` wiederverwendet werden kann.

### 3.3 Erweiterung PlanUpdateTypes.swift

```swift
enum PlanUpdateChangeType {
    case weightUpdate(from: Double, to: Double)
    case setCountUpdate(from: Int, to: Int)
    case exerciseAdded(sets: [ExerciseSetSnapshot])
    case exerciseSkipped(timesSkipped: Int, outOf: Int)  // bestehend (Option B)
    case exerciseRemoved                                  // NEU (Option A)
}
```

### 3.4 Erweiterung PlanUpdateApplicator.swift

Neuer Case im `apply`-Switch:

```swift
case .exerciseRemoved:
    // Alle Template-Sets dieser Übung aus dem Plan entfernen
    let toRemove = plan.safeTemplateSets.filter {
        $0.groupKey == change.exerciseGroupKey
    }
    for set in toRemove {
        context.delete(set)
    }
    // sortOrder lückenlos neu vergeben
    plan.reindexSortOrders() // ← Private Methode muss public werden
```

### 3.5 Progression-Kompatibilität

| Szenario | Verhalten |
|---|---|
| **Gewicht geändert** | `PlanUpdateApplicator` ändert nur Plan-Template-Gewicht. `ExerciseProgressionState.workingWeight` bleibt unverändert — wird weiterhin nur durch `AutoProgressionApplier` oder manuelle Progression geändert. |
| **Neue Übung hinzugefügt** | Nach `apply()`: prüfen ob `ExerciseProgressionState` für den `groupKey` existiert. Falls nein → neuen anlegen mit `workingWeight` = Modus-Gewicht aus Session. |
| **Übung entfernt** | `ExerciseProgressionState` wird **nicht gelöscht**. Bleibt bestehen für den Fall, dass die Übung später wieder hinzugefügt wird (History-Erhaltung). |
| **Satzanzahl geändert** | Kein Einfluss auf Progression — `ExerciseProgressionState` trackt Gewicht, nicht Satzanzahl. |

**Neuer Service: `ProgressionStateEnsurer`**

```swift
/// Stellt sicher, dass für jede Übung im Plan ein ExerciseProgressionState existiert.
/// Legt fehlende States an (z.B. nach Hinzufügen einer neuen Übung).
struct ProgressionStateEnsurer {
    static func ensureStates(
        forPlan plan: TrainingPlan,
        sessionSets: [ExerciseSet]?,  // Optional: Gewichte aus Session übernehmen
        context: ModelContext
    )
}
```

Wird aufgerufen nach jedem `PlanUpdateApplicator.apply()` — sowohl für Option A als auch Option B.

### 3.6 Anwendung beim externen TrainingPlan-Import

`ProgressionStateEnsurer` schließt zusätzlich eine bestehende Lücke beim externen Plan-Import von `motioncore.barto.cloud`:

**Aktueller Stand (vor diesem Konzept):**
- `PlanImportManager.acceptImport()` legt einen `TrainingPlan` mit Template-Sets an, **erzeugt aber keinen `ExerciseProgressionState`**.
- Importierte Pläne starten dadurch mit `workingWeight = 0` → `AutoProgressionApplier` greift erst nach manueller Initialisierung.

**Neue Regel:**
Am Ende von `PlanImportManager.acceptImport()` (bzw. direkt nach `PlanImportApplyService.apply(...)`) wird ebenfalls `ProgressionStateEnsurer.ensureStates(forPlan:sessionSets:context:)` aufgerufen — mit `sessionSets = nil`, weil noch keine Session vorliegt. Der Ensurer legt für jede Übung einen `ExerciseProgressionState` an und initialisiert `workingWeight` aus dem Template-Gewicht des ersten Work-Sets.

**Wichtig:** Diese Erweiterung gehört semantisch zu diesem Feature, weil `ProgressionStateEnsurer` ohnehin neu eingeführt wird. Sie wird in Schritt 4 des Implementierungsplans (Sektion 10) mit erledigt.

---

## 4. Feature B: Plan duplizieren

### 4.1 User Flow

In der `TrainingDetailView` (Plan-Ansicht) gibt es einen neuen Button in der `PlanActionsSection`:

**"Plan duplizieren"**

Tipp: Erstellt sofort eine Kopie mit dem Namen `"{Original-Name} (Kopie)"`. Kein Sheet, kein Dialog — direktes Feedback via kurzer Bestätigung.

### 4.2 Implementierung — `TrainingPlan.duplicate(context:)`

Extension auf `TrainingPlan`:

```swift
extension TrainingPlan {
    /// Erstellt eine vollständige Kopie dieses Plans inkl. aller Template-Sets.
    /// Der neue Plan bekommt eine eigene planUUID und ist sofort aktiv.
    /// ExerciseProgressionStates werden NICHT kopiert — sie sind über
    /// exerciseGroupKey geteilt und gelten plan-übergreifend.
    func duplicate(context: ModelContext) -> TrainingPlan {
        let copy = TrainingPlan(
            title: "\(title) (Kopie)",
            planDescription: planDescription,
            startDate: Date(),            // Frisches Startdatum
            endDate: nil,                 // Kein Enddatum
            planType: planType,
            isActive: true
        )
        context.insert(copy)

        // Template-Sets klonen (sortiert, damit Reihenfolge stimmt)
        for templateSet in safeTemplateSets.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let clonedSet = templateSet.cloneForPlanEditing()
            copy.addTemplateSet(clonedSet)
            context.insert(clonedSet)
        }

        try? context.save()
        return copy
    }
}
```

### 4.3 Progression-Kompatibilität

**Kein Handlungsbedarf.** Da `ExerciseProgressionState` über `exerciseGroupKey` identifiziert wird (nicht über Plan-ID), teilen sich Original und Kopie automatisch denselben Progressions-State. Wenn `workingWeight` in einer der beiden Pläne steigt, gilt das für beide — was gewollt ist, weil es dieselbe Übung am selben Gerät ist.

### 4.4 Duplikat eines extern importierten Plans

Ein Plan, der ursprünglich über `motioncore.barto.cloud` importiert wurde, ist im SwiftData-Modell ein ganz normaler `TrainingPlan` ohne Quellen-Markierung. Beim Duplizieren gilt:

| Aspekt | Verhalten |
|---|---|
| `planUUID` | Neue UUID — Original und Kopie sind komplett unabhängige Records. |
| `motioncore.barto.cloud`-Polling | Der Polling-Mechanismus (`pending_plan_imports`) erzeugt neue Pläne, **berührt** Original und Kopie nicht erneut. Kein Konflikt. |
| `ExerciseProgressionState` | Geteilt über `exerciseGroupKey` — falls der Ensurer für den Original-Import bereits gelaufen ist (Sektion 3.6), nutzt die Kopie denselben State. |
| Voll-Backup-Sync | Greift beim nächsten Sync für die Kopie automatisch (eigene `planUUID`). |

**Kein Sonderfall** — das Duplikat verhält sich wie jede andere Plan-Kopie. Es gibt aktuell keine Verbindung zurück zur externen Quelle, und das ist gewollt: das Duplikat ist eine lokale Variante.

---

## 5. Zusammenspiel A + B (kein Konflikt)

```
Session beendet
    │
    ├──▶ Option A (User-gesteuert, sofort)
    │    User öffnet StrengthDetailView
    │    → "Plan aus Session aktualisieren"
    │    → SessionPlanSyncCalcEngine vergleicht 1:1
    │    → SessionPlanSyncSheet zeigt Diff
    │    → PlanUpdateApplicator.apply()
    │    → ProgressionStateEnsurer.ensureStates()
    │
    └──▶ Option B (Automatisch, nach ≥3 Sessions)
         PlanUpdateCalcEngine analysiert Trend über letzte 3 Sessions
         → PlanUpdateBanner erscheint in TrainingDetailView
         → PlanUpdateSheet (bestehendes UI)
         → PlanUpdateApplicator.apply()
         → ProgressionStateEnsurer.ensureStates()
```

Beide Pfade enden beim selben `PlanUpdateApplicator` und `ProgressionStateEnsurer`. Kein doppelter Code, kein Konflikt.

**Edge Case:** User nutzt Option A nach Session 1, dann kommt Option B nach Session 3 — aber die Änderung wurde schon übernommen. Der `PlanUpdateCalcEngine` erkennt keinen Unterschied mehr zwischen Plan und Sessions → kein Banner, kein Vorschlag. Korrekt.

---

## 6. Entschiedene Design-Fragen

| Frage | Entscheidung |
|---|---|
| SessionPlanSyncSheet Styling | **Eigenes Sheet** — Kontext zu unterschiedlich vom bestehenden PlanUpdateSheet |
| Undo für Option A | **Ja** — Snapshot-basiert mit 72h Ablauf (siehe Sektion 8) |
| Supabase-Sync bei Duplikat | **Voll-Backup-Sync** — neue `planUUID` → Voll-Backup-Sync greift beim nächsten Sync (siehe 6.1) |
| Option B Enhancement | **Ja, mit aufnehmen** — umgekehrte Trend-Erkennung (siehe Sektion 9) |
| Plan-Update spielt zurück nach motioncore.barto.cloud? | **Nein** — Option A/B ändern nur lokal. Der externe Import ist ein One-Way-Pfad (siehe 6.1) |

### 6.1 Zwei getrennte Supabase-Sync-Pfade

MotionCore hat zwei getrennte Supabase-Pfade, die nicht verwechselt werden dürfen:

| Pfad | Zweck | Richtung | Tabellen |
|---|---|---|---|
| **Externer Plan-Import** | Pläne von `motioncore.barto.cloud` ins App ziehen | One-Way: Cloud → App (Status-Update zurück: `accepted`) | `pending_plan_imports` |
| **Voll-Backup-Sync** | Lokale SwiftData-Records sichern/wiederherstellen | Two-Way: App ↔ Supabase | `training_plans`, `exercise_sets`, ... |

**Konsequenzen für dieses Feature:**

- **Plan duplizieren:** Die Kopie wird über den **Voll-Backup-Sync** synchronisiert (eigene `planUUID`). Sie taucht **nicht** als neuer Eintrag in `pending_plan_imports` auf — der externe Cloud-Editor weiß nichts von der Kopie.
- **Option A — Plan aus Session aktualisieren:** Änderungen am Plan landen über den **Voll-Backup-Sync** in Supabase. Der externe Plan in `motioncore.barto.cloud` (falls er der Ursprung war) bleibt unverändert. Plan und externe Quelle dürfen auseinanderdriften — das ist der intendierte Lebenszyklus: extern erstellen, lokal weiterentwickeln.
- **Option B — Smart-Trend:** Identisches Verhalten wie Option A.
- **Undo (Sektion 7):** Snapshot lebt nur lokal auf dem `TrainingPlan`-Record. Voll-Backup synchronisiert die drei neuen Felder mit. Externer Pfad ist nicht beteiligt.

---

## 7. Undo-Mechanismus für Option A

### 8.1 Problemstellung

Wenn der User per Option A Änderungen am Plan übernimmt und danach feststellt, dass die Änderung doch nicht gewollt war, braucht er einen Weg zurück — ohne den Plan manuell rückbauen zu müssen.

### 8.2 Design: Snapshot-basiertes Undo

Vor jeder Anwendung von `PlanUpdateApplicator.apply()` aus dem `SessionPlanSyncSheet` wird ein **Snapshot** des aktuellen Plan-Zustands** gespeichert.

**Neues Feld auf `TrainingPlan`:**

```swift
// Serialisierter Snapshot der Template-Sets vor dem letzten Session-Sync
var lastSyncSnapshotJSON: String? = nil

// Zeitpunkt des letzten Session-Syncs (für Undo-Banner-Ablauf)
var lastSessionSyncDate: Date? = nil

// UUID-String der Session, die den letzten Sync ausgelöst hat
var lastSessionSyncSourceUUID: String? = nil
```

**Snapshot-Format:** Array von `ExerciseSetSnapshot` (schon definiert in `PlanUpdateTypes.swift`), serialisiert als JSON-String. Leichtgewichtig, CloudKit-kompatibel (einfacher String).

### 8.3 Undo-Flow

```
User übernimmt Änderungen aus Session
    │
    ├── 1. Snapshot aller aktuellen Template-Sets → JSON → plan.lastSyncSnapshotJSON
    ├── 2. PlanUpdateApplicator.apply() führt Änderungen durch
    ├── 3. plan.lastSessionSyncDate = Date()
    │
    └── Nächster Besuch der TrainingDetailView:
         │
         ├── Banner: "Plan wurde aus Session vom 27.04. aktualisiert — Rückgängig?"
         │   Sichtbar für 72 Stunden nach lastSessionSyncDate
         │
         └── Tipp auf "Rückgängig":
              ├── Alle aktuellen Template-Sets löschen
              ├── Sets aus lastSyncSnapshotJSON wiederherstellen
              ├── lastSyncSnapshotJSON = nil
              └── lastSessionSyncDate = nil
```

### 8.4 Implementierung — `SessionSyncUndoService`

```swift
struct SessionSyncUndoService {
    /// Erstellt einen Snapshot des aktuellen Plan-Zustands vor dem Sync.
    static func captureSnapshot(for plan: TrainingPlan) { ... }

    /// Stellt den Plan auf den gespeicherten Snapshot zurück.
    static func undo(plan: TrainingPlan, context: ModelContext) { ... }

    /// Prüft ob ein Undo verfügbar und noch nicht abgelaufen ist (72h).
    static func isUndoAvailable(for plan: TrainingPlan) -> Bool { ... }
}
```

### 8.5 Undo-Banner in TrainingDetailView

Kleiner, dezenter Banner unter dem bestehenden PlanUpdate-Banner-Slot:

```
┌──────────────────────────────────────────────┐
│ ↩️  Plan am 27.04. aus Session aktualisiert  │
│     [Rückgängig]              [Verwerfen]    │
└──────────────────────────────────────────────┘
```

- Sichtbar nur wenn `plan.lastSessionSyncDate` < 72 Stunden alt
- "Rückgängig" → `SessionSyncUndoService.undo()`
- "Verwerfen" → setzt `lastSyncSnapshotJSON = nil` (Undo-Option entfernen)
- Nach 72h oder nach dem nächsten erfolgreichen Workout mit dem Plan: automatisch verwerfen

### 8.6 Progression bei Undo

| Szenario | Verhalten |
|---|---|
| Übung wurde hinzugefügt, jetzt Undo | Template-Sets werden entfernt. `ExerciseProgressionState` bleibt bestehen (kein Löschen). |
| Übung wurde entfernt, jetzt Undo | Template-Sets werden aus Snapshot wiederhergestellt. `ExerciseProgressionState` existiert noch (wurde nie gelöscht). |
| Gewicht/Sätze geändert, jetzt Undo | Template-Sets kehren auf alte Werte zurück. `ExerciseProgressionState.workingWeight` bleibt unverändert (war nie geändert worden). |

---

## 8. Option B Enhancement: Umgekehrte Trend-Erkennung

### 9.1 Idee

Der bestehende `PlanUpdateCalcEngine` erkennt bereits, wenn eine Übung in ≥2/3 Sessions übersprungen wurde (`.exerciseSkipped`). Die Erweiterung geht in die andere Richtung:

**Erkennen, wenn eine NICHT im Plan stehende Übung wiederholt trainiert wird.**

### 9.2 Logik-Erweiterung in `PlanUpdateCalcEngine`

Der bestehende `detectNewExercises()` macht das bereits — er findet Übungen, die in Sessions vorkommen aber nicht im Plan. Die aktuelle Schwelle ist implizit (mindestens 1 Session). 

**Änderung:** Die Schwelle wird explizit auf die ≥2/3-Regel angepasst:

```swift
// Bestehend: Übung in mindestens 1 Session → .exerciseAdded
// Neu: Übung muss in ≥2 von 3 analysierten Sessions vorkommen → .exerciseAdded

// Zusätzlicher Hinweis-Text im PlanUpdateChange:
// "Seitheben war in 3 von 3 Sessions dabei — in den Plan aufnehmen?"
```

### 9.3 Zusätzliche umgekehrte Logik

Wenn der User per Option A eine Übung in den Plan aufgenommen hat, sie aber in den nächsten 3 Sessions nie trainiert:

```
PlanUpdateCalcEngine erkennt:
  - "Seitheben" ist im Plan (per Option A hinzugefügt am 27.04.)
  - In den letzten 3 Sessions nach dem 27.04. nie trainiert
  → Vorschlag: .exerciseSkipped(timesSkipped: 3, outOf: 3)
  → Banner-Text: "Seitheben seit 3 Sessions nicht trainiert — entfernen?"
```

Das ist kein neuer Code — der bestehende `.exerciseSkipped`-Mechanismus greift hier automatisch. Die einzige Änderung ist, dass die Schwelle und der Anzeige-Text diese Situation klar kommunizieren.

### 9.4 Betroffene Dateien

| Datei | Änderung |
|---|---|
| `PlanUpdateCalcEngine.swift` | `detectNewExercises()` — Schwelle auf ≥2/3 anpassen |
| `PlanUpdateSheet.swift` | Optionaler Hinweis-Text bei `.exerciseAdded` ("War in X von Y Sessions dabei") |

---

## 9. Datei-Übersicht

### Neue Dateien

| Datei | Typ | Beschreibung |
|---|---|---|
| `SessionPlanSyncCalcEngine.swift` | CalcEngine | Vergleicht einzelne Session mit Plan |
| `SessionPlanSyncSheet.swift` | View | Sheet mit Diff-Ansicht und Checkboxen |
| `ProgressionStateEnsurer.swift` | Service | Stellt ExerciseProgressionState-Existenz sicher |
| `SessionSyncUndoService.swift` | Service | Snapshot-basiertes Undo für Option A |
| `SessionSyncUndoBanner.swift` | View | Undo-Banner in TrainingDetailView |

### Geänderte Dateien

| Datei | Änderung |
|---|---|
| `PlanUpdateTypes.swift` | Neuer Case `.exerciseRemoved` |
| `PlanUpdateApplicator.swift` | Handler für `.exerciseRemoved` |
| `TrainingPlan.swift` | `duplicate(context:)`, `reindexSortOrders()` internal, 3 neue Felder (Undo-Snapshot) |
| `StrengthDetailView.swift` | Button "Plan aus Session aktualisieren" + Sheet-State |
| `PlanActionsSection.swift` | Button "Plan duplizieren" + `onDuplicate` Callback |
| `TrainingDetailView.swift` | Duplikat-Callback, Undo-Banner Integration |
| `PlanUpdateCalcEngine.swift` | `detectNewExercises()` — ≥2/3-Schwelle für neue Übungen |
| `PlanUpdateSheet.swift` | Optionaler Hinweis-Text bei `.exerciseAdded` |
| `PlanImportManager.swift` | Aufruf von `ProgressionStateEnsurer.ensureStates(...)` am Ende von `acceptImport()` (siehe 3.6) |

### Unveränderte Dateien (Kompatibilität bestätigt)

| Datei | Warum unverändert |
|---|---|
| `PlanUpdateBanner.swift` | Weiterhin nur für Option B |
| `AutoProgressionApplier.swift` | Arbeitet weiter über `ExerciseProgressionState` |
| `AutoProgressionCalcEngine.swift` | Keine Änderung |
| `ExerciseProgressionState.swift` | Keine strukturelle Änderung |
| `ExerciseSet.swift` | `cloneForPlanEditing()` wird wiederverwendet |

---

## 10. Implementierungsplan (STOPP-Gates)

### Schritt 1: PlanUpdateTypes erweitern
- `.exerciseRemoved` Case hinzufügen
- **STOPP** — Build prüfen

### Schritt 2: PlanUpdateApplicator erweitern
- Handler für `.exerciseRemoved`
- `TrainingPlan.reindexSortOrders()` von `private` auf `internal` setzen
- **STOPP** — Build prüfen

### Schritt 3: SessionPlanSyncCalcEngine
- Neue Datei `SessionPlanSyncCalcEngine.swift`
- Vergleichslogik: Session vs. Plan → `PlanUpdateProposal`
- **STOPP** — Build prüfen

### Schritt 4: ProgressionStateEnsurer
- Neue Datei `ProgressionStateEnsurer.swift`
- `ensureStates(forPlan:sessionSets:context:)` implementieren
- In `PlanUpdateApplicator.apply()` nach erfolgreicher Anwendung aufrufen
- **Zusätzlich:** in `PlanImportManager.acceptImport()` (am Ende, mit `sessionSets = nil`) aufrufen — schließt die Initialisierungslücke beim externen Plan-Import (siehe 3.6)
- **STOPP** — Build prüfen

### Schritt 5: SessionSyncUndoService + TrainingPlan-Felder
- 3 neue Felder auf `TrainingPlan` (Snapshot-JSON, Sync-Datum, Source-UUID)
- Neue Datei `SessionSyncUndoService.swift` (captureSnapshot, undo, isUndoAvailable)
- **STOPP** — Build prüfen

### Schritt 6: SessionPlanSyncSheet (UI)
- Neue Datei `SessionPlanSyncSheet.swift`
- Diff-Ansicht mit Checkboxen, gruppiert nach Kategorie
- Ruft `SessionSyncUndoService.captureSnapshot()` vor Apply auf
- Nutzt `PlanUpdateApplicator.apply()` + `ProgressionStateEnsurer`
- **STOPP** — Build prüfen

### Schritt 7: StrengthDetailView Integration
- Neuer `@State` für Sheet-Präsentation
- Button "Plan aus Session aktualisieren" in `actionsSection`
- Nur sichtbar wenn `session.sourceTrainingPlan != nil && session.isCompleted`
- **STOPP** — Build prüfen + manueller Test

### Schritt 8: Undo-Banner
- Neue Datei `SessionSyncUndoBanner.swift`
- Integration in `TrainingDetailView` (unter PlanUpdate-Banner-Slot)
- 72h Ablauf-Logik
- **STOPP** — Build prüfen + manueller Test

### Schritt 9: Plan duplizieren
- `TrainingPlan.duplicate(context:)` Extension
- `PlanActionsSection`: neuer "Duplizieren"-Button mit `onDuplicate` Callback
- `TrainingDetailView`: Callback-Handler, optional Navigation zum neuen Plan
- **STOPP** — Build prüfen + manueller Test

### Schritt 10: Option B Enhancement
- `PlanUpdateCalcEngine.detectNewExercises()` — ≥2/3-Schwelle
- `PlanUpdateSheet` — Hinweis-Text bei `.exerciseAdded`
- **STOPP** — Build prüfen

### Schritt 11: Regression-Check
- Bestehende PlanUpdate-Banner (Option B) testen — darf nicht brechen
- AutoProgression nach Session testen — muss weiter funktionieren
- Plan starten → Session beenden → Option A testen → Plan prüfen
- Undo testen: Plan aktualisieren → Undo → Plan zurück auf alten Stand?
- Plan duplizieren → beide Pläne starten → Progression prüfen
- Option B: 3× eine neue Übung trainieren → Vorschlag erscheint?
- **Externer Import:** Plan aus `motioncore.barto.cloud` importieren → für jede importierte Übung muss `ExerciseProgressionState` mit `workingWeight` aus dem Template-Set existieren (siehe 3.6)
- **Externer Import + Duplikat:** importierten Plan duplizieren → Original und Kopie teilen denselben `ExerciseProgressionState` (siehe 4.4)
- **STOPP** — Finaler Review
