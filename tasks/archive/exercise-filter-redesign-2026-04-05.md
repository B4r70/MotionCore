# ExerciseListView Filter-Redesign

**Complexity:** Medium

## Summary

Die ExerciseListView bekommt ein überarbeitetes Filter-System: Der doppelte floating Lupe-Button wird entfernt, die horizontalen Filter-Chips werden durch eine kompakte FilterBar ersetzt (drei Toggle-Icons + ein Filter-Button), und der Muskel-Filter wird zum zweistufigen hierarchischen Picker aufgewertet (MuscleGroup → DetailedMuscle). Das bereits existierende `ExerciseFilterSheet` wird als zentrale Filterkomponente wiederverwendet und um eine Kategorie-Sektion erweitert.

## Scope

**Enthalten:**
- Entfernung des floating Lupe-Buttons und zugehöriger States
- Ersatz der horizontalen Filter-Chips durch eine kompakte FilterBar (Toggle-Icons + Filter-Sheet-Button)
- Erweiterung des `ExerciseFilterSheet` um Kategorie-Sektion
- Zweistufiger Muskel-Filter in ExerciseListView (MuscleGroup + DetailedMuscle)
- Equipment-Filter auf `BundledEquipmentItem` umstellen (wie LocalExerciseSearchView)
- Aktive Filter als entfernbare Capsule-Tags unter der FilterBar

**Nicht enthalten:**
- Änderungen am Exercise-Datenmodell
- Änderungen an `LocalExerciseSearchView` (bleibt unverändert)
- Änderungen an `ExercisePickerSheet`

## Affected Files

- `MotionCore/Views/Training/Exercises/View/ExerciseListView.swift` — Hauptänderung
- `MotionCore/Views/Training/Exercises/View/ExerciseFilterSheet.swift` — Kategorie-Sektion hinzufügen

## Risks

- **ExerciseFilterSheet-Kompatibilität:** `LocalExerciseSearchView` nutzt das Sheet ebenfalls. Kategorie-Binding muss optional / mit Default sein.
- **Equipment-Filter-Umstellung:** Wechsel von `ExerciseEquipment`-Enum auf `BundledEquipmentItem` erfordert Anpassung der Filterlogik (`equipmentRaw`-Vergleich).
- **Muskel-Filter zweistufig:** Logik aus `LocalExerciseSearchView` übernehmen (Level-1 über `primaryMusclesRaw` Fallback, Level-2 über `detailedPrimaryMusclesRaw`).

## Implementation Steps

- [x] **1. ExerciseFilterSheet um Kategorie erweitern** (`ExerciseFilterSheet.swift`)
  - Neues optionales Binding `selectedCategory: Binding<ExerciseCategory?> = .constant(nil)`
  - Neue `categorySection`-View (LazyVGrid mit ExerciseCategory.allCases)
  - `activeFiltersCard`, `hasActiveFilters`, `resetFilters()` um Kategorie ergänzen
  - `LocalExerciseSearchView` übergibt kein Kategorie-Binding → bleibt kompatibel

- [x] **2. ExerciseListView: States anpassen** (`ExerciseListView.swift`)
  - `selectedMuscleGroup: MuscleGroup?` → behalten als `selectedPrimaryMuscle: MuscleGroup?`
  - Neuen State `selectedSubMuscle: DetailedMuscle?` hinzufügen
  - `selectedEquipment: ExerciseEquipment?` → `selectedEquipment: BundledEquipmentItem?`
  - Neuer State `equipmentItems: [BundledEquipmentItem] = []`
  - Neuer State `showFilterSheet: Bool = false`
  - `showingAPISearch`-State entfernen

- [x] **3. Floating Lupe-Button entfernen** (`ExerciseListView.swift`)
  - `.overlay(alignment: .bottomLeading) { ... }` Block entfernen
  - `.sheet(isPresented: $showingAPISearch) { LocalExerciseSearchView(...) }` entfernen

- [x] **4. Filter-Chips durch FilterBar ersetzen** (`ExerciseListView.swift`)
  - `filterChips`-Property ersetzen durch `filterBar`:
    - HStack: drei Toggle-Capsule-Buttons (Eigene / System / Favoriten) + Trichter-Button rechts
    - Trichter-Button zeigt gefülltes Icon + Akzentfarbe wenn Filter aktiv
  - `activeFiltersRow` darunter: entfernbare Capsule-Tags für Equipment, Muskel, Kategorie

- [x] **5. Filter-Sheet anbinden** (`ExerciseListView.swift`)
  - `.sheet(isPresented: $showFilterSheet)` mit `ExerciseFilterSheet` (alle Bindings)
  - `.task`: `equipmentItems = BundledEquipmentService.loadAll()`

- [x] **6. filteredExercises-Logik anpassen** (`ExerciseListView.swift`)
  - Equipment: `exercise.equipmentRaw == selectedEquipment.identifier`
  - Muskel zweistufig (aus `LocalExerciseSearchView` übernehmen)
  - Kategorie: `exercise.category == selectedCategory`

## Manual Verification

- [ ] `Cmd+B` — kein Compile-Fehler
- [ ] Floating Lupe-Button ist verschwunden
- [ ] Toggle-Icons (Eigene / System / Favoriten) funktionieren
- [ ] Filter-Button öffnet Sheet, Trichter-Icon zeigt aktive Filter an
- [ ] Kategorie-Filter im Sheet wirkt sich auf Liste aus
- [ ] Equipment-Filter im Sheet wirkt sich auf Liste aus
- [ ] Muskel Level-1 (Gruppe) filtert alle Übungen dieser Gruppe
- [ ] Muskel Level-2 (Detail) filtert exakt auf `detailedPrimaryMusclesRaw`
- [ ] Aktive Filter-Tags unter FilterBar entfernbar (Tap auf × löscht einzelnen Filter)
- [ ] "Zurücksetzen" im Sheet setzt alle Filter zurück
- [ ] `LocalExerciseSearchView` funktioniert weiterhin (Regression)

---

## Fortschritt

**2026-04-05**

Alle 6 Implementierungsschritte abgeschlossen.

**Geänderte Dateien:**
- `MotionCore/Views/Training/Exercises/View/ExerciseFilterSheet.swift` — `selectedCategory`-Binding hinzugefügt, neue `categorySection` (LazyVGrid mit Icons), `hasActiveFilters` + `resetFilters()` + `activeFiltersCard` um Kategorie ergänzt, Preview aktualisiert
- `MotionCore/Views/Training/Exercises/View/ExerciseListView.swift` — Komplett überarbeitet: States auf `BundledEquipmentItem?`, `MuscleGroup?`, `DetailedMuscle?`, `ExerciseCategory?` umgestellt; floating Lupe-Button + `showingAPISearch`-Sheet entfernt; `filterChips` durch `filterBar` (drei `FilterToggleButton` + Trichter) ersetzt; `activeFiltersRow` mit entfernbaren `ActiveFilterTag`-Capsules; zweistufige Muskel-Filterlogik aus `LocalExerciseSearchView` übernommen; Equipment-Vergleich auf `equipmentRaw == identifier`
- `MotionCore/Views/Training/Exercises/View/LocalExerciseSearchView.swift` — `ExerciseFilterSheet`-Aufruf um `.constant(nil)` für `selectedCategory` ergänzt (Rückwärtskompatibilität)
