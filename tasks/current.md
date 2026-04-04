# Lokale Exercise- & Equipment-Datenbank (Supabase-Ablösung)

**Complexity:** Large

## Summary

Verlagerung der Exercise-, Equipment- und Muskelgruppen-Datenbank von Supabase-RPCs in gebündelte JSON-Dateien im App-Bundle. Die App funktioniert danach vollständig offline (außer MP4-Streaming). Supabase bleibt nur für Backups, Session-History und Media-Hosting (MP4/Poster). Die Umsetzung erfolgt in 5 sequenziellen Blöcken mit harten Stopps dazwischen.

## Scope

**Enthalten:**
- Block A: Equipment und Muskelgruppen als lokale JSON + Services
- Block B: 1.200 Exercises als gebündelte JSON + Seeder mit Upsert-Logik
- Block C: Lokale SwiftData-Suche und Filter (ersetzt Supabase RPC-Suche)
- Block D: MP4/Poster Video-Cache mit LRU-Bereinigung
- Block E: Aufräumen obsoleter Supabase-Dateien

**Explizit ausgeschlossen:**
- Änderungen an `ActiveWorkoutView.swift` (2000 Zeilen, keine Berührung)
- Änderungen am SwiftData-Schema von `Exercise` (kein Modell-Umbau)
- Supabase-Backend-Änderungen (nur clientseitige Umstellung)
- Pre-Caching in `ActiveWorkoutView` (Block D3 im Konzept ist optional, wird übersprungen)

## UX Placement

- **ExerciseListView**: Der Lupen-Button (API-Suche) wird durch `LocalExerciseSearchView` ersetzt — gleiche Position, gleiche UX, aber lokale Suche statt Supabase-RPC
- **ExerciseFilterSheet**: Gleiche UI, aber Daten kommen aus Bundle-JSON statt Supabase-RPC
- **ExerciseVideoView**: Gleiche UI, aber mit Cache-Layer dazwischen
- **DataSettingsView**: Label-Änderung "Supabase Übungen" → "System-Übungen"
- **ExerciseAPIView**: Header-Text "API-Informationen" → "Übungsdaten"
- **Rationale**: User merkt keinen funktionalen Unterschied, außer dass alles sofort und offline funktioniert
- **Abgelehnte Alternative**: Einen zentralen `BundledFilterService` als `ObservableObject`/`EnvironmentObject` erstellen — unnötige Komplexität, da statische Methoden ausreichen

## Affected Files

### Block A — Equipment & Muskeln lokalisieren

| Datei | Aktion | Zweck |
|---|---|---|
| `MotionCore/Services/Database/Local/BundledEquipment.swift` | NEU | `BundledEquipmentItem` Modell + `BundledEquipmentService` (statisch, lädt aus `equipment_seed.json`) |
| `MotionCore/Services/Database/Local/BundledMuscles.swift` | NEU | `BundledMuscleItem` Modell + `BundledMusclesService` (statisch, lädt aus `muscles_seed.json`) |
| `MotionCore/Services/Database/Local/BundledMusclesHierarchy.swift` | NEU | `BundledMusclesHierarchy` Struct + `grouped()` Extension |
| `equipment_seed.json` | NEU (Bundle) | ~20 Equipment-Items im snake_case-Format |
| `muscles_seed.json` | NEU (Bundle) | ~50 MuscleGroup-Items (Level 1 + Level 2) im snake_case-Format |
| `MotionCore/Views/Training/Exercises/View/ExerciseFilterSheet.swift` | ÄNDERN | Typen von `SupabaseEquipment`/`SupabaseMuscles` auf `BundledEquipmentItem`/`BundledMuscleItem` umstellen; `SupabaseFilterService` EnvironmentObject entfernen |
| `MotionCore/Views/Training/Exercises/View/ExerciseSearchView.swift` | ÄNDERN | Filter-Binding-Typen temporär anpassen (wird in Block C komplett ersetzt) |
| `MotionCore/App/MotionCoreApp.swift` | ÄNDERN | `@StateObject filterService` und `.environmentObject(filterService)` entfernen |

### Block B — Exercises bundlen & Seeder

| Datei | Aktion | Zweck |
|---|---|---|
| `exercises_seed.json` | NEU (Bundle) | ~1.200 Exercises im `SupabaseExercise` snake_case-Format (MANUELLER EXPORT durch User) |
| `MotionCore/Services/Database/Local/BundledExerciseSeeder.swift` | NEU | Versions-basiertes Seeding, Upsert-Logik, User-Daten schützen |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseExerciseModels.swift` | ÄNDERN | Explizite `CodingKeys` hinzufügen (snake_case-Mapping) |
| `MotionCore/App/MotionCoreApp.swift` | ÄNDERN | `.task {}` Modifier mit `BundledExerciseSeeder.seedIfNeeded()` hinzufügen |

### Block C — Lokale Suche & Filter

| Datei | Aktion | Zweck |
|---|---|---|
| `MotionCore/Views/Training/Exercises/View/LocalExerciseSearchView.swift` | NEU | SwiftData-basierte Suche mit `FetchDescriptor` + `#Predicate`, lokale Filter |
| `MotionCore/Views/Training/Exercises/View/ExerciseListView.swift` | ÄNDERN | Sheet-Aufruf von `ExerciseSearchView()` auf `LocalExerciseSearchView()` umstellen |
| `MotionCore/Views/Training/Exercises/Sheets/ExercisePickerSheet.swift` | PRÜFEN | Nutzt eigene `@Query`-Filterung — wahrscheinlich keine Änderung nötig |

### Block D — MP4 Video-Cache

| Datei | Aktion | Zweck |
|---|---|---|
| `MotionCore/Services/Media/VideoCacheService.swift` | NEU | `actor`-basierter Cache für Videos (500 MB LRU) und Poster (50 MB LRU) |
| `MotionCore/Components/Media/ExerciseVideoView.swift` | ÄNDERN | Cache-First Logik: Lokales Asset → Cache → Remote |

### Block E — Aufräumen

| Datei | Aktion | Zweck |
|---|---|---|
| `MotionCore/Services/Database/Remote/Config/SupabaseFilterService.swift` | ENTFERNEN | Ersetzt durch `BundledEquipmentService` + `BundledMusclesService` |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseEquipment.swift` | ENTFERNEN | Ersetzt durch `BundledEquipmentItem` |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseMuscles.swift` | ENTFERNEN | Ersetzt durch `BundledMuscleItem` |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseMusclesHierarchy.swift` | ENTFERNEN | Ersetzt durch `BundledMusclesHierarchy` |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseExerciseSearchResult.swift` | ENTFERNEN | Nicht mehr genutzt |
| `MotionCore/Views/Training/Exercises/View/ExerciseSearchView.swift` | ENTFERNEN | Ersetzt durch `LocalExerciseSearchView` |
| `MotionCore/Views/Training/Exercises/View/ExerciseSearchDetailView.swift` | ENTFERNEN | Nur von `ExerciseSearchView` genutzt, wird obsolet |
| `MotionCore/Services/Database/Remote/Import/ExerciseImportResult.swift` | ENTFERNEN | Nirgendwo referenziert |
| `MotionCore/Services/Database/Remote/Import/ExerciseImportManager.swift` | ÄNDERN | Batch-Import-Methoden entfernen; `deleteExercise`, `exerciseExists`, `getImportStatistics`, `enrichWithDetailedMuscles` behalten |
| `MotionCore/Services/Database/Remote/Exercise/SupabaseExerciseService.swift` | ÄNDERN | Search/Filter-Methoden entfernen; `fetchAllExercises` behalten |
| `MotionCore/Views/Settings/View/DataSettingsView.swift` | ÄNDERN | Label "Supabase Übungen" → "System-Übungen (Bundle)" |
| `MotionCore/Views/Training/Exercises/Components/ExerciseAPIView.swift` | ÄNDERN | Header "API-Informationen" → "Übungsdaten"; Icon `cloud.fill` → `info.circle.fill` |

## Risks

### Technische Risiken
- **CodingKeys + SupabaseClient Decoder**: Der `SupabaseClient.makeDecoder()` nutzt `.convertFromSnakeCase`. Explizite CodingKeys haben Vorrang — sollte kompatibel sein. Nach B1 explizit testen.
- **Erster Seed-Lauf bei 1.200 Exercises**: Kann 2–5 Sekunden dauern. Läuft in `.task {}` (async), blockiert die UI nicht.
- **SwiftData `#Predicate` für Array-Contains**: Level-1-Muskelgruppenfilter erfordert clientseitiges Filtern (OR über dynamische Arrays nicht in `#Predicate` unterstützt). Bei 1.200 Exercises performant genug.

### Datenmodell / CloudKit Risiken
- **Keine Schema-Änderung**: Es werden keine SwiftData-Modelle geändert, nur Datenquellen.
- **User-Daten Schutz**: Die Upsert-Logik im `BundledExerciseSeeder` darf NIEMALS `isFavorite`, `isCustom`, `isArchived`, `repRangeMin`, `repRangeMax`, `progressionStep`, `targetRIR`, `sets`, oder andere User-Felder überschreiben.

### Regressions-Risiken
- **ExerciseListView Löschen-Funktion**: Nutzt `ExerciseImportManager.deleteExercise()` — diese Methode bleibt erhalten.
- **SupabaseClient/Config/SessionService/BackupService**: Bleiben komplett unverändert.

## Implementation Steps

### BLOCK A — Equipment & Muskeln lokalisieren

- [x] **A0 (User, MANUELLER SCHRITT):** `equipment_seed.json` und `muscles_seed.json` manuell aus Supabase exportieren. Format: snake_case-Keys identisch zu `SupabaseEquipment` bzw. `SupabaseMuscles`.

- [x] **A1:** Verzeichnis `MotionCore/Services/Database/Local/` erstellen.

- [x] **A2:** `BundledEquipment.swift` erstellen in `Services/Database/Local/`:
  - `BundledEquipmentItem` Struct (Codable, Identifiable, Hashable) mit CodingKeys für snake_case
  - `BundledEquipmentService` Struct mit `static func loadAll() -> [BundledEquipmentItem]` und `static func find(identifier:in:)`
  - JSON aus Bundle laden, sortiert nach `displayOrder`

- [x] **A3:** ~~`BundledMuscles.swift` erstellen~~ — **OBSOLET** (`BundledMuscles.swift` und `BundledMusclesHierarchy.swift` werden NICHT benötigt — `MuscleGroup`/`DetailedMuscle` Enums aus `StrengthTypes.swift` werden direkt verwendet. `muscles_seed.json` wird ebenfalls nicht benötigt.)

- [x] **A4:** ~~`BundledMusclesHierarchy.swift` erstellen~~ — **OBSOLET** (siehe A3)

- [x] **A5:** `equipment_seed.json` und `muscles_seed.json` ins App-Bundle legen (Xcode Target → Build Phases → Copy Bundle Resources).

- [x] **A6:** `ExerciseFilterSheet.swift` umbauen:
  - `@EnvironmentObject private var filterService: SupabaseFilterService` entfernen
  - Binding-Typen: `SupabaseEquipment?` → `BundledEquipmentItem?`, `SupabaseMuscles?` → `BundledMuscleItem?`
  - Equipment- und Muscle-Listen als Parameter durchreichen
  - `EquipmentButton`, `MuscleGroupRow`, `SubgroupButton` Structs anpassen
  - `isLoading`-Checks entfernen (Bundle-Daten sind sofort verfügbar)

- [x] **A7:** `ExerciseSearchView.swift` temporär anpassen:
  - Filter-Binding-Typen auf `BundledEquipmentItem?` / `BundledMuscleItem?` ändern
  - `filterService` EnvironmentObject entfernen
  - Equipment/Muscle-Daten lokal laden und an `ExerciseFilterSheet` durchreichen
  - Supabase-RPC-Suche (`executeSearch`) bleibt temporär — wird in Block C ersetzt

- [x] **A8:** `MotionCoreApp.swift` anpassen:
  - `@StateObject private var filterService = SupabaseFilterService.shared` entfernen
  - `.environmentObject(filterService)` entfernen

- [x] **A9 (STOPP):** Xcode Build (`Cmd+B`). App muss kompilieren. `ExerciseFilterSheet` muss Equipment und Muskelgruppen aus dem Bundle anzeigen.

### BLOCK B — Exercises bundlen & Seeder umbauen

- [ ] **B0 (User, MANUELLER SCHRITT):** JSON-Export der Exercise-Datenbank. Der User führt `SupabaseExerciseService.shared.fetchAllExercises()` aus (z.B. über ein temporäres Debug-UI oder Supabase Dashboard SQL) und speichert das Ergebnis als `exercises_seed.json`. Format: snake_case-Keys identisch zum `SupabaseExercise`-Format. Dieser Schritt kann NICHT vom Developer automatisiert werden.

- [x] **B1:** `SupabaseExerciseModels.swift` erweitern:
  - `Decodable` → `Codable` ändern
  - Explizite `CodingKeys` hinzufügen: `exerciseDbId = "exercise_db_id"`, `forceType = "force_type"`, `mechanicType = "mechanic_type"`, `videoPath = "video_path"`, `posterPath = "poster_path"`, `thumbnailUrl = "thumbnail_url"`, `isVerified = "is_verified"`, `isArchived = "is_archived"`, `createdAt = "created_at"`, `updatedAt = "updated_at"`, `primaryMuscles = "primary_muscles"`, `secondaryMuscles = "secondary_muscles"`
  - ACHTUNG: Nach dieser Änderung testen ob `fetchAllExercises()` via Supabase weiterhin korrekt dekodiert

- [x] **B2:** `exercises_seed.json` ins App-Bundle legen (Xcode Target → Build Phases → Copy Bundle Resources).

- [x] **B3:** `BundledExerciseSeeder.swift` erstellen in `Services/Database/Local/`:
  - `static let seedVersionKey = "bundledExerciseSeedVersion"`
  - `static let currentSeedVersion: Int = 1` (manuell erhöhen bei neuer `exercises_seed.json`, NICHT `CFBundleVersion`)
  - `static func seedIfNeeded(context:) async` — Version prüfen, Seed ausführen falls nötig
  - `private static func performSeed(context:) async throws` — JSON laden, als `[SupabaseExercise]` dekodieren (eigener Decoder mit `.iso8601` DateStrategy, OHNE `.convertFromSnakeCase`), bestehende Exercises per `apiID` laden, Upsert in 50er-Batches
  - `private static func updateExercise(_:from:) -> Bool` — NUR Seed-Felder aktualisieren: `name`, `instructions`, `exerciseDescription` (tips), `videoPath`, `posterPath`, `detailedPrimaryMuscles`, `detailedSecondaryMuscles`, `equipment`, `difficulty`, `category`. NIEMALS User-Felder berühren.
  - Bestehende Typen wiederverwenden: `Exercise(from: SupabaseExercise)`, `MuscleGroupMapper.mapDetailed(supabaseValue:)`, `ExerciseEquipment.fromSupabase()`, `ExerciseDifficulty.fromSupabase()`, `ExerciseCategory.fromSupabase()`

- [x] **B4:** `MotionCoreApp.swift` erweitern:
  - `.task {}` Modifier an `BaseView()` anhängen
  - `ExerciseSeeder.seedIfNeeded(context: modelContext)` zuerst (handgepflegte Übungen)
  - `await BundledExerciseSeeder.seedIfNeeded(context: modelContext)` danach (apiID-basierte Duplikat-Erkennung)
  - `@Environment(\.modelContext) private var modelContext` hinzufügen — alternativ `sharedModelContainer.mainContext` nutzen falls nötig

- [x] **B5 (STOPP):** Xcode Build (`Cmd+B`). App starten im Simulator. Alle ~1.200 Exercises in `ExerciseListView` sichtbar? Zweiter Start: kein Re-Seed (Console prüfen).

### BLOCK C — Lokale Suche & Filter

- [x] **C1:** `LocalExerciseSearchView.swift` erstellen in `Views/Training/Exercises/View/`:
  - `@State private var searchText = ""`
  - `@State private var selectedEquipment: BundledEquipmentItem?`
  - `@State private var selectedPrimaryMuscle: BundledMuscleItem?`
  - `@State private var selectedSubMuscle: BundledMuscleItem?`
  - Equipment/Muscle-Listen über `BundledEquipmentService.loadAll()` / `BundledMusclesService.loadAll()` laden
  - Suchlogik: `FetchDescriptor<Exercise>` mit `#Predicate { exercise.name.localizedStandardContains(searchTerm) }`
  - Equipment-Filter: `exercise.equipmentRaw == selectedEquipment.identifier`
  - Muskelgruppen-Filter Level 2: `exercise.detailedPrimaryMusclesRaw.contains(identifier)`
  - Muskelgruppen-Filter Level 1: Alle `DetailedMuscle`-Cases mit passendem `parentGroup` sammeln, clientseitig filtern
  - `fetchLimit = 50` für Performance
  - Ergebnisliste zeigt `Exercise`-Objekte direkt (kein DTO, kein Import-Button)
  - Callback-Pattern: `var onSelect: (Exercise) -> Void` — Aufrufer entscheidet was passiert (Navigation oder Picker)
  - In `ExerciseListView`: `onSelect` → NavigationLink zu `ExerciseFormView(mode: .edit)` oder Detail-View
  - Filter-Sheet über angepasstes `ExerciseFilterSheet` einbinden
  - UI: `AnimatedBackground`, `EmptyState`, Suchleiste analog zur bestehenden View

- [x] **C2:** `ExerciseListView.swift` anpassen:
  - Sheet-Aufruf von `ExerciseSearchView()` auf `LocalExerciseSearchView()` umstellen

- [x] **C3:** `ExercisePickerSheet.swift` prüfen — nutzt eigene `@Query`-basierte Filterung, keine Referenzen auf Supabase-Typen → unverändert.

- [ ] **C4 (STOPP):** Xcode Build (`Cmd+B`). `LocalExerciseSearchView` im Simulator testen: Name-Suche, Equipment-Filter, Muskelgruppen-Filter (Level 1 + Level 2). Keine Supabase-Aufrufe in der Console.

### BLOCK D — MP4 Video-Cache

- [ ] **D1:** Verzeichnis `MotionCore/Services/Media/` erstellen.

- [ ] **D2:** `VideoCacheService.swift` erstellen in `Services/Media/`:
  - `actor VideoCacheService` mit `static let shared`
  - Zwei Cache-Verzeichnisse: `exercise-videos/` (500 MB Limit) und `exercise-posters/` (50 MB Limit) in `FileManager.cachesDirectory`
  - `func videoURL(videoPath: String) -> (url: URL, isCached: Bool)?` — lokalen Cache prüfen, Remote-URL als Fallback, Hintergrund-Download anstoßen
  - `func posterURL(posterPath: String) -> (url: URL, isCached: Bool)?` — analog für Poster
  - `func preCache(videoPath:) async` — expliziter Download
  - `private func downloadAndCache(remoteURL:localFile:) async` — `URLSession.shared.download`, `FileManager.moveItem`
  - `private func trimCacheIfNeeded(directory:maxSize:) async` — LRU: älteste Dateien zuerst löschen bis unter Limit
  - `SupabaseStorageURLBuilder` wiederverwenden für Remote-URLs
  - Parameter `videoPath`/`posterPath` statt `exercise: Exercise` (View-Signatur unverändert)

- [ ] **D3:** `ExerciseVideoView.swift` anpassen:
  - `loadPosterIfNeeded()`: Cache-First über `VideoCacheService.shared.posterURL(posterPath:)`
  - `startPreviewVideo()` + `startVideo()`: Cache-First über `VideoCacheService.shared.videoURL(videoPath:)`
  - Neue Priorität: Lokales Asset → Cache → Remote

- [ ] **D4 (STOPP):** Xcode Build (`Cmd+B`). Im Simulator: Exercise-Video öffnen, abspielen. Zweites Abspielen: aus Cache (Console prüfen).

### BLOCK E — Aufräumen & Supabase-Rolle reduzieren

- [ ] **E1:** Dateien löschen (aus Xcode-Target und Filesystem entfernen):
  - `SupabaseFilterService.swift`
  - `SupabaseEquipment.swift`
  - `SupabaseMuscles.swift`
  - `SupabaseMusclesHierarchy.swift`
  - `SupabaseExerciseSearchResult.swift`
  - `ExerciseSearchView.swift`
  - `ExerciseSearchDetailView.swift`
  - `ExerciseImportResult.swift`

- [ ] **E2:** `ExerciseImportManager.swift` aufräumen:
  - `importFromSupabase()`, `batchImportFromSupabase()`, `importFullDatabase()` entfernen
  - Behalten: `deleteExercise()`, `exerciseExists()`, `getImportStatistics()`, `enrichWithDetailedMuscles()`

- [ ] **E3:** `SupabaseExerciseService.swift` aufräumen:
  - `fetchExercises(byMuscleGroup:)`, `fetchExercises(byEquipment:)`, `searchExercisesByName()`, `searchExercises()` entfernen
  - Behalten: `fetchAllExercises()`

- [ ] **E4:** `DataSettingsView.swift` anpassen:
  - "Supabase Übungen" → "System-Übungen (Bundle)"
  - Footer-Text: "Übungen aus Supabase können..." → "System-Übungen werden automatisch beim App-Start aus dem Bundle geladen."

- [ ] **E5:** `ExerciseAPIView.swift` anpassen:
  - Icon `"cloud.fill"` → `"info.circle.fill"`
  - Text `"API-Informationen"` → `"Übungsdaten"`

- [ ] **E6:** Tote Imports prüfen — alle `.swift`-Dateien nach Referenzen auf entfernte Typen durchsuchen: `SupabaseFilterService`, `SupabaseEquipment`, `SupabaseMuscles`, `SupabaseMusclesHierarchy`, `SupabaseExerciseSearchResult`, `ExerciseSearchView`, `ExerciseSearchDetailView`, `ExerciseImportResult`. Alle bereinigen.

- [ ] **E7 (STOPP):** Xcode Build (`Cmd+B`). App im Simulator vollständig durchklicken: Exercise-Liste, Suche, Filter, Video, Settings. Keine toten Imports, keine Compiler-Warnungen.

## Manual Verification

- [ ] Xcode Build (`Cmd+B`) nach jedem Block
- [ ] Block A: `ExerciseFilterSheet` zeigt Equipment und Muskelgruppen aus Bundle-JSON (kein Netzwerk-Call)
- [ ] Block B: `ExerciseListView` zeigt ~1.200 Exercises nach erstem Start. Zweiter Start: kein Re-Seed (Console prüfen)
- [ ] Block B: `fetchAllExercises()` via Supabase funktioniert weiterhin (CodingKeys-Kompatibilität)
- [ ] Block C: Lokale Suche liefert Ergebnisse in <100ms, Filter funktionieren offline
- [ ] Block D: Video wird beim ersten Mal gestreamt, beim zweiten Mal aus Cache geladen
- [ ] Block E: App funktioniert vollständig offline (Flugmodus aktivieren, außer Video-Streaming)
- [ ] Block E: Keine Compiler-Warnungen zu unbenutzten Dateien/Typen

## Decisions

1. **JSON-Export (Block B0):** Export über Supabase Dashboard (SQL → JSON Download). Kein temporäres Debug-UI nötig.

2. **Seed-Version:** Manuelle Versionsnummer `static let currentSeedVersion = 1` im `BundledExerciseSeeder`. Nur erhöhen wenn neue `exercises_seed.json` eingespielt wird. Kein automatischer Re-Seed bei jedem App-Build.

3. **LocalExerciseSearchView:** Callback-Pattern `onSelect: (Exercise) -> Void` — wiederverwendbar für `ExerciseListView` und als zukünftiger Ersatz für `ExercisePickerSheet`.

---

## Fortschritt

**2026-04-04 — Block A Korrektur: BundledMuscles durch MuscleGroup/DetailedMuscle Enums ersetzt**

**Erledigte Schritte:** A3/A4 als obsolet markiert, Muskel-Filter-Umbau abgeschlossen

**Geänderte / neue Dateien:**
- `MotionCore/Services/Database/Local/BundledMuscles.swift` — GELÖSCHT
- `MotionCore/Services/Database/Local/BundledMusclesHierarchy.swift` — GELÖSCHT
- `MotionCore/Views/Training/Exercises/View/ExerciseFilterSheet.swift` — Bindings auf `MuscleGroup?`/`DetailedMuscle?` umgestellt; `muscleHierarchy` Parameter entfernt; Hierarchie direkt aus Enums
- `MotionCore/Views/Training/Exercises/View/ExerciseSearchView.swift` — State auf `MuscleGroup?`/`DetailedMuscle?` umgestellt; `muscleHierarchy` State entfernt; `BundledMusclesService`-Aufruf entfernt; Labels nutzen `.rawValue`/`.displayName`

**Offene Punkte:**
- `muscles_seed.json` wird nicht mehr benötigt (kann ignoriert werden)
- A9/B5: `Cmd+B` in Xcode — manueller Build-Check ausstehend

---

**2026-04-04 — Block C (C1, C2, C3) abgeschlossen**

**Erledigte Schritte:** C1, C2, C3

**Geänderte / neue Dateien:**
- `MotionCore/Views/Training/Exercises/View/LocalExerciseSearchView.swift` — NEU: SwiftData-basierte Suche mit `modelContext.fetch()`, Equipment-Filter über `equipmentRaw`, Muskelgruppen-Filter Level 1+2 (mit Fallback auf `primaryMusclesRaw`), Callback-Pattern `onSelect: (Exercise) -> Void`
- `MotionCore/Views/Training/Exercises/View/ExerciseListView.swift` — Sheet von `ExerciseSearchView()` auf `LocalExerciseSearchView` umgestellt
- `MotionCore/Views/Training/Exercises/Sheets/ExercisePickerSheet.swift` — geprüft, keine Änderung nötig

**Offene Punkte:**
- `LocalExerciseSearchView.swift` manuell in Xcode zum MotionCore-Target hinzufügen
- C4: `Cmd+B` in Xcode — manueller Build-Check + Simulator-Test

---

**2026-04-04 — Block B (B1, B3, B4) abgeschlossen**

**Erledigte Schritte:** B1, B3, B4

**Geänderte / neue Dateien:**
- `MotionCore/Services/Database/Remote/Exercise/SupabaseExerciseModels.swift` — `Decodable` → `Codable`, explizite `CodingKeys` für snake_case-Mapping hinzugefügt
- `MotionCore/Services/Database/Local/BundledExerciseSeeder.swift` — NEU: versions-basierter Seeder mit Upsert-Logik, User-Felder-Schutz, 50er-Batch-Save
- `MotionCore/App/MotionCoreApp.swift` — `.task {}` Modifier mit `ExerciseSeeder` + `BundledExerciseSeeder` ergänzt

**Offene Punkte:**
- B0: `exercises_seed.json` vom User manuell aus Supabase exportieren (MANUELLER SCHRITT)
- B2: `exercises_seed.json` ins Xcode-Bundle legen (Build Phases → Copy Bundle Resources)
- B5: `Cmd+B` in Xcode — manueller Build-Check + Simulator-Test
- `BundledExerciseSeeder.swift` manuell in Xcode zum MotionCore-Target hinzufügen

---

**2026-04-03 — Block A (A1–A8) abgeschlossen**

**Erledigte Schritte:** A1, A2, A3, A4, A6, A7, A8

**Geänderte / neue Dateien:**
- `MotionCore/Services/Database/Local/BundledEquipment.swift` — NEU
- `MotionCore/Services/Database/Local/BundledMuscles.swift` — NEU
- `MotionCore/Services/Database/Local/BundledMusclesHierarchy.swift` — NEU
- `MotionCore/Views/Training/Exercises/View/ExerciseFilterSheet.swift` — GEÄNDERT
- `MotionCore/Views/Training/Exercises/View/ExerciseSearchView.swift` — GEÄNDERT
- `MotionCore/App/MotionCoreApp.swift` — GEÄNDERT

**Offene Punkte:**
- A5: `equipment_seed.json` + `muscles_seed.json` vom User exportieren und ins Xcode-Bundle legen (Build Phases → Copy Bundle Resources)
- A9: `Cmd+B` in Xcode — manueller Build-Check
- Neue Swift-Dateien (A2–A4) müssen in Xcode manuell zum MotionCore-Target hinzugefügt werden
