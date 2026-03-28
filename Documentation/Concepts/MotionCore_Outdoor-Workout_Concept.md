# MotionCore — E-Bike Outdoor Feature (Phase 1)

> **ACHTUNG — Striktes Step-by-Step-Protokoll:**
> Jeder Schritt wird einzeln implementiert. Nach jedem Schritt muss Barto einen Build + kurzen App-Test durchführen. Erst nach explizitem **"Go für Schritt X"** darf der nächste Schritt begonnen werden. Keine parallelen Aufgaben. Kein Vorziehen von Schritten.

---

## Übersicht

Dieses Dokument beschreibt die Implementierung des E-Bike-Outdoor-Features in MotionCore (Phase 1). Umfang: E-Bike-Profil in den Einstellungen, manuelle Erfassung von E-Bike-Touren, ListView-Integration mit eigener Card, DetailView für abgeschlossene Touren und Basis-KPIs in der Statistik.

**Scope Phase 1:** Nur E-Bike (kein Laufen, Wandern etc.). Manuelle Erfassung. Vorbereitung für späteres Live-Tracking.

---

## Phasenübersicht (alle Phasen)

| Phase | Beschreibung | Status |
|-------|-------------|--------|
| **1** | E-Bike-Profil + manuelle Erfassung + ListView/Detail + NewWorkoutSheet + Basis-Stats | **Dieses Dokument** |
| **2** | ActiveOutdoorWorkoutView (Live-Tracking mit Timer, Pause, etc.) | Geplant |
| **3** | GPS-Tracking + Standortanzeige in Intervallen | Geplant |
| **4** | Outdoor-spezifische Records + Progressionsanalyse | Geplant |

---

## Performance-Richtlinien

Diese Regeln gelten für alle Schritte und müssen bei jeder Code-Änderung beachtet werden.

### ViewModel-Pattern (etabliert in MotionCore)

- **ViewModels sind `@Observable` (Swift Observation Framework)**, NICHT `@ObservableObject`.
- Berechnungen werden in `recalculate()`-Methoden gebündelt, getriggert über `.task {}` und `.onChange(of:)`.
- Gecachte Werte sind `private(set) var` — Views lesen nur, sie schreiben nie.
- Keine Neuberechnung bei jedem View-Render — nur bei echten Datenänderungen.

### SwiftUI-Performance

- **`@State` nur für UI-lokalen State** (Sheet-Toggles, Wheel-State, Alerts). Nie für berechnete Daten.
- **`@Query` mit gezielten Filtern** statt alle Daten laden und im View filtern. Wo möglich: `#Predicate` nutzen.
- **`LazyVStack` / `LazyVGrid`** für alle scrollbaren Listen — niemals `VStack` in `ScrollView` mit vielen Items.
- **Keine Neuberechnung in `body`**: Computed Properties in `body` werden bei jedem Re-Render aufgerufen. Teure Berechnungen gehören in CalcEngines, deren Ergebnis im ViewModel gecacht ist.
- **`@Bindable` nur auf `@Model`-Objekte**, nie auf ViewModels.
- **Kein redundantes `.onChange(of:)`**: Wenn drei `@Query`-Arrays die gleiche `recalculate()`-Methode triggern, sicherstellen, dass die Methode idempotent ist und keine O(n²)-Patterns enthält.

### CalcEngine-Performance

- CalcEngines sind **pure Structs** — kein State, keine Seiteneffekte, keine Referenzen auf SwiftData-Modelle außer den übergebenen Arrays.
- **Keine mehrfache Array-Iteration**: Wenn mehrere KPIs aus dem gleichen Array berechnet werden, in einem einzigen `reduce()`/`forEach()` erledigen oder cached lazy berechnen.
- **Zeitbasierte Filter** (Woche, Monat, Jahr) werden über die existierende `CoreSessionCalcEngine`-Infrastruktur delegiert — nicht jede CalcEngine filtert selbst.

### SwiftData / CloudKit

- Alle neuen `@Model`-Properties **müssen** einen Default-Wert haben oder optional sein.
- **Keine eager Fetches** in Views: `@Query` mit `#Predicate` oder `FetchDescriptor` mit Limits.
- Neue Models müssen im `appSchema` in `MotionCoreApp.swift` registriert werden — **sonst Runtime-Crash**.
- Nach Inserts: `try? context.save()` sofort aufrufen — kein „save at end of method".

### Supabase

- DTO-Properties werden **synchron vor dem ersten `await`** aus SwiftData-Objekten kopiert (Thread-Safety).
- Uploads laufen in `Task {}` — Fehler werden geloggt, nicht weitergereicht (sekundäre Persistenz).

---

## Build-sichere Implementierungsreihenfolge

Jeder Schritt erzeugt einen grünen Build. Kein Schritt referenziert Typen oder Views, die erst in einem späteren Schritt erstellt werden.

---

## Schritt 1: E-Bike Enums und Typen

**Ziel:** Neue Enums für das E-Bike-Profil. Reine Typ-Definitionen ohne Abhängigkeiten.

**Neue Datei:** `EBikeProfileTypes.swift`

**Build-Impakt:** Keine. Isolierte Typ-Definitionen.

```swift
import Foundation
import SwiftUI

// MARK: - Fahrradtyp

enum BikeType: String, Codable, CaseIterable, Identifiable {
    case eBikeTrekking
    case eBikeCity
    case eBikeMountain
    case eBikeRoad
    case eBikeCargo

    var id: Self { self }

    var description: String {
        switch self {
        case .eBikeTrekking:  return "E-Trekking"
        case .eBikeCity:      return "E-City"
        case .eBikeMountain:  return "E-Mountainbike"
        case .eBikeRoad:      return "E-Rennrad"
        case .eBikeCargo:     return "E-Lastenrad"
        }
    }

    var icon: String {
        switch self {
        case .eBikeTrekking:  return "figure.outdoor.cycle"
        case .eBikeCity:      return "bicycle"
        case .eBikeMountain:  return "mountain.2"
        case .eBikeRoad:      return "road.lanes"
        case .eBikeCargo:     return "shippingbox"
        }
    }
}

// MARK: - Zustand des Fahrrads

enum BikeCondition: Int, Codable, CaseIterable, Identifiable {
    case excellent = 5
    case good = 4
    case fair = 3
    case needsService = 2
    case poor = 1

    var id: Self { self }

    var description: String {
        switch self {
        case .excellent:    return "Hervorragend"
        case .good:         return "Gut"
        case .fair:         return "Befriedigend"
        case .needsService: return "Wartung nötig"
        case .poor:         return "Schlecht"
        }
    }

    var color: Color {
        switch self {
        case .excellent:    return .green
        case .good:         return .blue
        case .fair:         return .yellow
        case .needsService: return .orange
        case .poor:         return .red
        }
    }
}

// MARK: - Reifengröße

enum TireSize: String, Codable, CaseIterable, Identifiable {
    case t26 = "26\""
    case t275 = "27.5\""
    case t28 = "28\""
    case t29 = "29\""

    var id: Self { self }
    var description: String { rawValue }
}
```

**Buildtest:** App kompiliert. Keine sichtbaren Änderungen in der UI.

---

## Schritt 2: E-Bike Profile SwiftData-Model + Schema-Registrierung

**Ziel:** Das `@Model` für das E-Bike-Profil erstellen UND im ModelContainer registrieren.

**Neue Datei:** `EBikeProfile.swift`

**Geänderte Datei:** `MotionCoreApp.swift` — `appSchema` erweitern

**Build-Impakt:** Schema-Änderung. Beim ersten Start wird das neue Model zur Datenbank addiert. Bestehende Daten bleiben unberührt.

**EBikeProfile.swift** — vollständiges Model mit Initializer, typisierten Enum-Properties, berechneten Werten (Alter, Wartungsstatus). Alle Properties haben Defaults. Keine Relationships.

**MotionCoreApp.swift** — `EBikeProfile.self` zum `appSchema`-Array hinzufügen.

**Buildtest:** App startet. Einstellungen und bestehende Workouts funktionieren. E-Bike-Profil noch nicht in UI sichtbar.

---

## Schritt 3: OutdoorTypes erweitern (eBike-Case + WeatherCondition UI-Texte)

**Ziel:** `OutdoorActivity` um `.eBike` erweitern. `WeatherCondition` bekommt `description`-, `icon`- und `Identifiable`-Conformance.

**Geänderte Datei:** `OutdoorTypes.swift` — komplett ersetzen

**Build-Impakt:** Neuer Enum-Case. Bestehende rawValue-Mappings (`OutdoorActivity(rawValue:)`) bleiben kompatibel. `WeatherCondition` bekommt `Identifiable`-Conformance.

Erweiterungen:
- `OutdoorActivity`: neuer Case `.eBike` mit `description`, `icon`, `tint: Color`
- `WeatherCondition`: `Identifiable`-Conformance, `description`, `icon`

**Achtung:** `import SwiftUI` nötig für `Color` im `tint`-Property.

**Buildtest:** App kompiliert. Bestehende Outdoor-Funktionalität (Export/Import, Supabase) arbeitet korrekt.

---

## Schritt 4: OutdoorSession erweitern (neue Properties)

**Ziel:** GPS-Koordinaten, strukturierte Adressfelder und E-Bike-Profil-UUID.

**Geänderte Datei:** `OutdoorSession.swift`

**Build-Impakt:** Schema-Migration (nur Addition). CloudKit-kompatibel. Bestehender Initializer bleibt unverändert — alle neuen Properties haben Defaults.

Neue Properties (alle optional/mit Default):
- `startLatitude: Double?`, `startLongitude: Double?`, `endLatitude: Double?`, `endLongitude: Double?`
- `startStreet: String = ""`, `startPostalCode: String = ""`, `startCity: String = ""`
- `endStreet: String = ""`, `endPostalCode: String = ""`, `endCity: String = ""`
- `eBikeProfileUUID: UUID? = nil`

**Bestehende `startLocation`/`endLocation` (String) bleiben erhalten** — werden beim Speichern als Zusammenfassung der strukturierten Felder befüllt.

**Buildtest:** App startet. Bestehende OutdoorSessions bekommen automatisch Default-Werte.

---

## Schritt 5: E-Bike Profil-View + Einstellungs-Navigation

**Ziel:** Settings-View zum Pflegen des E-Bike-Profils. Navigation über MainSettingsView.

**Neue Datei:** `EBikeProfileView.swift`

**Geänderte Datei:** `MainSettingsView.swift`

**Build-Impakt:** Neue View mit Navigation. Keine bestehende Funktionalität betroffen.

EBikeProfileView — List-basiert (konsistent mit UserSettingsView, WorkoutSettingsView):
- Section 1: Stammdaten (Name, Typ, Rahmengröße, Gewicht, Akkukapazität, Reifengröße)
- Section 2: Zustand & Wartung (Zustand-Picker farbig, Kilometerstand, Kaufdatum/Alter, Wartungsintervall, letzte Wartung, Wartungshinweis-Banner)
- Section 3: Notizen

**Performance-Hinweis:** Lazy-Create für Profil — nur beim allerersten Zugriff wird ein `EBikeProfile`-Objekt angelegt. `@Query` liefert das bestehende Profil. `Bindable(profile)` für direkte Two-Way-Bindings auf das `@Model`. Auto-Save `.onDisappear`.

MainSettingsView — NavigationLink mit Label "E-Bike Profil" + `bicycle`-Icon in Section "Allgemeine Einstellungen".

**Buildtest:** Einstellungen → "E-Bike Profil" öffnet die neue View. Felder bearbeitbar. Beim Zurücknavigieren wird gespeichert.

---

## Schritt 6: LocationHelper für GPS-Abfrage

**Ziel:** CLLocationManager-Wrapper für einmalige Standortabfrage + Reverse Geocoding.

**Neue Datei:** `LocationHelper.swift`

**Build-Impakt:** Keine UI-Änderung. Erfordert `NSLocationWhenInUseUsageDescription` in Info.plist.

LocationHelper — `@MainActor`, Singleton, `CLLocationManagerDelegate`:
- `requestCurrentLocation() async -> CLLocation?` — einmalig, mit Authorization-Check
- `reverseGeocode(location:) async -> CLPlacemark?` — Koordinaten → Adresse
- Continuation-basiert (kein Delegate-Spaghetti)

**Info.plist prüfen/ergänzen:**
```
NSLocationWhenInUseUsageDescription = "MotionCore benötigt deinen Standort, um Start- und Zielorte deiner Touren zu erfassen."
```

**Buildtest:** App kompiliert. Keine sichtbaren Änderungen.

---

## Schritt 7: OutdoorFormSections (wiederverwendbare Form-Sections)

**Ziel:** Alle Eingabe-Sections für die Outdoor-Erfassung. Inkl. `OutdoorFocusedField`-Enum.

**Neue Datei:** `OutdoorFormSections.swift`

**Build-Impakt:** Keine. Isolierte View-Komponenten, noch nicht eingebunden.

Enthält:
- `OutdoorFocusedField` Enum
- `OutdoorRouteNameSection`
- `OutdoorAddressSection` (mit GPS-Button + Reverse Geocoding über LocationHelper)
- `OutdoorWeatherSection`
- `OutdoorDurationSection` (Wheel-basiert)
- `OutdoorDistanceSection`, `OutdoorElevationSection`, `OutdoorSpeedSection`
- `OutdoorCaloriesSection`, `OutdoorHeartRateSection`, `OutdoorBodyWeightSection`
- `OutdoorRPESection` (Picker 1-10), `OutdoorEnergySection` (Picker 1-5)

**Buildtest:** App kompiliert. Keine sichtbaren Änderungen.

---

## Schritt 8: OutdoorFormView (manuelle Erfassung)

**Ziel:** Vollständige Erfassungs-View für E-Bike-Touren.

**Neue Datei:** `OutdoorFormView.swift`

**Build-Impakt:** Neue View, noch nicht per Navigation erreichbar.

OutdoorFormView — Pattern identisch mit FormView (Cardio):
- `@Bindable var session: OutdoorSession`, `mode: FormMode`
- 4 GlassCards: Route, Leistungsdaten, Bewertung, Notizen
- `AnimatedBackground` + `ScrollView` + `.glassCard()`
- Toolbar: Speichern (checkmark) + Löschen (trash, nur Edit-Modus)

Speicher-Logik:
1. `startLocation`/`endLocation` als Zusammenfassung aus strukturierten Feldern generieren
2. `outdoorActivity = .eBike` setzen
3. `isCompleted = true`, `isLiveSession = false`
4. Supabase-Upload (gleicher Pattern wie FormView)
5. E-Bike Kilometerstand aktualisieren (Profile-Query über `eBikeProfileUUID`)

**Performance-Hinweis:** Die FetchDescriptor-Query für das E-Bike-Profil in `updateBikeKilometers()` läuft nur einmal beim Speichern — nicht bei jedem Render.

**Buildtest:** App kompiliert. View noch nicht erreichbar — isolierter Build-Test.

---

## Schritt 9: NewWorkoutSheet + BaseView (Navigation aktivieren)

**Ziel:** Outdoor-Button aktivieren. BaseView bekommt Sheet-Logik für OutdoorFormView.

**Geänderte Dateien:** `NewWorkoutSheet.swift`, `BaseView.swift`

**Build-Impakt:** Der Outdoor-Button wird klickbar. OutdoorFormView öffnet sich als Sheet.

NewWorkoutSheet:
- Titel → "E-Bike Tour", Subtitle → "E-Bike Tour erfassen", Color → `.green`, `isDisabled: false`

BaseView:
- Neue States: `@State private var showingAddOutdoor = false`, `@State private var outdoorDraft = OutdoorSession()`
- `onOutdoorSelected`: Sheet nach 0.3s Delay öffnen
- Neues `.sheet(isPresented: $showingAddOutdoor)` mit OutdoorFormView
- `.onDisappear`: Draft zurücksetzen

**Buildtest:** "+" → "E-Bike Tour" → OutdoorFormView öffnet sich. Felder befüllbar. Speichern funktioniert. Bestehende Cardio/Kraft-Flows unverändert.

---

## Schritt 10: OutdoorSessionCard (ListView-Card)

**Ziel:** Card-Darstellung für OutdoorSessions.

**Neue Datei:** `OutdoorSessionCard.swift`

**Build-Impakt:** Keine. Card wird noch nicht in ListView referenziert.

OutdoorSessionCard:
- Header: Aktivitäts-Icon + Datum + Routenname + Wetter-Icon
- Metriken-Zeile: Dauer, Distanz, Höhenmeter, Geschwindigkeit (als `OutdoorMetricBadge`)
- Route-Zeile: Mappin-Icon + "Start → Ziel" (wenn vorhanden)
- `.glassCard()`

**Buildtest:** App kompiliert. Keine sichtbare UI-Änderung.

---

## Schritt 11: OutdoorDetailView

**Ziel:** Detailansicht für abgeschlossene E-Bike-Touren.

**Neue Datei:** `OutdoorDetailView.swift`

**Build-Impakt:** Keine. Noch nicht per Navigation erreichbar.

OutdoorDetailView — 4 Cards + Aktionen:
1. **Route & Wetter:** Datum, Aktivitäts-Icon, Route, Start/Ziel, Wetter, Temperatur
2. **Leistungsdaten:** 2x3 Grid mit StatBubble (Dauer, Distanz, Höhenmeter, Tempo, Kalorien, Herzfrequenz)
3. **Bewertung:** RPE, Energielevel, Intensität (nur wenn vorhanden)
4. **Notizen:** (nur wenn vorhanden)
5. **Aktionen:** "Tour bearbeiten" (→ OutdoorFormView edit), "Tour löschen" (mit Alert)

**Buildtest:** App kompiliert. Keine sichtbare UI-Änderung.

---

## Schritt 12: ListView-Integration (Outdoor-Filter + Card + Navigation)

**Ziel:** OutdoorSessions in der Workout-Liste anzeigen.

**Geänderte Datei:** `ListView.swift`

**Build-Impakt:** ListView zeigt jetzt Outdoor-Touren. Alle bestehenden Funktionen bleiben unverändert.

Änderungen:
1. `WorkoutTypeFilter` um `.outdoor` erweitern (inkl. Icon)
2. `@Query` für `OutdoorSession` hinzufügen + `filteredOutdoorWorkouts` computed property
3. `MixedWorkoutItem` um `.outdoor(OutdoorSession)` Case erweitern
4. `isListEmpty` um Outdoor prüfen
5. `completedWorkoutsSection`: neuer `.outdoor` Case mit `OutdoorDetailView` Navigation
6. `createMixedWorkoutList()`: Outdoor-Sessions hinzufügen
7. `mixedWorkoutsList`: neuer `.outdoor` Case
8. `deleteOutdoorSession(_:)` Hilfsfunktion

**Performance-Hinweis:** `filteredOutdoorWorkouts` ist ein computed property. Bei vielen Sessions könnte das teuer werden. In Phase 2 evaluieren ob `#Predicate` in der `@Query` sinnvoller ist. Für Phase 1 (wenige Sessions) ist das OK.

**Buildtest:** Workouts-Tab → "Outdoor"-Filter sichtbar. Erfasste Touren erscheinen. Tap → Detail. Swipe → Löschen.

---

## Schritt 13: Outdoor-Statistik (Basis-KPIs)

**Ziel:** OutdoorRecordCalcEngine + Integration in Statistik.

**Neue Datei:** `OutdoorRecordCalcEngine.swift`

**Geänderte Dateien:** `StatisticCalcEngine.swift`, `StatisticsViewModel.swift`, `StatisticView.swift`

**Build-Impakt:** Neue Outdoor-Section in der Statistik (nur sichtbar wenn Outdoor-Touren existieren).

OutdoorRecordCalcEngine — pure Struct:
- `totalDistance`, `totalElevationGain`, `longestTour`, `fastestTour`, `highestElevationTour`
- Zeitbasierte Filter über `CoreSessionCalcEngine`

StatisticCalcEngine — neue Properties:
- `outdoorTotalDistance`, `outdoorTotalElevation`, `outdoorLongestTourDistance`

StatisticsViewModel — neue gecachte Properties:
- `outdoorTotalDistance`, `outdoorTotalElevation`, `outdoorLongestTourDistance`, `allOutdoorSessions`
- In `recalculate()` befüllen

StatisticView — neue Section "E-Bike":
- 3 KPI-Cards: Gesamtdistanz, Gesamt-Höhenmeter, Längste Tour
- Nur angezeigt wenn `!viewModel.allOutdoorSessions.isEmpty`

**Performance-Hinweis:** `outdoorRecordCalc` ist computed in StatisticCalcEngine — wird nur berechnet wenn aufgerufen. Teure Aggregation passiert einmal in `recalculate()`, Ergebnis gecacht im ViewModel.

**Buildtest:** Statistik-Tab zeigt "E-Bike"-Section nach Erfassen einer Tour. Ohne Touren: alles wie vorher.

---

## Schritt 14: Supabase Schema-Erweiterung

**Ziel:** DTO um neue Felder erweitern. Supabase-Tabelle erweitern. Neue Tabelle anlegen.

**Geänderte Dateien:** `SupabaseSessionModels.swift`, `SupabaseSessionService.swift`

**Supabase-Aktionen (via Claude Code + Supabase MCP):**

14a: SQL-Migration — `outdoor_sessions` um GPS-, Adress-, und Gesundheitsfelder erweitern

14b: Neue Tabelle `ebike_profiles` anlegen

14c: `SupabaseOutdoorSessionDTO` erweitern (GPS, Adresse, E-Bike-UUID, heartRate, maxHeartRate, bodyWeight)

14d: Upload-Methode `SupabaseSessionService.upload(_ session: OutdoorSession)` an neues DTO anpassen

**Build-Impakt:** Nur interne Änderung an DTOs. Kein UI-Impakt.

**Buildtest:** Tour erfassen → Console prüfen: "✅ OutdoorSession ... hochgeladen". In Supabase Dashboard verifizieren.

---

## Zusammenfassung: Alle Dateien

### Neue Dateien (9)

| Nr. | Datei | Schritt |
|-----|-------|---------|
| 1 | `EBikeProfileTypes.swift` | 1 |
| 2 | `EBikeProfile.swift` | 2 |
| 3 | `EBikeProfileView.swift` | 5 |
| 4 | `LocationHelper.swift` | 6 |
| 5 | `OutdoorFormSections.swift` | 7 |
| 6 | `OutdoorFormView.swift` | 8 |
| 7 | `OutdoorSessionCard.swift` | 10 |
| 8 | `OutdoorDetailView.swift` | 11 |
| 9 | `OutdoorRecordCalcEngine.swift` | 13 |

### Geänderte Dateien (10)

| Datei | Schritt |
|-------|---------|
| `MotionCoreApp.swift` | 2 |
| `OutdoorTypes.swift` | 3 |
| `OutdoorSession.swift` | 4 |
| `MainSettingsView.swift` | 5 |
| `NewWorkoutSheet.swift` | 9 |
| `BaseView.swift` | 9 |
| `ListView.swift` | 12 |
| `StatisticCalcEngine.swift` | 13 |
| `StatisticsViewModel.swift` | 13 |
| `StatisticView.swift` | 13 |
| `SupabaseSessionModels.swift` | 14 |
| `SupabaseSessionService.swift` | 14 |

---

## Vorbereitung auf Phase 2 (Live-Tracking)

Was durch Phase 1 bereits vorbereitet ist:

- `OutdoorSession` hat `start()`, `complete()`, `isLiveSession`, `startedAt`, `completedAt`
- `SessionResumeState` unterstützt `workoutType: .outdoor`
- `BaseView.restoreOutdoorSession()` ist als TODO markiert
- `ActiveSessionManager` ist generisch genug für Outdoor
- GPS-Koordinaten-Felder existieren im Model
- `LocationHelper` kann für kontinuierliches Tracking erweitert werden

---

## Design-Konsistenz (Checkliste)

- [ ] Alle Cards verwenden `.glassCard()`
- [ ] Hintergrund immer `AnimatedBackground(showAnimatedBlob:)`
- [ ] Empty States über `EmptyState()`
- [ ] Toolbar-Buttons über `IconType().glassButton()`
- [ ] Glassmorphism / Liquid Glass Design-System
- [ ] Deutsche Kommentare, englische Variablen-/Methodennamen
- [ ] Production Code only (kein Test-Scaffolding)
- [ ] Max 400 Zeilen pro Datei (Warnung ab 600)
