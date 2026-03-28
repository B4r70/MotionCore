# Progressions-Übersicht: Trend-Gruppierung

**Complexity:** Medium
**Status:** Genehmigt

## Summary

Flache Übungsliste in `ProgressionAnalyseView` durch aufklappbare Sektionen nach `PerformanceTrend` ersetzen.
Reihenfolge: Aufwärtstrend → Stabil → Rückgang → Zu wenig Daten.
Default-Zustand: alle Sektionen offen. Labels kurz und deutsch.

## Affected Files

- `MotionCore/Services/ViewModels/ProgressionViewModel.swift` — neues `groupedByTrend` Property
- `MotionCore/Views/Progression/View/ProgressionAnalyseView.swift` — flache ForEach durch DisclosureGroup-Sektionen ersetzen
- `MotionCore/Views/Progression/Components/ProgressionSectionHeader.swift` — **NEU**: Sektions-Header (Trend-Icon + Label + Count)

## Implementation Steps

- [x] **Step 1: `ProgressionViewModel.swift`** — `groupedByTrend: [(trend: PerformanceTrend, exercises: [(Exercise, ProgressionAnalysis)])]` computed Property. Reihenfolge: `.improving` → `.stable`/`.volatile` → `.declining` → `.insufficient`. Innerhalb jeder Gruppe alphabetisch. `volatile` → `.stable`-Gruppe. `.insufficient`-Sektion nur wenn vorhanden.
- [x] **Step 2: `ProgressionSectionHeader.swift` erstellen** — Trend-Icon + Label + Count-Badge. Labels: `.improving` → "Aufwärtstrend", `.stable` → "Stabil", `.declining` → "Rückgang", `.insufficient` → "Zu wenig Daten". Kein `.glassCard()` auf den Header.
- [x] **Step 3: `ProgressionAnalyseView.swift`** — `VStack { ForEach(trainedExercises) }` durch Sektionen ersetzen. Pro Gruppe ein `DisclosureGroup` mit `ProgressionSectionHeader` als Label. State: `@State private var expandedSections: Set<PerformanceTrend> = [.improving, .stable, .declining, .insufficient]` (alle offen). `sheet(item:)` bleibt unverändert.

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Sektionen sichtbar, korrekt gruppiert und benannt
- [ ] Auf-/Zuklappen funktioniert
- [ ] Tap auf Card → ProgressionDetailView Sheet öffnet korrekt
- [ ] Hero-Card zeigt weiterhin korrekte Zahlen
- [ ] EmptyState bei null Übungen weiterhin sichtbar

## Fortschritt

**Datum:** 2026-03-28
**Abgeschlossene Steps:** alle 3 Implementation Steps

**Geänderte Dateien:**
- `MotionCore/Services/ViewModels/ProgressionViewModel.swift` — computed Property `groupedByTrend` hinzugefügt
- `MotionCore/Views/Progression/Components/ProgressionSectionHeader.swift` — **NEU**: Trend-Icon + Label + Count-Badge
- `MotionCore/Views/Progression/View/ProgressionAnalyseView.swift` — `expandedSections`-State + DisclosureGroup-Sektionen statt flachem ForEach

**Hinweis:** `ProgressionSectionHeader.swift` ist eine neue Datei — muss manuell zum Xcode-Target hinzugefügt werden (falls nicht durch `PBXFileSystemSynchronizedBuildFileExceptionSet` automatisch erkannt).

**Offene Punkte:** Manual Verification in Xcode (Cmd+B)

---

# Exercise-Navigation aus SetConfigurationSheet

**Complexity:** Small

## Summary

In der `exerciseInfoCard` des `SetConfigurationSheet` soll ein NavigationLink-Icon ergänzt werden, das zur `ExerciseFormView` (Edit-Modus) der jeweiligen Exercise navigiert. Das Icon erscheint nur, wenn eine Exercise-Referenz vorhanden ist (Init A), nicht im Snapshot-Modus (Init B).

## Affected Files

- `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift` — NavigationLink-Icon in `exerciseInfoCard` ergänzen

## Implementation Steps

- [x] In `exerciseInfoCard` (nach `Spacer()`): einen `NavigationLink` ergänzen, der nur angezeigt wird wenn `exercise != nil`
- [x] NavigationLink-Ziel: `ExerciseFormView(mode: .edit, exercise: ex, showDeleteButton: false)`
- [x] Icon: `Image(systemName: "arrow.right.circle")` mit passendem Stil

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Icon sichtbar in PlanExerciseCard, Tap → ExerciseFormView
- [ ] Zurück-Navigation funktioniert korrekt
- [ ] Snapshot-Modus (Init B): Icon NICHT sichtbar

## Fortschritt

**Datum:** 2026-03-28
**Abgeschlossene Steps:** alle 3 Implementation Steps

**Geänderte Dateien:**
- `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift` — NavigationLink nach `Spacer()` in `exerciseInfoCard` eingefügt; nur sichtbar wenn `exercise != nil`

**Offene Punkte:** Manual Verification in Xcode (Cmd+B)

---

# Plan: DetailedMuscle-Bearbeitung in ExerciseFormView

**Komplexität:** Medium
**Status:** Warte auf Genehmigung

## Summary

Der User soll in der ExerciseFormView die feingranularen Muskeln (`detailedPrimaryMuscles` / `detailedSecondaryMuscles`) einsehen und bearbeiten können. Die Heatmap arbeitet bereits auf `DetailedMuscle`-Ebene und bevorzugt diese Daten gegenüber den groben `MuscleGroup`-Daten. Aktuell können nur Supabase-importierte Exercises von dieser Genauigkeit profitieren — mit diesem Feature auch custom und manuell korrigierte Exercises.

## Kontext

- `Exercise.primaryMuscles` Getter bevorzugt `detailedPrimaryMusclesRaw` (wenn nicht leer)
- `MuscleHeatmapCalcEngine` bevorzugt `detailedPrimaryMuscles`, fällt sonst auf alle Sub-Muskeln der `MuscleGroup` zurück (ungenauer)
- 42 `DetailedMuscle`-Cases, gruppiert nach 9 `parentGroup`-Werten
- `primaryMuscles`-Setter leert `detailedPrimaryMusclesRaw` (Fix aus letzter Session)

## Affected Files

- `MotionCore/Views/Training/Exercises/Components/DetailedMusclePicker.swift` — **NEU**: Picker gruppiert nach `parentGroup`, Multi-Select
- `MotionCore/Components/Forms/FormViewSection.swift` — 2 neue Sections: Primary + Secondary Detailed
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — Integration der Sections
- `MotionCore/Models/Core/Exercise.swift` — `detailedPrimaryMuscles`/`detailedSecondaryMuscles` Setter sync `primaryMusclesRaw`/`secondaryMusclesRaw`

## Implementation Steps

- [x] **Step 1: `DetailedMusclePicker.swift` erstellen** — Analog `MuscleGroupPicker`. `List` mit `Section` pro `parentGroup`, Checkmarks. Binding auf `[DetailedMuscle]`.
- [x] **Step 2: Neue Form-Sections in `FormViewSection.swift`** — `ExerciseDetailedPrimaryMusclesSection` + `ExerciseDetailedSecondaryMusclesSection`. Capsule-Tags + NavigationLink zum Picker.
- [x] **Step 3: Integration in `ExerciseFormView.swift`** — Sections unterhalb der bestehenden MuscleGroup-Sections. Zeigen "Keine" wenn leer.
- [x] **Step 4: `Exercise.swift` — Setter synchronisieren** — `detailedPrimaryMuscles`-Setter leitet `primaryMusclesRaw` aus `parentGroup` ab. Analog Secondary.

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] ExerciseFormView ohne DetailedMuscles — Sections zeigen "Keine"
- [ ] ExerciseFormView mit Supabase-Exercise — Capsule-Tags sichtbar
- [ ] DetailedMusclePicker — 9 Gruppen-Sektionen, Checkmarks korrekt
- [ ] DetailedMuscles setzen → Heatmap zeigt feingranulare Daten
- [ ] MuscleGroup ändern → DetailedMuscles werden geleert

---

## Fortschritt

**Datum:** 2026-03-27
**Abgeschlossene Steps:** alle 4 Implementation Steps

**Geänderte Dateien:**
- `MotionCore/Views/Training/Exercises/Components/DetailedMusclePicker.swift` — **NEU**: List mit Section pro parentGroup, Multi-Select Checkmarks
- `MotionCore/Components/Forms/FormViewSection.swift` — `ExerciseDetailedPrimaryMusclesSection` + `ExerciseDetailedSecondaryMusclesSection` nach Zeile 662 eingefügt
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — 2 neue Sections nach SekundäreMuscleGroups eingebunden
- `MotionCore/Models/Core/Exercise.swift` — `detailedPrimaryMuscles`/`detailedSecondaryMuscles` Setter leiten jetzt `primaryMusclesRaw`/`secondaryMusclesRaw` aus `parentGroup`-Werten ab

**Hinweis:** `DetailedMusclePicker.swift` ist eine neue Datei — muss manuell zum Xcode-Target hinzugefügt werden (falls nicht durch `PBXFileSystemSynchronizedBuildFileExceptionSet` automatisch erkannt).

---

# Abgeschlossener Plan: Muscle Heatmap Bug + Exercise-Edit Absicherung

**Complexity:** Medium
**Datum:** 2026-03-27

## Summary

Die Muscles Heatmap zeigt falsche Muskeln (Quadrizeps statt Brust/Arme) aus zwei Gründen:
1. **Setter-Bug im Exercise-Modell**: Der `primaryMuscles`-Setter leert `detailedPrimaryMusclesRaw` nicht — nach einer manuellen Korrektur in ExerciseFormView werden die alten (falschen) Detailed-Daten weiterhin bevorzugt.
2. **Sekundär-Faktor zu hoch**: `0.5` überschätzt den sekundären Stimulus systematisch → auf `0.3` senken.

Zusätzlich: ExerciseFormView zeigt aus StrengthDetailView heraus einen unerwünschten Löschen-Button (Quality Gate Finding aus vorheriger Session).

ExerciseSets brauchen **keine** Muscle-Snapshots — die Engine liest Muskeln live von `Exercise`.

## Affected Files

- `MotionCore/Models/Core/Exercise.swift` — Setter-Fix für primary + secondary muscles
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — Sekundär-Faktor 0.5 → 0.3
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — `showDeleteButton`-Parameter
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — `showDeleteButton: false` übergeben

## Implementation Steps

- [x] **Exercise.swift — `primaryMuscles` Setter fixen**: Im Setter zusätzlich `detailedPrimaryMusclesRaw = []` setzen
- [x] **Exercise.swift — `secondaryMuscles` Setter fixen**: Analog `detailedSecondaryMusclesRaw = []` im Setter
- [x] **MuscleHeatmapCalcEngine.swift — Sekundär-Faktor**: `volume * 0.5` → `volume * 0.3`
- [x] **ExerciseFormView.swift — `showDeleteButton: Bool = true` hinzufügen**: Property + Condition `if mode == .edit && showDeleteButton`
- [x] **StrengthDetailView.swift — `showDeleteButton: false` übergeben**: Im bestehenden `sheet(item: $exerciseToEdit)` Aufruf

---

## Fortschritt

**Datum:** 2026-03-27
**Abgeschlossene Steps:** alle 5 Implementation Steps

**Geänderte Dateien:**
- `MotionCore/Models/Core/Exercise.swift` — Setter `primaryMuscles` und `secondaryMuscles` leeren jetzt `detailedPrimaryMusclesRaw` bzw. `detailedSecondaryMusclesRaw`
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — Sekundär-Faktor 0.5 → 0.3
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — `showDeleteButton: Bool = true` Property + Condition `mode == .edit && showDeleteButton`
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — `showDeleteButton: false` im Sheet-Aufruf

**Offene Punkte:** keine — bereit für Xcode Build und Manual Verification

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Exercise mit falschen Muskeln via `ellipsis.circle` in StrengthDetailView öffnen
- [ ] Primary Muscles korrigieren (z.B. Chest statt Legs), speichern
- [ ] Heatmap in StrengthDetailView zeigt jetzt korrekte Muskeln
- [ ] Heatmap in MuscleHeatmapView (Analyse-Tab) zeigt korrekte Muskeln
- [ ] ExerciseFormView aus StrengthDetailView — kein Löschen-Button sichtbar
- [ ] ExerciseFormView aus ExerciseListView — Löschen-Button weiterhin sichtbar
