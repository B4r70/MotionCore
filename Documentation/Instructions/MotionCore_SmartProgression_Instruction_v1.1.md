# MotionCore — Smart Progression Implementation
## Claude-Code-Instruktionsdokument v1.1 (Codebase-validiert)

**Bezug:** `MotionCore_SmartProgression_Concept_v1.1.md`
**Datum:** 18. April 2026
**Zielagenten:** motioncore-planner (opus) → motioncore-developer (sonnet) → motioncore-quality-gate (sonnet)
**Komplexität:** Large (3 Phasen, multiple CalcEngines, Datenmodell-Umbau + Legacy-Entfernung)

---

## 🛑 GRUNDREGELN FÜR ALLE AGENTEN

### Vor jedem Schritt
1. **NIEMALS mehrere Schritte zusammenfassen.** Jeder Schritt hat einen expliziten STOPP-Gate am Ende.
2. **NIEMALS den nächsten Schritt starten**, ohne explizites "Go" von Barto.
3. **Bei Unklarheiten: Frage stellen, nicht annehmen.**

### Nach jedem Schritt
1. **Build-Check obligatorisch:** Xcode-Build muss grün sein (iOS + watchOS wenn Watch betroffen).
2. **Zusammenfassung liefern:** Was wurde geändert, welche Dateien, welche Auswirkungen.
3. **STOPP-Signal:** `🛑 STOPP — Warte auf Freigabe für Schritt X.Y`

### Definition of "Green Build"
- `xcodebuild` für iOS-Target ohne Errors
- `xcodebuild` für watchOS-Target ohne Errors (falls Watch-Files betroffen)
- Keine neuen Warnings in betroffenen Dateien
- App startet im Simulator und öffnet Hauptansichten ohne Crash
- Bestehende Sessions öffnen ohne Crash

### Agent-Workflow pro Schritt
1. **Planner:** Liest Instruction-Schritt, lädt `tasks/current.md`, validiert Scope, schreibt Implementation-Plan
2. **Developer:** Implementiert laut Plan
3. **Quality-Gate:** Prüft Build, Architektur, File-Größen, CalcEngine-Pattern, **Cross-Dependencies** (besonders bei Löschungen)
4. **Handover an Barto:** Build-Report + Screenshots + STOPP

### File-Size-Policy
- Ziel: 400 Zeilen
- Warnung ab 600: Quality-Gate fordert Split
- Hart ab 800: Muss im Schritt gesplittet werden

### Wichtig für v1.1: Sicherheits-Check bei Löschungen
Bevor eine Datei gelöscht wird, muss der Agent zuerst:
1. Globale Suche nach allen Referenzen auf die Datei/Typ
2. Liste aller Usages dokumentieren
3. Erst wenn alle Usages bereinigt sind, darf gelöscht werden
4. Quality-Gate prüft mit eigenständiger Suche auf "dangling references"

---

## 📋 PHASENÜBERSICHT

| Phase | Name | Schritte | Geschätzte Dauer |
|---|---|---|---|
| **1** | Smart Progression | 1.1 – 1.17 | ~3-4 Wochen |
| **2** | Readiness | 2.1 – 2.8 | ~1,5 Wochen |
| **3** | Dynamic Hints & Volumen | 3.1 – 3.6 | ~1 Woche |

**Zwischen Phasen:** Großer STOPP-Gate mit manuellem User-Test über mehrere Tage.

---

# PHASE 1 — Smart Progression

## Schritt 1.1 — Datenmodell: Studio & StudioEquipment

**Ziel:** Zwei neue SwiftData-Modelle anlegen, keine UI.

**Dateien:**
- NEU: `MotionCore/Models/Studio.swift`
- NEU: `MotionCore/Models/StudioEquipment.swift`
- NEU: `MotionCore/Models/StudioEquipmentType.swift` (enum)
- ÄNDERN: `MotionCoreApp.swift` (ModelContainer-Schema erweitern)

**Anforderungen:**
- Swift-Standards einhalten (Datei-Header aus bestehenden Files kopieren, deutsche Kommentare)
- Alle stored Properties optional oder mit Default
- Inverse Relationship Studio ↔ StudioEquipment
- Safe Accessor `safeEquipment`
- **WICHTIG:** Enum heißt `StudioEquipmentType`, NICHT `EquipmentType` — `ExerciseEquipment` existiert bereits!

**Build-Check:**
- App startet ohne Migration-Fehler
- Bestehende Daten intakt

**🛑 STOPP 1.1**

---

## Schritt 1.2 — Datenmodell: ExerciseProgressionState

**Ziel:** Model für Arbeitsgewicht pro Übungsgruppe.

**Dateien:**
- NEU: `MotionCore/Models/ExerciseProgressionState.swift`
- NEU: `MotionCore/Models/ProgressionMode.swift` (enum)
- ÄNDERN: `MotionCoreApp.swift` (Schema)

**Anforderungen:**
- Match-Pattern wie `ExerciseRating` (via `exerciseGroupKey`)
- Alle Properties defaulted
- `previousWorkingWeight` für Rollback-Wiederherstellung

**Build-Check:** wie 1.1

**🛑 STOPP 1.2**

---

## Schritt 1.3 — Exercise-Erweiterung (nur HINZUFÜGEN, noch nicht löschen)

**Ziel:** Neue Felder auf Exercise. Alte Felder bleiben vorerst für Migration-Sicherheit.

**Dateien:**
- ÄNDERN: `MotionCore/Models/Exercise.swift`
  - HINZUFÜGEN:
    - `var studioEquipmentID: UUID? = nil`
    - `var customTargetReps: Int? = nil`
    - `var progressionModeRaw: String = "smart"`
    - `var configNotes: String = ""`
    - Computed `progressionMode` (get/set ProgressionMode)
  - `init()`-Parameter entsprechend ergänzen (mit Defaults)

**Anforderungen:**
- Alte Felder (`progressionStrategyRaw`, `customProgressionStep`, `progressionSessionsRequired`, `minDaysBetweenProgressions`) BLEIBEN noch unverändert
- Code muss weiterhin kompilieren inkl. aller bestehenden Views

**Build-Check:**
- iOS + watchOS grün
- App startet, alte Progression-View (`ProgressionAnalyseView`) funktioniert noch

**🛑 STOPP 1.3**

---

## Schritt 1.4 — ExerciseSet-Erweiterung

**Ziel:** `isLastSetOfExercise`-Flag auf ExerciseSet.

**Dateien:**
- ÄNDERN: `MotionCore/Models/ExerciseSet.swift`
  - HINZUFÜGEN: `var isLastSetOfExercise: Bool = false`
  - `init()`-Parameter ergänzen (optional, default false)
  - `cloneForSession()` und `cloneForPlanEditing()` anpassen (Flag nicht kopieren — immer false bei Templates und neuen Clones)

**Anforderungen:**
- `rpe`-Feld NICHT anfassen (wird weiterhin für RIR genutzt)
- `calculatedRIR` bleibt unverändert

**Build-Check:** Grün, alte Session-Details öffnen ohne Crash.

**🛑 STOPP 1.4**

---

## Schritt 1.5 — Neue Datenmodelle: SessionReadiness & HealthBaseline

**Ziel:** Models für Phase 2 bereits jetzt anlegen (bleiben ungenutzt in Phase 1).

**Dateien:**
- NEU: `MotionCore/Models/SessionReadiness.swift`
- NEU: `MotionCore/Models/HealthBaseline.swift`
- NEU: `MotionCore/Models/HealthMetricType.swift` (enum)
- ÄNDERN: `MotionCoreApp.swift` (Schema)

**Anforderungen:**
- Vollständig gemäß Concept 3.1.4/3.1.5
- In Phase 1 werden die Modelle NICHT befüllt

**Rationale für frühes Anlegen:** Vermeidet erneute SwiftData-Migration in Phase 2.

**🛑 STOPP 1.5**

---

## Schritt 1.6 — StrengthSession-Erweiterung

**Dateien:**
- ÄNDERN: `MotionCore/Models/StrengthSession.swift`
  - HINZUFÜGEN: `var sessionQualityScore: Int? = nil`
  - HINZUFÜGEN: `var sessionReadinessID: UUID? = nil`

**Build-Check:** Session-Listen und -Details funktionieren.

**🛑 STOPP 1.6**

---

## Schritt 1.7 — Cross-Reference-Check vor Legacy-Entfernung

**Ziel:** Sicherheits-Schritt. Keine Code-Änderung, nur Analyse.

**Aufgabe Planner:**
Globale Suche nach allen Referenzen auf:
- `ProgressionCalcEngine` (alte Klasse)
- `ProgressionAnalyseCalcEngine`
- `ProgressionAnalysis`
- `ProgressionRecommendation`
- `ProgressionViewModel`
- `ProgressionAnalyseView`, `ProgressionDetailView`, `ProgressionBannerView`
- `ProgressionOverviewCard`, `ProgressionExerciseCard`, `ProgressionInsightCard`
- `ProgressionSectionHeader`, `ProgressionSummaryCard`
- `TrendPoint` (prüfen ob außerhalb von `ProgressionTypes.swift` verwendet)
- `AnalyseSegment` (enum)
- `SessionSnapshot`
- `TrainingLevel`, `PerformanceTrend`, `ProgressionAction`, `ProgressionConfidence`
- Auf Exercise: `progressionStrategyRaw`, `customProgressionStep`, `progressionSessionsRequired`, `minDaysBetweenProgressions`, `baseProgressionStep`, `effectiveProgressionStep`, `progressionStrategy`, `canRecommendProgression`
- `ExerciseProgressionSection` (UI-Komponente in `FormViewSection.swift`)
- `WorkoutAnalyseView` — prüfen ob es Progression-Referenzen hat

**Output:** Matrix mit allen Fundstellen, gruppiert nach:
- Zu entfernende Files (kein Aufräumen nötig, werden gelöscht)
- Files mit Referenzen, die aufgeräumt werden müssen (v.a. `SetConfigurationSheet`, `WorkoutAnalyseView`, evtl. andere)
- Externe Typen, die bleiben müssen (z.B. wenn `TrendPoint` auch von `StatisticTrendChart` genutzt wird)

**Kein Build-Check nötig, nur Report.**

**🛑 STOPP 1.7** — Barto reviewt Report, entscheidet ggf. Umfang-Anpassungen.

---

## Schritt 1.8 — TrendPoint-Extraktion (falls nötig laut 1.7)

**Ziel:** Wenn `TrendPoint` außerhalb `ProgressionTypes.swift` genutzt wird, Typ vor Löschung in eigene Datei extrahieren.

**Dateien:**
- NEU (falls nötig): `MotionCore/Types/TrendPoint.swift`
- ÄNDERN: `ProgressionTypes.swift` — Typ entfernen

**Wenn 1.7 zeigt, dass `TrendPoint` NUR in `ProgressionTypes.swift` und den zu löschenden Files verwendet wird:** Schritt überspringen, direkt zu 1.9.

**🛑 STOPP 1.8** (ggf. überspringen mit "n/a")

---

## Schritt 1.9 — Legacy-UI-Entfernung (Views)

**Ziel:** Alle Progression-Views löschen.

**Dateien (ALLE LÖSCHEN):**
- `ProgressionAnalyseView.swift`
- `ProgressionDetailView.swift`
- `ProgressionBannerView.swift`
- `ProgressionOverviewCard.swift`
- `ProgressionExerciseCard.swift`
- `ProgressionInsightCard.swift`
- `ProgressionSectionHeader.swift`
- `ProgressionSummaryCard.swift`

**Zusätzlich bereinigen:**
- Alle Referenzen auf diese Views in `ContentView`, `HomeView`, `WorkoutAnalyseView`, `StrengthDetailView` — entfernen
- `AnalyseSegment`-Enum: wenn nur `.heatmap` übrig → entfernen oder belassen als Einzelwert für zukünftige Erweiterung
- Navigation-Pfade bereinigen

**Anforderungen:**
- Keine toten Imports
- Keine dangling references
- Heatmap-Ansicht bleibt vollständig funktional

**Build-Check:**
- iOS + watchOS grün
- Heatmap öffnet normal
- Kein Navigationspfad führt mehr zu den gelöschten Views

**Screenshots:** Heatmap-Ansicht, Workout-Analyse-Ansicht (falls noch existiert).

**🛑 STOPP 1.9** — Nach STOPP testet Barto manuell, dass nichts offensichtlich fehlt.

---

## Schritt 1.10 — Legacy-CalcEngines + ViewModel entfernen

**Dateien (LÖSCHEN):**
- `ProgressionCalcEngine.swift`
- `ProgressionAnalyseCalcEngine.swift`
- `ProgressionViewModel.swift`
- `ProgressionTypes.swift`

**Zusätzlich bereinigen:**
- Referenzen in ggf. noch übrigen ViewModels (z.B. `WorkoutAnalyseViewModel`, `StatisticsViewModel`)

**Build-Check:**
- Grün
- SummaryView, StrengthDetailView, ActiveWorkoutView funktionieren

**🛑 STOPP 1.10**

---

## Schritt 1.11 — Exercise-Felder entfernen + SetConfigurationSheet-UI bereinigen

**Dateien:**
- ÄNDERN: `MotionCore/Models/Exercise.swift`
  - ENTFERNEN: `progressionStrategyRaw`, `customProgressionStep`, `progressionSessionsRequired`, `minDaysBetweenProgressions`
  - ENTFERNEN: Computed `progressionStrategy`, `canRecommendProgression`, `effectiveProgressionStep`, `baseProgressionStep` (falls dort definiert)
  - ENTFERNEN: Entsprechende `init()`-Parameter
- ÄNDERN: `ExerciseSeeder.swift` — diese Felder nicht mehr setzen
- ÄNDERN: `Export.swift` — Export-Schema anpassen, rückwärtskompatibel lassen beim Import
- ÄNDERN: `FormViewSection.swift` — `ExerciseProgressionSection` KOMPLETT entfernen
- ÄNDERN: `SetConfigurationSheet.swift` — Referenzen und States für Progression-Section entfernen

**Anforderungen:**
- SwiftData-Schema-Version erhöhen
- Lightweight Migration: entfernte Felder werden still ignoriert
- **Bestehende Exercises bleiben intakt**, nur die 4 Felder fallen weg

**Build-Check:**
- Grün
- App startet, bestehende Übungen öffnen
- Exercise-Edit-View funktioniert (ohne Progression-Section)
- SetConfiguration-Sheet funktioniert (ohne Progression-Section)
- Sessions bleiben vollständig

**Screenshots:** Exercise-Edit-View neu, SetConfigurationSheet neu.

**🛑 STOPP 1.11** — Barto testet: Legen sich neue Übungen an? Können alte bearbeitet werden?

---

## Schritt 1.12 — Studio-Setup + Default-Seeder

**Dateien:**
- NEU: `MotionCore/Views/Settings/StudioSetupView.swift`
- NEU: `MotionCore/Views/Settings/StudioEquipmentEditSheet.swift`
- NEU: `MotionCore/Views/Settings/StudioEquipmentRow.swift`
- NEU: `MotionCore/Services/DefaultStudioSeeder.swift`
- ÄNDERN: `MainSettingsView.swift` (oder equivalent) — Link "Studio einrichten"
- ÄNDERN: `MotionCoreApp.swift` — Seeder-Call beim ersten Start

**Anforderungen:**
- Seeder idempotent: prüft ob Studio existiert, läuft nur wenn nicht
- Seeder legt "Mein Studio" + die 5 Emser-Therme-Defaults an
- Edit-Sheet: alle Felder editierbar
- Zwischengewichte als dynamische Liste (add/remove)
- Validierung (Name nicht leer, Increment > 0)
- `.glassCard()`-Styling

**Build-Check:**
- Erster Start: Studio wird erzeugt
- Zweiter Start: keine Duplikation
- Editieren funktioniert, Löschen mit Bestätigung

**Screenshots:** StudioSetupView, EquipmentEditSheet.

**🛑 STOPP 1.12**

---

## Schritt 1.13 — Medikamenten-Schalter in Settings

**Dateien:**
- ÄNDERN: `AppSettings.swift` (oder equivalent)
  - NEU: `@AppStorage("takesCardioMedication") var takesCardioMedication: Bool = false`
- ÄNDERN: Settings-Screen (vorzugsweise in Sektion "Gesundheit" oder neuer "Tagesform")
  - Toggle "Ich nehme kreislaufwirksame Medikamente"
  - Max 2 Zeilen Erklärtext: "Passt die Analyse deiner Tagesform an, z.B. bei Betablockern."

**Anforderungen:**
- In Phase 1 hat Schalter keine funktionale Wirkung
- Wert muss persistieren

**🛑 STOPP 1.13**

---

## Schritt 1.14 — Neue `ProgressionCalcEngine`

**Dateien:**
- NEU: `MotionCore/CalcEngines/ProgressionCalcEngine.swift`
- NEU: `MotionCore/CalcEngines/ProgressionTypes.swift` (Input/Output/Reasoning)
- NEU: `MotionCore/Services/EquipmentWeightRounding.swift` (Helper für Equipment-aware Rounding)

**Anforderungen:**
- Pure Struct, keine Side Effects, keine SwiftUI-Imports
- API gemäß Concept 4.1
- `readinessModifier`-Parameter bereits vorhanden, in Phase 1 immer 1.0
- Equipment-aware Rounding: rundet auf gültige Sprünge des `StudioEquipment`, Fallback `exerciseFallbackStep`
- Zwischengewichte NICHT in Engine-Output — kommen nur via Feintuning-UI

**Manuelle Testszenarien (dokumentieren in Kommentar oder Test-View):**
1. Keine Historie → `firstSession`
2. Modus `.off` → `noProgression`
3. Alle Sätze Ziel-Reps + RIR 1 (rpe=9) → `increaseWeight`
4. Alle Sätze Ziel-Reps + RIR 4 (rpe=6) → `bigIncrease`
5. Reps unter Ziel + RIR 0 (rpe=10) → `holdWeight`
6. Reps unter Ziel + jüngste Progression → `rollbackSuggested`
7. readinessModifier 0.85 → `readinessReduced`
8. `currentSessionSetIndex > 0` → Wert vom vorherigen Satz der aktuellen Session

**Build-Check:**
- Grün
- Engine-Preview oder Test-View zeigt alle 8 Szenarien

**🛑 STOPP 1.14**

---

## Schritt 1.15 — `RollbackDetectionCalcEngine`

**Dateien:**
- NEU: `MotionCore/CalcEngines/RollbackDetectionCalcEngine.swift`

**Anforderungen:**
- API gemäß Concept 4.3
- Trigger: `lastProgressionDate` ≤ 2 Sessions her UND beide Sessions letzter-Satz-Reps < `minTargetReps` (< 8)
- Pure Struct

**Manuelle Testszenarien:**
1. Progression vor 1 Session, letzter Satz 10 Reps → kein Rollback
2. Progression vor 2 Sessions, beide Male 7 Reps → Rollback
3. Progression vor 4 Sessions → kein Rollback (außerhalb Fenster)
4. Progression nie durchgeführt → kein Rollback

**🛑 STOPP 1.15**

---

## Schritt 1.16 — Smart-Fill im ActiveWorkoutView

**Ziel:** Bei Satzeingabe Placeholder-Werte aus ProgressionCalcEngine.

**Dateien:**
- ÄNDERN: `ActiveWorkoutView.swift` oder neue `ActiveWorkoutSetInputView.swift` (falls Splitting nötig)
- NEU ggf.: `ActiveWorkoutSetInputViewModel.swift`

**Anforderungen:**
- Engine wird pro Übung einmal beim Öffnen aufgerufen, Resultat cached in `[exerciseGroupKey: Output]`-Dictionary
- Placeholder-Werte in Gewicht-/Reps-Feld (grau, weichen beim Tap)
- Bei `currentSessionSetIndex > 0`: Engine nimmt vorherigen Satz der aktuellen Session als Baseline
- `ExerciseProgressionState` wird **lazy erstellt** beim ersten Satz einer Übung (siehe Concept 3.4)
- Performance: kein Flickern
- `ActiveWorkoutView` nähert sich 800 Zeilen — ggf. Splitting nötig (Quality-Gate entscheidet)

**Edge Cases:**
- Ganz neue Übung ohne Historie → kein Placeholder, User trägt frei ein
- Engine schlägt Rollback vor → Placeholder zeigt `previousWorkingWeight`

**Build-Check:**
- Training starten → erste Übung mit Vorschlag
- Vorschlag akzeptieren → nächster Satz aktualisiert
- Vorschlag überschreiben → Override wird gespeichert

**Screenshots:** ActiveWorkoutView mit Placeholder, mit ausgefülltem Satz.

**🛑 STOPP 1.16**

---

## Schritt 1.17 — Feintuning-Button für Zwischengewichte

**Dateien:**
- NEU: `MotionCore/Views/ActiveWorkout/FineTuneChipsView.swift`
- ÄNDERN: ActiveWorkout-Satz-Eingabe

**Anforderungen:**
- Button nur sichtbar, wenn zugewiesenes Equipment `intermediateIncrements` hat
- Chips inline unter Gewicht-Feld: `+0.625` `+1.25` (bzw. aus `intermediateIncrements`)
- Minus-Chips symmetrisch
- Tap: addiert/subtrahiert Wert
- Schließt sich automatisch nach Auswahl

**Build-Check:**
- Kabelzug-Übung: Chips 0.625 und 1.25 sichtbar
- Kurzhantel-Übung: keine Chips
- Übung ohne Equipment-Zuweisung: keine Chips

**🛑 STOPP 1.17**

---

## Schritt 1.18 — RIR-Sheet am letzten Satz

**Dateien:**
- NEU: `MotionCore/Views/ActiveWorkout/RIRInputSheet.swift`
- NEU: `MotionCore/Views/ActiveWorkout/CompactRestTimerView.swift` (oder `RestTimerCard` um `isCompact: Bool` erweitern)
- ÄNDERN: `ActiveWorkoutView.swift`
  - Erkennung letzter Satz
  - Sheet-Trigger bei "Satz abschließen" am letzten Satz
  - Setzen von `isLastSetOfExercise = true` auf dem entsprechenden Set

**Anforderungen:**
- Sheet-Höhe kompakt, max ~45% Screen
- RestTimer ~60% normale Höhe
- RIR-Buttons einzeilig: `0` `1` `2` `3` `4+`, Höhe ~48pt, gleich breit
- Kleine Zeile oben: "Wie viele Reps wären noch drin gewesen?"
- Skip-Link klein unten
- Tap auf Button: `set.rpe = 10 - rirValue` (bei `4+` → `rpe = 6`), Sheet schließt
- Skip: `rpe` bleibt 0, Sheet schließt
- Nicht-letzter Satz: normaler RestTimer, kein Sheet

**Erkennung letzter Satz:**
- Anzahl geplanter Sätze für die Übung in aktueller Session: `session.safeExerciseSets.filter { $0.groupKey == currentGroupKey && $0.setKind == .work }.count`
- Aktueller abgeschlossener Satz-Index
- Wenn alle Work-Sätze der Übung completed → letzter Satz

**Edge Cases:**
- User fügt nach RIR-Eingabe weiteren Satz hinzu → alter Satz bekommt `isLastSetOfExercise = false`, neuer bekommt `true` (oder bleibt unverändert — muss Barto entscheiden)
- User löscht letzten Satz → vorheriger wird `isLastSetOfExercise = true`

**Kein Konflikt mit `ExerciseRatingCard`:**
- RIR-Sheet erscheint während des letzten Satzes (beim "Satz abschließen" Button)
- `ExerciseRatingCard` erscheint danach im `ExerciseCompletedCard`
- Zeitlich getrennt, beide können bestehen

**Build-Check:**
- Training mit 3 Sätzen: RIR-Sheet nur nach Satz 3
- 5 Buttons in einer Zeile auf iPhone 15 UND iPhone SE
- Skip funktioniert, `rpe` bleibt 0
- `rpe`-Wert korrekt berechnet bei Tap

**Screenshots:** RIR-Sheet auf iPhone 15 + iPhone SE. Bestätigung: `ExerciseRatingCard` erscheint danach weiterhin normal.

**🛑 STOPP 1.18**

---

## Schritt 1.19 — Quick-Config aus ActiveWorkout

**Dateien:**
- NEU: `MotionCore/Views/ActiveWorkout/ExerciseQuickConfigSheet.swift`
- ÄNDERN: `ActiveWorkoutView.swift` — ⚙️-Icon am Übungskopf
- ÄNDERN: `ExerciseFormView.swift` (oder equivalent Edit-View) — neue Felder integrieren:
  - Equipment-Picker (Studio-Geräte + "Kein Gerät")
  - `customTargetReps`-Input (optional)
  - Progression-Mode-Picker (Smart/Advanced/Off)
  - `configNotes`-Freitext

**Anforderungen:**
- Quick-Config-Sheet zeigt: Übungsname, aktuelles Gerät (oder "—"), Ziel-Reps, Mode, Notiz
- Button "Zur Übung bearbeiten" → navigiert zu Exercise-Edit (Pattern aus `StrengthDetailView` zu Exercise wiederverwenden)
- Nach Bearbeitung: zurück ins aktive Training

**Build-Check:**
- Icon tappen → Sheet öffnet
- Link zu Exercise-Edit funktioniert
- Änderung speichern → zurück ins Training, neuer Wert wird bei nächstem Satz sichtbar

**Screenshots:** Quick-Config-Sheet, Exercise-Edit mit neuen Feldern.

**🛑 STOPP 1.19**

---

## Schritt 1.20 — Rollback-Insight-Karte + manueller Rollback

**Dateien:**
- NEU: `MotionCore/Views/Summary/RollbackInsightCard.swift`
- ÄNDERN: `SummaryView.swift` — Integration
- ÄNDERN: `StrengthDetailView.swift` oder `ExerciseDetailView` — Rollback-Badge + Button "Arbeitsgewicht zurücksetzen"
- NEU: `MotionCore/Services/ProgressionRollbackService.swift`

**Anforderungen:**
- Karte: Titel, Begründung, 3 Buttons
- "Zurück auf X kg": `workingWeight` auf `previousWorkingWeight`, `lastRollbackDate = now`, `consecutiveFailCount = 0`
- "Weiter versuchen": nur `consecutiveFailCount = 0`
- "Ich trage selbst ein": `progressionMode = .advanced`
- Manueller Button in Exercise-Detail: Bestätigungsdialog
- Service pure, alle Änderungen über ModelContext

**Build-Check:**
- Karte erscheint nach 2 schlechten Sessions (manuell erzeugbar)
- Buttons funktionieren korrekt
- Keine Dopplung

**🛑 STOPP 1.20**

---

## Schritt 1.21 — `SessionQualityCalcEngine` + Integration

**Dateien:**
- NEU: `MotionCore/CalcEngines/SessionQualityCalcEngine.swift`
- ÄNDERN: Session-Abschluss-Workflow (in ActiveWorkoutViewModel oder WorkoutCompletionService)
- ÄNDERN: `SummaryView.swift` oder `SummaryHeroCard.swift` — kleine Statline "Session-Qualität: X/100"

**Anforderungen:**
- API gemäß Concept 4.6
- Berechnung bei Session-Abschluss, Score auf `StrengthSession.sessionQualityScore`
- Gewichtung:
  - RIR-Ausbelastung 40%
  - Ziel-Reps erreicht 35%
  - Readiness-adjustiert 25% (Phase 1: neutral = 100%)
- Score 0–100, immer im Bereich

**🛑 STOPP 1.21**

---

## Schritt 1.22 — Supabase-Schema-Erweiterung

**Dateien:**
- ÄNDERN: `SupabaseFullBackupService.swift`
- NEU: Supabase SQL-Migration im `motioncore`-Schema:
  - CREATE `studios`
  - CREATE `studio_equipment`
  - CREATE `exercise_progression_states`
  - CREATE `session_readiness`
  - CREATE `health_baselines`
  - ALTER `exercises` — neue Spalten: `studio_equipment_id`, `custom_target_reps`, `progression_mode_raw`, `config_notes`
  - ALTER `exercise_sets` — neue Spalte: `is_last_set_of_exercise`
  - ALTER `strength_sessions` — neue Spalten: `session_quality_score`, `session_readiness_id`

**Anforderungen:**
- Idempotente Migration
- Entfernte Exercise-Felder (`progression_strategy_raw` etc.) bleiben in Supabase (historische Daten)
- Backup-Service befüllt neue Tabellen
- Session-Upload überträgt neue Felder

**Build-Check:**
- Manueller Backup-Trigger → Tabellen gefüllt
- Session-Abschluss → Supabase-Row hat neue Felder
- Keine Fehler in Logs

**🛑 STOPP 1.22 — Ende Phase 1**

---

## 🎯 Phase-1-Abschluss

### Definition of Done
- [ ] Alle 22 Schritte abgeschlossen
- [ ] Alte Progression-Views/Engines komplett entfernt
- [ ] Alte Exercise-Felder entfernt
- [ ] Training durchführbar mit Smart Progression
- [ ] RIR-Erfassung via `rpe` funktioniert
- [ ] Quick-Config erreichbar
- [ ] Rollback-System funktioniert
- [ ] Session-Qualität berechnet
- [ ] `ExerciseRating` funktioniert unverändert
- [ ] `PlanUpdateCalcEngine` funktioniert unverändert
- [ ] Supabase-Sync komplett

### User-Test-Phase (mind. 1 Woche)
Barto trainiert 1 Woche (3-4 Sessions). Feedback:
- Vorschläge sinnvoll?
- RIR-Eingabe störend oder passend?
- Rollbacks korrekt?
- Edge Cases?

**🛑 GROSSER STOPP vor Phase 2**

---

# PHASE 2 — Readiness

## Schritt 2.1 — HealthKit-Abfragen erweitern

(siehe v1.0 Schritt 2.1 — unverändert)

## Schritt 2.2 — HealthBaseline-Updates

Baselines werden bereits als Model in 1.5 angelegt. In 2.2 wird der Update-Service gebaut.

**Dateien:**
- NEU: `MotionCore/Services/HealthBaselineUpdateService.swift`
- ÄNDERN: App-Start Hook

**Anforderungen:**
- Rolling Mean + StdDev über 28 / 42 Tage (je nach Medikamenten-Schalter)
- Update einmal pro Tag beim Foreground
- Persistierung in SwiftData
- Fallback bei <14 Datenpunkten → `isCalibrating`

**🛑 STOPP 2.2**

## Schritt 2.3 — `ReadinessCalcEngine`

(siehe v1.0 Schritt 2.3 — unverändert)

## Schritt 2.4 — SessionReadiness-Speicherung

(siehe v1.0 Schritt 2.4 — unverändert; Modell ist bereits in 1.5 angelegt)

## Schritt 2.5 — Readiness-Karte (kompakt)

(siehe v1.0 Schritt 2.5 — unverändert)

## Schritt 2.6 — Readiness-Expanded-View

(siehe v1.0 Schritt 2.6 — unverändert)

## Schritt 2.7 — Verdrahtung mit ProgressionCalcEngine

**Ziel:** `readinessModifier` wird jetzt dynamisch.

**Dateien:**
- ÄNDERN: `ActiveWorkoutSetInputViewModel.swift` (oder Ort der Engine-Aufrufe)

**Anforderungen:**
- Beim Workout-Start: aktuelle `SessionReadiness` laden, Modifier extrahieren
- Vorschläge zeigen `readinessReduced`-Reasoning wenn Modifier < 1

**🛑 STOPP 2.7**

## Schritt 2.8 — Kalibrierungs-Hinweis-UI

(siehe v1.0 Schritt 2.8 — unverändert)

**🛑 STOPP 2.8 — Ende Phase 2**

---

# PHASE 3 — Dynamic Hints & Volumen-Ampel

## Schritt 3.1 — `VolumeTargetCalcEngine`

(siehe v1.0 Schritt 3.1 — unverändert)

## Schritt 3.2 — Tracked-Muscle-Groups-Settings

(siehe v1.0 Schritt 3.2 — unverändert)

## Schritt 3.3 — Wochenvolumen-Karte auf SummaryView

(siehe v1.0 Schritt 3.3 — unverändert)

## Schritt 3.4 — MuscleHeatmap-Toggle Ist/Ziel

(siehe v1.0 Schritt 3.4 — unverändert)

## Schritt 3.5 — `DynamicSplitHintCalcEngine`

(siehe v1.0 Schritt 3.5 — unverändert)

## Schritt 3.6 — Split-Hint-Karte auf Workout-Start

(siehe v1.0 Schritt 3.6 — unverändert)

**🛑 STOPP 3.6 — Ende Phase 3**

---

# ANHANG

## A. Abhängigkeiten Phase 1

```
1.1 ─┬─ 1.2 ─┬─ 1.3 ── 1.4 ── 1.5 ── 1.6 ─── 1.7 ── 1.8 ── 1.9 ── 1.10 ── 1.11 ── 1.12
     │       │                                                                    │
     │       │                                                                    ├── 1.13
     │       │                                                                    │
     │       │                                                                    └── 1.14 ── 1.15 ── 1.16 ── 1.17 ── 1.18 ── 1.19 ── 1.20 ── 1.21 ── 1.22
```

## B. Agent-Briefing-Template

Für jeden Schritt produziert Planner:

```markdown
# Schritt X.Y Plan

## Ziel
[1 Satz]

## Files (erwartet)
- NEU: ...
- ÄNDERN: ...
- LÖSCHEN: ...

## Cross-References (für Löschungen)
- [Liste aller Usages]
- [Aufräum-Plan]

## Detail-Steps
1. ...

## Manuelle Tests
1. ...

## Build-Check
- [ ] iOS build green
- [ ] watchOS build green (if applicable)
- [ ] No new warnings
- [ ] App launches
- [ ] Bestehende Daten intakt
- [ ] Affected views load without crash

## Risks / Open Questions
- ...
```

## C. Rollback-Strategie

Jeder Schritt als eigener Commit. Bei Problemen: `git revert <commit>`, Status an Barto, Replan.

## D. Kommunikation

- Sprache: Deutsch für User-Texte und Statusmeldungen
- Screenshots bei UI-Änderungen obligatorisch
- Zusammenfassung pro Schritt: max 10 Zeilen

## E. Notfall-Kriterien

Bei einem dieser Probleme: sofort STOPP und Meldung:

1. SwiftData-Migration schlägt fehl
2. CloudKit-Sync bricht
3. `ExerciseRating`-System bricht unbeabsichtigt
4. `PlanUpdateCalcEngine`-System bricht unbeabsichtigt
5. HealthKit-Permissions müssen verändert werden
6. Supabase-Schema-Änderung erfordert Datenverlust
7. File > 1000 Zeilen erzwungen
8. Cross-Reference-Check in 1.7 zeigt unerwartete Usages

## F. Besonderheiten dieser Version (v1.1)

- **Schritte 1.3/1.4 getrennt von 1.11**: erst neue Felder hinzufügen (additiv, sicher), dann nach manueller Test-Phase die alten Felder entfernen
- **Schritt 1.7 Cross-Reference-Check** vor Löschungen: verhindert Kaskadenfehler
- **`rpe`-Feld wird semantisch neu interpretiert**, aber nicht überschrieben
- **`ExerciseRating` explizit als unveränderlich markiert**
- **`PlanUpdateCalcEngine` explizit als unveränderlich markiert**
- **Multi-Studio-Datenmodell vorbereitet**, UI zeigt nur eins (YAGNI für v1)

---

**Ende Instruktionsdokument v1.1**
