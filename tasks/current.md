# E-Bike Outdoor Feature (Phase 1)

**Complexity:** Large

## Summary

Implementierung der manuellen E-Bike-Tour-Erfassung in MotionCore. Umfasst: E-Bike-Profil in AppSettings, OutdoorTypes-Erweiterung, neue Properties auf OutdoorSession, vollstaendige Erfassungs-UI (OutdoorFormView), ListView-Integration mit eigener Card, DetailView, Basis-KPIs in der Statistik und Supabase-DTO-Erweiterung. Kein GPS/Location in Phase 1, kein EBikeProfile SwiftData-Model, kein Live-Tracking.

## Scope

**Enthalten:**
- E-Bike-Enums (BikeType, BikeCondition, TireSize)
- OutdoorActivity um `.eBike` erweitern, WeatherCondition um UI-Texte erweitern
- 6 strukturierte Adressfelder + 4 GPS-Koordinaten-Felder auf OutdoorSession
- E-Bike-Stammdaten als Properties in AppSettings (KEIN SwiftData-Model)
- EBikeProfileView fuer Einstellungen (arbeitet mit AppSettings)
- OutdoorFormSections (wiederverwendbare Form-Sections)
- OutdoorFormView (manuelle Erfassung)
- Navigation via NewWorkoutSheet + BaseView
- OutdoorSessionCard fuer ListView
- OutdoorDetailView fuer abgeschlossene Touren
- ListView-Integration mit Outdoor-Filter
- OutdoorRecordCalcEngine + Statistik-Integration
- Supabase DTO-Erweiterung (nur outdoor_sessions, KEINE ebike_profiles Tabelle)

**Explizit ausgeschlossen:**
- Kein EBikeProfile SwiftData-Model (Daten in AppSettings)
- Kein LocationHelper / GPS (erst Phase 3)
- Kein Live-Tracking / ActiveOutdoorWorkoutView (erst Phase 2)
- Keine Supabase ebike_profiles Tabelle
- Kein automatischer Kilometerstand-Update
- Keine Schema-Aenderung in MotionCoreApp.swift (kein neues Model)

## UX Placement

- **E-Bike Profil:** Einstellungen -> "Allgemeine Einstellungen" -> NavigationLink "E-Bike Profil"
- **Tour erfassen:** "+" FAB -> NewWorkoutSheet -> "E-Bike Tour" -> OutdoorFormView als Sheet
- **Tour in Liste:** Workouts-Tab -> Filter "Outdoor" -> OutdoorSessionCard -> OutdoorDetailView
- **Statistik:** StatisticView -> neue Section "E-Bike" (nur sichtbar wenn Touren existieren)

## Affected Files

### Neue Dateien (7+)

| Datei | Block |
|-------|-------|
| `Models/Types/EBikeProfileTypes.swift` | 1 |
| `Views/Settings/View/EBikeProfileView.swift` | 2 |
| `Views/Workouts/Outdoor/Components/OutdoorFormSections.swift` | 3 |
| `Views/Workouts/Outdoor/View/OutdoorFormView.swift` | 3 |
| `Views/Workouts/Outdoor/Components/OutdoorSessionCard.swift` | 5 |
| `Views/Workouts/Outdoor/View/OutdoorDetailView.swift` | 5 |
| `Services/Calculation/OutdoorRecordCalcEngine.swift` | 6 |

### Geaenderte Dateien (11)

| Datei | Block |
|-------|-------|
| `Models/Types/OutdoorTypes.swift` | 1 |
| `Models/Core/OutdoorSession.swift` | 1 |
| `Services/Settings/AppSettings.swift` | 1 |
| `Views/Settings/View/MainSettingsView.swift` | 2 |
| `Views/Workouts/Sheets/NewWorkoutSheet.swift` | 4 |
| `Views/Root/View/BaseView.swift` | 4 |
| `Views/Workouts/View/ListView.swift` | 5 |
| `Services/ViewModels/StatisticsViewModel.swift` | 6 |
| `Views/Statistics/Workouts/View/StatisticView.swift` | 6 |
| `Services/Database/Remote/Session/SupabaseSessionModels.swift` | 7 |
| `Services/Database/Remote/Session/SupabaseSessionService.swift` | 7 |

## Risks

- **Schema-Migration (OutdoorSession):** 10 neue Properties, alle optional/Default. CloudKit-kompatibel (nur Addition).
- **AppSettings Wachstum:** ~12 neue Properties. Langfristig ggf. Aufspaltung noetig.
- **ListView Performance:** Neuer @Query + computed property. Fuer Phase 1 akzeptabel.
- **Supabase Schema:** SQL-Migration noetig (neue Spalten). Muss vor App-Release erfolgen.

## Implementation Steps

### Block 1: Types & Models

- [x] **1.1** Neue Datei `EBikeProfileTypes.swift`: `BikeType` (5 Cases, description, icon), `BikeCondition` (5 Cases, description, color), `TireSize` (4 Cases, description)
- [x] **1.2** `OutdoorTypes.swift`: `.eBike` Case + `description`/`icon`/`tint` auf OutdoorActivity. `Identifiable`/`description`/`icon` auf WeatherCondition
- [x] **1.3** `OutdoorSession.swift`: 10 neue Properties (4 GPS Double?, 6 Adress-Strings mit Default "")
- [x] **1.4** `AppSettings.swift`: ~12 E-Bike-Properties (Name, Typ, Gewicht, Akku, Reifen, Zustand, km, Kaufdatum, Wartung, Notizen)

### Block 2: E-Bike Profil UI

- [x] **2.1** Neue Datei `EBikeProfileView.swift`: List-basiert, 3 Sections (Stammdaten, Zustand & Wartung, Notizen), arbeitet mit AppSettings
- [x] **2.2** `MainSettingsView.swift`: NavigationLink "E-Bike Profil" mit bicycle-Icon

### Block 3: Erfassungs-UI

- [x] **3.1** Ordnerstruktur `Views/Workouts/Outdoor/Components/` + `Views/Workouts/Outdoor/View/`
- [x] **3.2** Neue Datei `OutdoorFormSections.swift`: FocusedField-Enum + ~13 wiederverwendbare Section-Views mit Bindings
- [x] **3.3** Neue Datei `OutdoorFormView.swift`: Pattern wie FormView (Cardio). 4 GlassCards, Toolbar, Speicher-Logik mit Supabase-Upload

### Block 4: Navigation & Integration

- [x] **4.1** `NewWorkoutSheet.swift`: Outdoor-Button aktivieren, Titel "E-Bike Tour"
- [x] **4.2** `BaseView.swift`: States + Sheet-Logik fuer OutdoorFormView

### Block 5: Listen & Detail

- [x] **5.1** Neue Datei `OutdoorSessionCard.swift`: Header, Metriken-Grid, Route-Zeile, .glassCard()
- [x] **5.2** Neue Datei `OutdoorDetailView.swift`: 4 GlassCards + Aktionen (Bearbeiten/Loeschen)
- [x] **5.3** `ListView.swift`: WorkoutTypeFilter.outdoor, @Query, MixedWorkoutItem.outdoor, Navigation

### Block 6: Statistik

- [x] **6.1** Neue Datei `OutdoorRecordCalcEngine.swift`: totalDistance, totalElevation, longestTour, fastestTour, highestElevation, mostCalories
- [x] **6.2** `StatisticsViewModel.swift`: gecachte Outdoor-KPIs in recalculate()
- [x] **6.3** `StatisticView.swift`: neue E-Bike Section mit 4 StatisticGridCards

### Block 7: Supabase

- [x] **7.1** `SupabaseSessionModels.swift`: DTO um 13 Felder erweitern (GPS, Adresse, Gesundheit)
- [x] **7.2** `SupabaseSessionService.swift`: upload(OutdoorSession) an neues DTO anpassen
- [x] **7.3** SQL-Migration dokumentieren (ALTER TABLE outdoor_sessions ADD COLUMN ...)

## Open Questions

1. Wartungshinweis nur als Banner im Profil, oder auch Badge in MainSettingsView?
2. OutdoorFormView hardcoded `.eBike` (kein Picker), oder Picker vorbereiten?
3. SQL-Migration jetzt ausfuehren, oder erst beim Release?

---

## Fortschritt

**30.03.2026 — Block 1 abgeschlossen**

Erledigte Schritte: 1.1, 1.2, 1.3, 1.4

Geaenderte / neue Dateien:
- `MotionCore/Models/Types/EBikeProfileTypes.swift` — neu erstellt (BikeType, BikeCondition, TireSize)
- `MotionCore/Models/Types/OutdoorTypes.swift` — `.eBike` Case + description/icon/tint auf OutdoorActivity; Identifiable + description/icon auf WeatherCondition; import Foundation → import SwiftUI
- `MotionCore/Models/Core/OutdoorSession.swift` — 10 neue Properties (4x GPS Double?, 6x Adress-String mit Default "")
- `MotionCore/Models/Core/AppSettings.swift` — 13 neue E-Bike-Properties + init-Block

Offene Punkte: Blocks 3–7 ausstehend.

---

**30.03.2026 — Block 2 abgeschlossen**

Erledigte Schritte: 2.1, 2.2

Geaenderte / neue Dateien:
- `MotionCore/Views/Settings/View/EBikeProfileView.swift` — neu erstellt (3 Sections, AppSettings-Bindings, optionale DatePicker mit Toggle-Pattern, Wartungshinweis-Banner, Altersberechnung)
- `MotionCore/Views/Settings/View/MainSettingsView.swift` — NavigationLink "E-Bike Profil" (bicycle-Icon) nach "Training" eingefuegt

---

**30.03.2026 — Block 3 abgeschlossen**

Erledigte Schritte: 3.1, 3.2, 3.3

Neue Dateien:
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSections.swift` — OutdoorFocusedField-Enum + 4 Sections: OutdoorRouteNameSection, OutdoorAddressSection, OutdoorWeatherSection, OutdoorDurationSection
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSectionsMetrics.swift` — 9 Sections: Distanz, Hoehe, Speed (2 Felder), Kalorien, HF (2 Felder), Koerpergewicht, RPE, Energie, Intensitaet
- `MotionCore/Views/Workouts/Outdoor/View/OutdoorFormView.swift` — 4 GlassCards, Toolbar, Supabase-Upload analog FormView, eigene Keyboard-Navigation via OutdoorFocusedField

Entscheidungen:
- OutdoorFocusedField als eigener Enum (nicht FocusedField aus KeyboardToolbar.swift) — Keyboard-Toolbar inline implementiert
- Sections wegen > 400 Zeilen auf 2 Dateien aufgeteilt
- WeatherSection nutzt lokale @State-Variable fuer Temperatur-TextField (Double? erfordert Hilfsvariable)
- OutdoorFormView setzt hardcoded `.eBike` beim Speichern (Open Question 2 implizit beantwortet)

Offene Punkte: Blocks 5–7 ausstehend.

---

**30.03.2026 — Block 4 abgeschlossen**

Erledigte Schritte: 4.1, 4.2

Geaenderte Dateien:
- `MotionCore/Views/Workouts/Sheets/NewWorkoutSheet.swift` — Outdoor-Button: title "E-Bike Tour", subtitle "E-Bike Tour erfassen", color .green, isDisabled entfernt
- `MotionCore/Views/Root/View/BaseView.swift` — `showingAddOutdoor: Bool` + `outdoorDraft: OutdoorSession?` States; `onOutdoorSelected` Closure mit Delay-Pattern; Outdoor-Sheet mit `NavigationStack { OutdoorFormView }` + `.onChange` fuer outdoorDraft-Reset

---

**30.03.2026 — Block 5 abgeschlossen**

Erledigte Schritte: 5.1, 5.2, 5.3

Neue Dateien:
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorSessionCard.swift` — Header (Aktivitaets-Icon, Datum, Routenname, Wetter-Icon), Metriken-Grid (Dauer, Distanz, Speed, Hoehenmeter), Route-Zeile (nur wenn startLocation/endLocation befuellt), Intensitaets-Stars; nutzt GlassDivider.tight + StatBubble
- `MotionCore/Views/Workouts/Outdoor/View/OutdoorDetailView.swift` — 4 GlassCards (Route & Wetter, Leistungsdaten, Bewertung, Notizen); Toolbar Bearbeiten/Loeschen; Sheet mit OutdoorFormView im Edit-Modus; Delete-Alert

Geaenderte Dateien:
- `MotionCore/Views/Workouts/View/ListView.swift` — WorkoutTypeFilter.outdoor Case; @Query allOutdoorWorkouts; filteredOutdoorWorkouts (isCompleted + TimeFilter); isListEmpty-Outdoor-Case; completedWorkoutsSection .outdoor; mixedWorkoutsList .outdoor; createMixedWorkoutList Outdoor; deleteOutdoorSession; MixedWorkoutItem.outdoor Case; aktive-Section-Guard fuer .outdoor

Offene Punkte: Block 6 ausstehend.

---

**30.03.2026 — Block 7 abgeschlossen**

Erledigte Schritte: 7.1, 7.2, 7.3

Geaenderte Dateien:
- `MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift` — `SupabaseOutdoorSessionDTO` um 13 Felder erweitert: `heartRate`, `maxHeartRate`, `bodyWeight` (bisher im DTO fehlend), `startLatitude`, `startLongitude`, `endLatitude`, `endLongitude` (nullable Double), `startStreet`, `startPostalCode`, `startCity`, `endStreet`, `endPostalCode`, `endCity` (String)
- `MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift` — `upload(_ session: OutdoorSession)` DTO-Initialisierung um alle 13 neuen Felder erweitert

Neue Dateien:
- `Documentation/SQL/outdoor_sessions_ebike_migration.sql` — ALTER TABLE Statements fuer alle 13 neuen Spalten; Gesundheitsdaten-Spalten mit Kommentar versehen (waren bisher nur in anderen Tabellen)

Hinweis: `heartRate`, `maxHeartRate`, `bodyWeight` waren im SwiftData-Model `OutdoorSession` bereits vorhanden, im Supabase-DTO aber noch nicht — jetzt synchronisiert.

---

**30.03.2026 — Block 6 abgeschlossen**

Erledigte Schritte: 6.1, 6.2, 6.3

Neue Dateien:
- `MotionCore/Services/Calculation/OutdoorRecordCalcEngine.swift` — `OutdoorRecord` Struct + `OutdoorRecordCalcEngine`: totalDistance, totalElevationGain, tourCount, longestTour, fastestTour, highestElevationTour, mostCaloriesTour

Geaenderte Dateien:
- `MotionCore/Services/ViewModels/StatisticsViewModel.swift` — 5 neue gecachte Outdoor-KPI-Properties; `recalculate()` berechnet via `OutdoorRecordCalcEngine(sessions: calc.allOutdoorSessions)`
- `MotionCore/Views/Statistics/Workouts/View/StatisticView.swift` — neue `eBikeSection` computed property (4 `StatisticGridCard`s: Touren, Gesamtdistanz, Höhenmeter, Längste Tour); Section nur sichtbar wenn `viewModel.hasOutdoorSessions`

---

## Manual Verification

- [ ] Xcode Build nach jedem Block
- [ ] E-Bike Profil: Einstellungen -> Profil oeffnet, Werte speichern/laden
- [ ] Tour erfassen: "+" -> "E-Bike Tour" -> Formular -> Speichern -> SwiftData
- [ ] ListView: Outdoor-Filter, Card, Tap -> Detail, Swipe -> Loeschen
- [ ] Statistik: E-Bike Section mit KPIs (nur bei vorhandenen Touren)
- [ ] Supabase: Upload-Log in Console nach Tour-Erfassung
- [ ] Regression: Cardio/Kraft-Flows unveraendert
