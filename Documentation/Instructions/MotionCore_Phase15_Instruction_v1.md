# MotionCore — Phase 1.5 Implementation
## Claude-Code-Instruktionsdokument v1.0

**Bezug:** `MotionCore_Phase15_Concept_v1.md`
**Datum:** 24. April 2026
**Zielagenten:** motioncore-planner (opus) → motioncore-developer (sonnet) → motioncore-quality-gate (sonnet)
**Komplexität:** Medium (5 Schritte, Bugfixes + 1 Feature)

---

## 🛑 GRUNDREGELN

Identisch zu Instruction v1.1. Kurz-Erinnerung:
- Jeder Schritt hat expliziten STOPP-Gate
- Build-Check obligatorisch (iOS + watchOS wenn relevant)
- Bei Unklarheiten: Frage stellen, nicht annehmen
- File-Size-Policy: Ziel 400, Warnung 600, hart bei 800

---

## 📋 PHASENÜBERSICHT

| Schritt | Thema | Abhängig von |
|---|---|---|
| 1.5.1 | `rpeRecorded`-Feld + Schema-Update | — |
| 1.5.2 | RIR-Sheet + Engine-Anpassung | 1.5.1 |
| 1.5.3 | Modus-Gewicht in ProgressionCalcEngine | 1.5.2 |
| 1.5.4 | `isLastSetOfExercise` reaktive Neuevaluation + RIR-nachtragen | 1.5.1 |
| 1.5.5 | AutoProgressionCalcEngine + Insight-Karte + Undo | 1.5.1–1.5.4 |
| 1.5.6 | Supabase-Schema-Erweiterung | 1.5.1, 1.5.5 |

**Empfohlene Reihenfolge:** 1.5.1 → 1.5.2 → 1.5.3 → 1.5.4 → 1.5.5 → 1.5.6

---

## Schritt 1.5.1 — `rpeRecorded`-Feld

**Ziel:** Neues Bool-Feld auf `ExerciseSet`, das zwischen „keine Angabe" und „RIR 10 = easy" disambiguiert.

**Dateien:**
- ÄNDERN: `ExerciseSet.swift`
  - Neu: `var rpeRecorded: Bool = false`
  - `init()`-Parameter optional ergänzen (mit default false)
  - `cloneForSession()` und `cloneForPlanEditing()`: `rpeRecorded` nicht kopieren, immer `false` bei Clones
- ÄNDERN: `MotionCoreApp.swift`
  - SwiftData-Schema-Version erhöhen

**Migration:**
- Lightweight-Migration
- Bestehende Sets: `rpeRecorded = false` (Default)
- Keine Heuristik nötig, da Phase 1 erst kürzlich produktiv ging

**Build-Check:**
- iOS + watchOS build green
- App startet, bestehende Sessions öffnen ohne Crash
- Debugger zeigt `rpeRecorded = false` bei existierenden Sets

**🛑 STOPP 1.5.1**

---

## Schritt 1.5.2 — RIR-Sheet + Engine-Anpassung

**Ziel:** RIR-Sheet setzt `rpeRecorded` korrekt. ProgressionCalcEngine respektiert den neuen Flag.

**Dateien:**
- ÄNDERN: `RIRInputSheet.swift`
  - Bei Tap auf RIR-Button:
    ```swift
    set.rpe = 10 - selectedRIR  // bei "4+" → rpe = 6
    set.rpeRecorded = true
    ```
  - Bei Tap auf „Überspringen" (oder „Ohne RIR fortfahren"):
    ```swift
    // rpe bleibt unverändert
    // rpeRecorded bleibt false
    ```
  - Skip-Link-Text ändern: „Ohne RIR fortfahren" statt „Überspringen"

- ÄNDERN: `ProgressionCalcEngine.swift`
  - Vor RIR-Auswertung prüfen: `guard lastSet.rpeRecorded else { return conservativeFallback }`
  - `conservativeFallback`: kein `bigIncrease`, keine `readinessReduced`, nur `holdWeight` oder `firstSession`
  - Bei fehlendem RIR-Signal: `Output.reasoning = .holdWeight` mit expliziter Begründung
  - Progression nur wenn alle Ziel-Reps erreicht wurden UND RIR-Signal vorhanden ist

**Manuelle Testszenarien (in Test-View oder Preview dokumentieren):**
1. RIR-Sheet, Tap auf „2" → `rpe = 8`, `rpeRecorded = true`
2. RIR-Sheet, Tap auf „4+" → `rpe = 6`, `rpeRecorded = true`
3. RIR-Sheet, Tap auf Überspringen → `rpe` unverändert, `rpeRecorded = false`
4. Engine-Input mit `rpeRecorded = false` + Ziel-Reps erreicht → `holdWeight`
5. Engine-Input mit `rpeRecorded = true, rpe = 9` (RIR 1) + Ziel-Reps → `increaseWeight`
6. Engine-Input mit `rpeRecorded = true, rpe = 6` (RIR 4) + deutlich über Ziel-Reps → `bigIncrease`

**Build-Check:**
- RIR-Sheet nach letztem Satz funktioniert
- Überspringen funktioniert, `rpeRecorded` bleibt false
- Engine liefert bei fehlendem RIR konservative Vorschläge

**Screenshots:** RIR-Sheet (unverändert Layout), Summary mit Vorschlag nach Skip (sollte nicht progressieren).

**🛑 STOPP 1.5.2**

---

## Schritt 1.5.3 — Modus-Gewicht

**Ziel:** ProgressionCalcEngine nutzt Modus-Gewicht als Baseline.

**Dateien:**
- ÄNDERN: `ProgressionCalcEngine.swift`
  - Neue private Helper-Funktion `modeWeight(from sets: [ExerciseSet]) -> Double?`
  - Logik:
    - Zähle Häufigkeit jedes Gewichts
    - Wenn ein Gewicht eindeutig am häufigsten → dieses Gewicht
    - Bei Gleichstand: niedrigstes Gewicht (konservativ)
    - Bei nur 1 Satz: dieses Gewicht
  - Integration in `calculate(input:)`:
    - Baseline = `modeWeight(from: lastSessionSets) ?? lastSessionSets.last?.weight ?? 0`
    - RIR-Auswertung: nutze RIR des **letzten Satzes mit Modus-Gewicht**, nicht zwingend des allerletzten Satzes der Übung
    - Ziel-Reps-Auswertung: nur Sätze mit Modus-Gewicht werden gewertet

**Edge Cases:**
- Alle Sätze unterschiedliches Gewicht (z.B. aufsteigende Pyramide) → nehme niedrigstes als Baseline
- Nur ein Satz insgesamt → dieses Gewicht ist Modus
- Letzter Satz hat abweichendes Gewicht + `rpeRecorded = true` → RIR wird für Modus-Baseline ignoriert, als Info aber gespeichert

**Manuelle Testszenarien:**
1. Sätze: 30kg, 30kg, 30kg → Modus = 30kg
2. Sätze: 30kg, 30kg, 32.5kg (Steigerung letzter Satz) → Modus = 30kg
3. Sätze: 30kg, 32.5kg, 32.5kg (Steigerung ab Satz 2) → Modus = 32.5kg
4. Sätze: 80kg, 80kg, 70kg (Reduktion letzter Satz) → Modus = 80kg
5. Sätze: 20kg, 22.5kg, 25kg (aufsteigende Pyramide) → Modus = 20kg (bei Gleichstand niedrigstes)
6. Sätze: 30kg (nur einer) → Modus = 30kg

**Build-Check:**
- Grün
- Test-View zeigt alle 6 Szenarien korrekt
- Bestehende Placeholder-Vorschläge sind konsistent mit neuer Logik

**🛑 STOPP 1.5.3**

---

## Schritt 1.5.4 — Reaktive Flag-Evaluation + RIR-nachtragen

**Ziel:** `isLastSetOfExercise` wird reaktiv gesetzt bei Satzanzahl-Änderungen. User kann RIR nachträglich eintragen.

**Dateien:**
- NEU: `Services/ExerciseSetFlagUpdater.swift`
  ```swift
  enum ExerciseSetFlagUpdater {
      static func updateLastSetFlags(
          forExerciseGroup groupKey: String,
          in session: StrengthSession
      ) {
          let workSets = session.safeExerciseSets
              .filter { $0.groupKey == groupKey && $0.setKind == .work }
              .sorted { $0.setNumber < $1.setNumber }

          workSets.forEach { $0.isLastSetOfExercise = false }
          workSets.last?.isLastSetOfExercise = true
      }
  }
  ```

- ÄNDERN: `ActiveWorkoutViewModel.swift` (oder wo Sätze manipuliert werden)
  - Nach jeder Set-Liste-Änderung `ExerciseSetFlagUpdater.updateLastSetFlags` aufrufen
  - Trigger-Events:
    - Satz hinzugefügt
    - Satz gelöscht
    - Satzanzahl reduziert (UI-Aktion)
    - Satz-Reihenfolge geändert
  - Nach Neuevaluation prüfen: Wenn neu markierter „letzter Satz" kein `rpeRecorded = true` hat UND User noch bei dieser Übung ist → RIR-Sheet zeigen

- ÄNDERN: Set-Kontextmenü (3-Punkt-Menü)
  - Neue Option „RIR nachtragen"
  - Sichtbar nur wenn `set.isLastSetOfExercise == true && set.rpeRecorded == false`
  - Öffnet `RIRInputSheet` im Retro-Mode (ohne RestTimer-Integration)

- NEU: `RIRRetroSheet.swift` (oder Parameter auf bestehendem Sheet)
  - Variante des RIR-Sheets ohne RestTimer-Section
  - Gleiche Button-Reihe
  - Headertext: „RIR für letzten Satz nachtragen"

**Edge Cases:**
- User löscht letzten Satz: vorletzter wird `isLastSetOfExercise = true`
- User fügt Satz hinzu, nachdem er RIR für alten letzten Satz eingegeben hat: alter Satz bekommt `isLastSetOfExercise = false`, `rpeRecorded` bleibt true, neuer Satz bekommt `isLastSetOfExercise = true, rpeRecorded = false`
- Satz-Reihenfolge ändern: Flags werden korrekt neu gesetzt

**Manuelle Testszenarien:**
1. Start mit 4 geplanten Sätzen, 3 abschließen, Satzanzahl auf 3 reduzieren → Satz 3 wird letzter, RIR-Sheet erscheint
2. Alle 4 Sätze abschließen, dann Satz 4 löschen → Satz 3 wird letzter, hat aber kein `rpeRecorded` → „RIR nachtragen" im Menü sichtbar
3. „RIR nachtragen" tappen → RIR-Sheet öffnet ohne RestTimer, Eingabe funktioniert

**Build-Check:**
- Flag-Reaktivität funktioniert bei allen Trigger-Events
- Kein UI-Flackern
- „RIR nachtragen" nur sichtbar wenn anwendbar
- Retro-Sheet funktioniert

**Screenshots:** Set-Kontextmenü mit „RIR nachtragen"-Option, Retro-Sheet.

**🛑 STOPP 1.5.4**

---

## Schritt 1.5.5 — AutoProgressionCalcEngine + Insight-Karte

**Ziel:** Automatische Erhöhung des `workingWeight` mit retrospektiver Info-Karte und Undo.

**Dateien:**
- ÄNDERN: `ExerciseProgressionState.swift`
  - Neu: `var lastAutoProgressionDate: Date?`
  - Neu: `var lastAutoProgressionAmount: Double?`
  - Neu: `var autoProgressionUndoable: Bool = false`
  - `previousWorkingWeight` existiert schon aus Phase 1, wird hier weitergenutzt

- NEU: `CalcEngines/AutoProgressionCalcEngine.swift`
  - Pure Struct, keine Side Effects
  - API gemäß Concept 4.4
  - Kriterien für Auto-Progression:
    1. Mindestens 2 Sessions vorhanden
    2. Beide Sessions: Modus-Gewicht = aktuelles `workingWeight`
    3. Beide Sessions: alle Sätze mit Modus-Gewicht erreichten `targetReps` oder mehr
    4. Beide Sessions: letzter Satz mit Modus-Gewicht `rpeRecorded = true` und RIR ≤ 2
    5. `lastAutoProgressionDate` mindestens 7 Tage her (oder nil)
    6. `lastRollbackDate` mehr als 14 Tage her (oder nil)
  - Erhöhung:
    - Default: `increment` aus `StudioEquipment` oder `exerciseFallbackStep`
    - `bigIncrease` wenn letzte Session RIR ≥ 3 + deutlich über Ziel-Reps: `+ 2× increment`

- NEU: `Services/AutoProgressionApplier.swift`
  - Führt die Änderungen am `ExerciseProgressionState` aus
  - Transaktional pro Session (alle Übungen gemeinsam evaluieren, gemeinsam persistieren)
  - Methode `func apply(forSession session: StrengthSession)` — wird nach Session-Abschluss aufgerufen
  - Methode `func undo(forSession session: StrengthSession)` — setzt alle auto-progressed States zurück

- ÄNDERN: `WorkoutCompletionFlow` / `ActiveWorkoutViewModel` beim Session-Abschluss
  - Nach `SessionQualityCalcEngine` zusätzlich `AutoProgressionApplier.apply(forSession:)` aufrufen
  - Ergebnisse der Auto-Progression für UI-Karte speichern (temporär auf Session oder in UI-State)

- NEU: `Views/Summary/AutoProgressionInsightCard.swift`
  - Zeigt Liste aller auto-progressed Übungen
  - Format: „Übungsname: alt → neu kg"
  - Zwei Buttons: „Details" + „Rückgängig"
  - Erscheint nur wenn `session.hasAutoProgressions == true`
  - Verschwindet bei Start nächster Session oder nach Undo

- NEU: `Views/Summary/AutoProgressionDetailsView.swift`
  - Pro Übung: alt → neu, Begründung, Einzeln-Undo-Button
  - Close-Button

- ÄNDERN: `SummaryView.swift`
  - Integration der `AutoProgressionInsightCard`
  - Positioniert direkt nach bestehenden Insight-Karten, vor Muskel-Heatmap

**Begründungs-Texte für UI (deutsch):**
- `consistentReadiness`: „2 Sessions mit RIR 0–2 und Ziel-Reps erreicht"
- `bigIncreaseSignal`: „Letzte Session zu leicht, großer Sprung empfohlen"

**Edge Cases:**
- User startet neue Session, bevor Undo getappt wurde: `autoProgressionUndoable` wird auf `false` gesetzt, Karte verschwindet
- Mehrere Undos gleichzeitig: transaktional handhaben
- Auto-Progression bei nur einer verfügbaren Session: nicht triggern (Kriterium 1)

**Manuelle Testszenarien:**
1. 2 Sessions Latzug mit 60kg × 10, RIR 1 → Auto-Progression auf 62.5kg, Karte erscheint
2. Undo tappen → workingWeight zurück auf 60kg, Karte verschwindet
3. 1 gute Session nach einer mittelmäßigen → kein Auto-Progression
4. Auto-Progression vor 5 Tagen, wieder 2 gute Sessions → kein neuer Auto-Progression (Cooldown)
5. Letzte Session RIR 4+, alle Reps deutlich über Ziel → bigIncrease-Variante (+2× Increment)

**Build-Check:**
- Engine liefert plausible Ergebnisse in allen 5 Szenarien
- Karte erscheint korrekt
- Undo funktioniert komplett
- Bei Session-Start: `autoProgressionUndoable = false`, Karte weg

**Screenshots:** Summary mit Auto-Progression-Karte, Details-View, nach Undo.

**🛑 STOPP 1.5.5**

---

## Schritt 1.5.6 — Supabase-Schema

**Ziel:** Datenbank um neue Felder erweitern, Backup funktioniert.

**Dateien:**
- SUPABASE MIGRATION (SQL):
  ```sql
  ALTER TABLE motioncore.exercise_sets
  ADD COLUMN IF NOT EXISTS rpe_recorded BOOLEAN DEFAULT FALSE;

  ALTER TABLE motioncore.exercise_progression_states
  ADD COLUMN IF NOT EXISTS last_auto_progression_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_auto_progression_amount DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS auto_progression_undoable BOOLEAN DEFAULT FALSE;
  ```

- ÄNDERN: `SupabaseFullBackupService.swift`
  - Encode `rpeRecorded` in Set-Upload
  - Encode neue Progression-State-Felder in State-Upload

**Build-Check:**
- Manueller Backup-Trigger → neue Felder erreichen Supabase
- Supabase-SQL-Query zeigt korrekte Werte
- Keine Fehler in Logs

**🛑 STOPP 1.5.6 — Ende Phase 1.5**

---

## 🎯 Phase-1.5-Abschluss

### Definition of Done
- [ ] Alle 6 Schritte abgeschlossen
- [ ] RIR-Skip führt nicht mehr zu aggressiver Progression
- [ ] Modus-Gewicht wird als Baseline genutzt
- [ ] Satzanzahl-Reduktion triggert RIR-Sheet
- [ ] „RIR nachtragen" verfügbar im Satz-Menü
- [ ] Auto-Progression erhöht `workingWeight` nach 2 guten Sessions
- [ ] Insight-Karte erscheint auf Summary
- [ ] Undo funktioniert
- [ ] Supabase-Schema vollständig
- [ ] Bestehende Features (Phase 1) funktionieren unverändert

### User-Test-Phase (mind. 1 Woche)
- Mindestens 3–4 Sessions trainieren
- Auto-Progression im echten Training verifizieren
- Modus-Gewicht-Verhalten bei spontanen Steigerungen prüfen
- RIR-Nachtragen ausprobieren

**🛑 GROSSER STOPP vor Phase 2**

---

**Ende Instruction Phase 1.5 v1.0**
