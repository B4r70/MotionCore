# MotionCore — Lokale Exercise- & Equipment-Datenbank

## Konzept v1 — Claude Code Ready

**Ziel:** Exercises (1.200) und Equipment (~20) als gebundelte JSON-Dateien ins App-Bundle verlagern. Supabase wird nur noch für Backups, Session-History und Media-Hosting (MP4s) genutzt. iOS hat Datenhoheit.

**Kernprinzip:** Die App funktioniert vollständig offline (außer MP4-Streaming). Supabase ist Mirror, nicht Quelle.

---

## Ist-Zustand

| Bereich | Aktuell | Ziel |
|---------|---------|------|
| Exercises | API-Suche über `SupabaseExerciseService` → Import in SwiftData | Gebundelte JSON → Seed in SwiftData beim App-Start |
| Equipment | Per RPC `list_equipment` über `SupabaseFilterService` | Gebundelte JSON → lokales Modell |
| Muscles | `DetailedMuscle` Enum + `MuscleGroup` Enum (bereits lokal) | Keine Änderung |
| MP4-Videos | Streaming direkt aus Supabase Storage (kein Cache) | Streaming + lokaler FileManager-Cache |
| Suche/Filter | `ExerciseSearchView` → Supabase RPC `search_exercises` | SwiftData `FetchDescriptor` + `#Predicate` |

---

## BLOCK A — Equipment lokalisieren

**Dateien neu:** `BundledEquipment.swift`, `BundledMuscles.swift`, `equipment_seed.json`, `muscles_seed.json` (App-Bundle)
**Dateien modifizieren:** `ExerciseFilterSheet.swift`, `ExerciseSearchView.swift`
**Dateien entfernen (später in Block E):** `SupabaseEquipment.swift`, `SupabaseFilterService.swift`, `SupabaseMuscles.swift`, `SupabaseMusclesHierarchy.swift`

### A1 — Equipment JSON erstellen

Einmaliger Export aus Supabase. Format identisch zu `SupabaseEquipment`:

```json
[
  {
    "id": "a1b2c3d4-...",
    "identifier": "barbell",
    "category": "free_weights",
    "display_order": 1,
    "name": "Langhantel",
    "description": "Standard-Langhantel (20 kg)"
  }
]
```

Datei: `equipment_seed.json` im App-Bundle (Xcode → Target → Build Phases → Copy Bundle Resources).

### A2 — BundledEquipment Service

Neue Datei: `BundledEquipment.swift`

```swift
// Abschnitt: Services
// Beschreibung: Lokaler Equipment-Katalog aus gebundelter JSON-Datei

import Foundation

struct BundledEquipmentItem: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let category: String?
    let displayOrder: Int?
    let name: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, identifier, category
        case displayOrder = "display_order"
        case name, description
    }
}

struct BundledEquipmentService {
    
    /// Alle Equipment-Items aus der gebundelten JSON laden
    /// Wird beim App-Start einmal aufgerufen und im Speicher gehalten
    static func loadAll() -> [BundledEquipmentItem] {
        guard let url = Bundle.main.url(forResource: "equipment_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ equipment_seed.json nicht im Bundle gefunden")
            return []
        }
        
        let decoder = JSONDecoder()
        do {
            let items = try decoder.decode([BundledEquipmentItem].self, from: data)
            print("✅ \(items.count) Equipment-Items aus Bundle geladen")
            return items.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
        } catch {
            print("❌ Equipment JSON Decode Error: \(error)")
            return []
        }
    }
    
    /// Equipment anhand Identifier finden (z.B. "barbell")
    static func find(identifier: String, in items: [BundledEquipmentItem]) -> BundledEquipmentItem? {
        items.first { $0.identifier == identifier }
    }
}
```

### A3 — ExerciseFilterSheet umbauen

`ExerciseFilterSheet.swift` — `selectedEquipment` Typ ändern:
- Alt: `@Binding var selectedEquipment: SupabaseEquipment?`
- Neu: `@Binding var selectedEquipment: BundledEquipmentItem?`

Die Equipment-Liste kommt nicht mehr aus `filterService.equipments`, sondern wird einmal in der übergeordneten View geladen und durchgereicht.

### A4 — Muskelgruppen als eigener gebundelter Service

`SupabaseMuscles` wird aktuell im `ExerciseFilterSheet` für den hierarchischen Muskelgruppen-Filter genutzt (Level 1 + Level 2 mit UUIDs und parentId). Diese Struktur hat kein lokales Äquivalent — die `MuscleGroup`/`DetailedMuscle` Enums bilden die Hierarchie anders ab.

**Entscheidung:** Muskelgruppen für Filter ebenfalls als JSON bundlen (`muscles_seed.json`), Format identisch zu `SupabaseMuscles`. Damit bleibt der Filter-Code nahezu unverändert.

**Architektur:** Getrennte Services (`BundledEquipmentService` + `BundledMusclesService`), nicht ein gemeinsamer `BundledFilterService`. Grund: Klare Einzelverantwortung pro Datei, konsistent mit dem bestehenden Architekturansatz. Wenn sich ein Format ändert, ist nur eine Datei betroffen.

```json
[
  {
    "id": "...",
    "identifier": "chest",
    "parent_id": null,
    "hierarchy_level": 1,
    "display_order": 1,
    "name": "Brust",
    "description": null
  },
  {
    "id": "...",
    "identifier": "chest_upper",
    "parent_id": "...",
    "hierarchy_level": 2,
    "display_order": 1,
    "name": "Obere Brust",
    "description": null
  }
]
```

Neue Datei: `BundledMuscles.swift`

```swift
// Abschnitt: Services
// Beschreibung: Lokaler Muskelgruppen-Katalog aus gebundelter JSON-Datei

import Foundation

struct BundledMuscleItem: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let parentId: UUID?
    let hierarchyLevel: Int
    let displayOrder: Int?
    let name: String
    let description: String?
    
    var isPrimaryGroup: Bool { hierarchyLevel == 1 && parentId == nil }
    var isSubgroup: Bool { hierarchyLevel == 2 && parentId != nil }
    
    enum CodingKeys: String, CodingKey {
        case id, identifier
        case parentId = "parent_id"
        case hierarchyLevel = "hierarchy_level"
        case displayOrder = "display_order"
        case name, description
    }
}

struct BundledMusclesService {
    
    /// Alle Muskelgruppen aus der gebundelten JSON laden
    static func loadAll() -> [BundledMuscleItem] {
        guard let url = Bundle.main.url(forResource: "muscles_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ muscles_seed.json nicht im Bundle gefunden")
            return []
        }
        
        let decoder = JSONDecoder()
        do {
            let items = try decoder.decode([BundledMuscleItem].self, from: data)
            print("✅ \(items.count) Muskelgruppen aus Bundle geladen")
            return items.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
        } catch {
            print("❌ Muscles JSON Decode Error: \(error)")
            return []
        }
    }
    
    /// Nur Level-1 Hauptgruppen
    static func primaryGroups(from items: [BundledMuscleItem]) -> [BundledMuscleItem] {
        items.filter { $0.isPrimaryGroup }
    }
    
    /// Untergruppen für eine Hauptgruppe
    static func subgroups(for parentId: UUID, from items: [BundledMuscleItem]) -> [BundledMuscleItem] {
        items.filter { $0.parentId == parentId }
    }
    
    /// Hierarchisch gruppiert (für Filter-UI)
    static func grouped(from items: [BundledMuscleItem]) -> [(group: BundledMuscleItem, children: [BundledMuscleItem])] {
        let primaries = primaryGroups(from: items)
        return primaries.map { primary in
            let children = subgroups(for: primary.id, from: items)
            return (primary, children)
        }
    }
}
```

**ExerciseFilterSheet anpassen:**
- Alt: `@Binding var selectedPrimaryMuscle: SupabaseMuscles?` / `@Binding var selectedSubMuscle: SupabaseMuscles?`
- Neu: `@Binding var selectedPrimaryMuscle: BundledMuscleItem?` / `@Binding var selectedSubMuscle: BundledMuscleItem?`

---

> **STOPP — Block A muss kompilieren und alle Filter funktionieren, bevor Block B beginnt.**

---

## BLOCK B — Exercises bundlen & Seeder umbauen

**Dateien neu:** `exercises_seed.json` (App-Bundle), `BundledExerciseSeeder.swift`
**Dateien modifizieren:** `MotionCoreApp.swift` (Seed-Aufruf), `Exercise.swift` (Update-Logik)
**Dateien obsolet (später entfernen):** `ExerciseImportManager.swift` (Batch-Import-Teil), `ExerciseSearchView.swift` (komplett neuer Flow)

### B1 — Exercise JSON erstellen

Einmaliger Export über bestehendes `SupabaseExerciseService.fetchAllExercises()`. Format = `SupabaseExercise`:

```json
[
  {
    "id": "a1b2c3d4-...",
    "exercise_db_id": "0001",
    "category": "compound",
    "force_type": "push",
    "mechanic_type": "compound",
    "difficulty": "intermediate",
    "video_path": "a1b2c3d4-...-uuid.mp4",
    "poster_path": "a1b2c3d4-...-uuid.jpg",
    "thumbnail_url": null,
    "source": "exercisedb",
    "is_verified": true,
    "is_archived": false,
    "created_at": "2025-01-15T12:00:00Z",
    "updated_at": "2025-03-20T08:30:00Z",
    "name": "Langhantel Bankdrücken",
    "instructions": "...",
    "tips": "...",
    "primary_muscles": ["chest_middle", "chest_lower"],
    "secondary_muscles": ["triceps_lateral", "shoulders_front"],
    "equipment": ["barbell"]
  }
]
```

**Wichtig:** CodingKeys in `SupabaseExercise` nutzen snake_case. Die JSON-Datei muss exakt dieses Format haben, damit der bestehende `Exercise(from: SupabaseExercise)` Initializer funktioniert.

Dateigröße geschätzt: ~3–5 MB für 1.200 Exercises.

### B2 — BundledExerciseSeeder

Neue Datei: `BundledExerciseSeeder.swift`

Verantwortlichkeiten:
1. Prüft ob Seed-Version sich geändert hat (Bundle-Version in `UserDefaults`)
2. Liest `exercises_seed.json` aus Bundle
3. Decoded als `[SupabaseExercise]` (bestehendes Modell wiederverwendet)
4. Für jede Exercise: Prüft ob `apiID` in SwiftData existiert
   - **Nicht vorhanden:** Insert über `Exercise(from: supabaseExercise)` (bestehender Init)
   - **Vorhanden:** Update nur der sich ändernden Felder (siehe B3)
5. Speichert in 50er-Batches (wie bestehender `batchImportFromSupabase`)

```swift
// Abschnitt: Services
// Beschreibung: Seeder für gebundelte Exercise-Datenbank

import Foundation
import SwiftData

struct BundledExerciseSeeder {
    
    // UserDefaults-Key für die letzte Seed-Version
    private static let seedVersionKey = "bundledExerciseSeedVersion"
    
    /// Aktuelle Seed-Version — hochzählen bei jeder neuen exercises_seed.json
    /// Empfehlung: App-Build-Number oder manuelles Inkrement
    static var currentSeedVersion: Int {
        // Bundle-Version als Int oder manuelles Inkrement
        Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
    }
    
    /// Prüft ob ein Seed nötig ist und führt ihn ggf. durch
    static func seedIfNeeded(context: ModelContext) async {
        let lastVersion = UserDefaults.standard.integer(forKey: seedVersionKey)
        
        // Erster Start: Immer seeden
        // App-Update mit neuer Build-Number: Erneut seeden (upsert)
        guard lastVersion < currentSeedVersion else {
            print("✅ BundledExerciseSeeder: Seed-Version \(lastVersion) ist aktuell")
            return
        }
        
        print("🚀 BundledExerciseSeeder: Starte Seed (Version \(lastVersion) → \(currentSeedVersion))")
        
        do {
            try await performSeed(context: context)
            UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)
            print("✅ BundledExerciseSeeder: Seed-Version \(currentSeedVersion) gespeichert")
        } catch {
            print("❌ BundledExerciseSeeder: Seed fehlgeschlagen: \(error)")
        }
    }
    
    // MARK: - Private
    
    private static func performSeed(context: ModelContext) async throws {
        // 1. JSON aus Bundle laden
        guard let url = Bundle.main.url(forResource: "exercises_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ exercises_seed.json nicht im Bundle gefunden")
            return
        }
        
        // 2. Decoder mit DateStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let supabaseExercises = try decoder.decode([SupabaseExercise].self, from: data)
        print("📥 \(supabaseExercises.count) Exercises aus Bundle geladen")
        
        // 3. Bestehende Exercises mit apiID laden (für Duplikat-Check + Update)
        let descriptor = FetchDescriptor<Exercise>()
        let allLocal = try context.fetch(descriptor)
        let localByApiID: [UUID: Exercise] = Dictionary(
            uniqueKeysWithValues: allLocal.compactMap { ex in
                guard let apiID = ex.apiID else { return nil }
                return (apiID, ex)
            }
        )
        
        // 4. Upsert
        var inserted = 0
        var updated = 0
        var skipped = 0
        
        for (index, supabaseExercise) in supabaseExercises.enumerated() {
            if let existing = localByApiID[supabaseExercise.id] {
                // Update: Nur Felder aktualisieren, die sich ändern können
                let didUpdate = updateExercise(existing, from: supabaseExercise)
                if didUpdate { updated += 1 } else { skipped += 1 }
            } else {
                // Insert
                let newExercise = Exercise(from: supabaseExercise)
                context.insert(newExercise)
                inserted += 1
            }
            
            // Batch-Save alle 50 Exercises
            if (index + 1) % 50 == 0 {
                try context.save()
            }
        }
        
        // Finale Speicherung
        try context.save()
        
        print("✅ BundledExerciseSeeder abgeschlossen:")
        print("   - Neu: \(inserted)")
        print("   - Aktualisiert: \(updated)")
        print("   - Unverändert: \(skipped)")
    }
    
    /// Aktualisiert eine bestehende Exercise mit neuen Daten aus dem Bundle.
    /// Ändert NUR Felder, die aus der Seed-Datenbank kommen.
    /// Lässt User-Daten (isFavorite, repRange, Progression, Sets) komplett unberührt.
    /// - Returns: true wenn mindestens ein Feld geändert wurde
    @discardableResult
    private static func updateExercise(_ existing: Exercise, from source: SupabaseExercise) -> Bool {
        var changed = false
        
        // Name
        if existing.name != source.name {
            existing.name = source.name
            changed = true
        }
        
        // Instructions
        let newInstructions = source.instructions ?? ""
        if existing.instructions != newInstructions {
            existing.instructions = newInstructions
            changed = true
        }
        
        // Tips → exerciseDescription
        let newTips = source.tips ?? ""
        if existing.exerciseDescription != newTips {
            existing.exerciseDescription = newTips
            changed = true
        }
        
        // Video/Poster Paths
        if existing.videoPath != source.videoPath {
            existing.videoPath = source.videoPath
            changed = true
        }
        if existing.posterPath != source.posterPath {
            existing.posterPath = source.posterPath
            changed = true
        }
        
        // DetailedMuscles (feingranular)
        let newDetailedPrimary = source.primaryMuscles
            .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
        let newDetailedSecondary = source.secondaryMuscles
            .compactMap { MuscleGroupMapper.mapDetailed(supabaseValue: $0) }
        
        if existing.detailedPrimaryMuscles != newDetailedPrimary {
            existing.detailedPrimaryMuscles = newDetailedPrimary
            changed = true
        }
        if existing.detailedSecondaryMuscles != newDetailedSecondary {
            existing.detailedSecondaryMuscles = newDetailedSecondary
            changed = true
        }
        
        // Equipment
        let newEquipment = ExerciseEquipment.fromSupabase(source.equipment.first)
        if existing.equipment != newEquipment {
            existing.equipment = newEquipment
            changed = true
        }
        
        // Difficulty
        let newDifficulty = ExerciseDifficulty.fromSupabase(source.difficulty ?? "intermediate")
        if existing.difficulty != newDifficulty {
            existing.difficulty = newDifficulty
            changed = true
        }
        
        // Category
        let newCategory = ExerciseCategory.fromSupabase(
            mechanic: source.mechanicType,
            force: source.forceType
        )
        if existing.category != newCategory {
            existing.category = newCategory
            changed = true
        }
        
        return changed
    }
}
```

**Felder die NICHT überschrieben werden (User-Daten):**
- `isFavorite`, `isCustom`, `isArchived`
- `repRangeMin`, `repRangeMax`
- `progressionStep`, `targetRIR`, `progressionSessionsRequired`, alle Progressions-Felder
- `lastProgressionDate`, `sortIndex`
- `sets` (Relationship)
- `localVideoFileName` (lokaler Cache)

### B3 — Seed-Aufruf in MotionCoreApp

In `MotionCoreApp.swift`, im `.task {}` Modifier der Root-View:

```swift
.task {
    // Bestehender Seed für handgepflegte Übungen
    ExerciseSeeder.seedIfNeeded(context: modelContext)
    
    // Neuer Bundle-Seed (1.200 Übungen aus JSON)
    await BundledExerciseSeeder.seedIfNeeded(context: modelContext)
}
```

**Reihenfolge wichtig:** `ExerciseSeeder` zuerst (enthält eventuell handgepflegte Übungen ohne apiID). `BundledExerciseSeeder` danach (hat apiID-basierte Duplikat-Erkennung).

### B4 — CodingKeys zu SupabaseExercise hinzufügen

`SupabaseExercise` hat aktuell **keine expliziten CodingKeys**. Da die Bundle-JSON im `snake_case`-Format aus Supabase exportiert wird, müssen CodingKeys ergänzt werden.

**Entscheidung:** Explizite CodingKeys in `SupabaseExercise` hinzufügen. Der Decoder in `BundledExerciseSeeder` (und überall sonst) braucht dann KEINE `.convertFromSnakeCase`-Strategy — die CodingKeys übernehmen das Mapping. Das ist sauberer, weil es an einer einzigen Stelle (dem Modell) definiert ist.

`SupabaseExerciseModels.swift` erweitern:

```swift
struct SupabaseExercise: Codable, Identifiable {
    let id: UUID
    let exerciseDbId: String?
    let category: String?
    let forceType: String?
    let mechanicType: String?
    let difficulty: String?
    let videoPath: String?
    let posterPath: String?
    let thumbnailUrl: String?
    let source: String?
    let isVerified: Bool
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
    let name: String
    let instructions: String?
    let tips: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let equipment: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case exerciseDbId = "exercise_db_id"
        case category
        case forceType = "force_type"
        case mechanicType = "mechanic_type"
        case difficulty
        case videoPath = "video_path"
        case posterPath = "poster_path"
        case thumbnailUrl = "thumbnail_url"
        case source
        case isVerified = "is_verified"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name, instructions, tips
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
        case equipment
    }
}
```

**Wichtig:** Auch `Decodable` → `Codable` ändern, damit zukünftiges Encoding (z.B. für Backup-Upload) ebenfalls funktioniert.

**ACHTUNG — Breaking Change prüfen:** Nach dem Hinzufügen der CodingKeys muss getestet werden, ob bestehende RPC-Calls (`fetchAllExercises`, etc.) weiterhin korrekt decodieren. Die Supabase RPC-Responses liefern bereits `snake_case` — das passt dann direkt mit den neuen CodingKeys zusammen.

---

> **STOPP — Block B muss kompilieren. App muss starten und alle 1.200 Exercises müssen in SwiftData sein. ExerciseListView muss sie anzeigen. Erst dann Block C.**

---

## BLOCK C — Lokale Suche & Filter

**Dateien neu:** `LocalExerciseSearchView.swift` (ersetzt `ExerciseSearchView.swift`)
**Dateien modifizieren:** `ExercisePickerSheet.swift`, `ExerciseListView.swift`

### C1 — Suche über SwiftData

Die aktuelle `ExerciseSearchView` sucht über Supabase RPC und zeigt Ergebnisse als `SupabaseExerciseSearchResult` an, mit einem "Importieren"-Button pro Ergebnis.

**Neuer Flow:** Alle Exercises sind bereits lokal. Die Suche läuft gegen SwiftData:

```swift
// SwiftData-basierte Suche
let searchTerm = searchText.lowercased()
let descriptor = FetchDescriptor<Exercise>(
    predicate: #Predicate<Exercise> { exercise in
        exercise.name.localizedStandardContains(searchTerm)
    },
    sortBy: [SortDescriptor(\.name)]
)
descriptor.fetchLimit = 50
let results = try context.fetch(descriptor)
```

Bei 1.200 Exercises ist das in <10ms erledigt — kein Debounce nötig (aber kann drin bleiben für UX-Konsistenz).

### C2 — Filter lokal

**Equipment-Filter:** Statt `selectedEquipment: SupabaseEquipment?` wird `selectedEquipment: BundledEquipmentItem?` verwendet. Filter-Logik:

```swift
// Filter auf equipmentRaw (String-basierter Vergleich)
if let equipment = selectedEquipment {
    // Prädikats-Erweiterung
    predicate = #Predicate { $0.equipmentRaw == equipment.identifier }
}
```

**Muskelgruppen-Filter:** Statt `selectedPrimaryMuscle: SupabaseMuscles?` → `selectedPrimaryMuscle: BundledMuscleItem?`. Filter-Logik:

```swift
// Filter über detailedPrimaryMusclesRaw (Array-Contains)
if let muscle = selectedPrimaryMuscle {
    let identifier = muscle.identifier
    // Für Level 1 (z.B. "chest"): Alle DetailedMuscles mit diesem parentGroup
    // Für Level 2 (z.B. "chest_upper"): Exakter Match
    if muscle.hierarchyLevel == 1 {
        let childIdentifiers = DetailedMuscle.allCases
            .filter { $0.parentGroup.rawValue == identifier }
            .map { $0.rawValue }
        // SwiftData #Predicate mit Array-Contains
        predicate = ... // Intersection-Check
    } else {
        predicate = #Predicate { $0.detailedPrimaryMusclesRaw.contains(identifier) }
    }
}
```

**Hinweis:** SwiftData `#Predicate` unterstützt `.contains` auf `[String]`. Für Level-1-Filter (mehrere Identifier) muss ggf. eine OR-Verknüpfung gebaut oder clientseitig gefiltert werden. Bei 1.200 Exercises ist clientseitiges Filtern performant genug.

### C3 — ExerciseSearchView ersetzen

Die bestehende `ExerciseSearchView` (564 Zeilen) wird **komplett ersetzt** durch eine neue `LocalExerciseSearchView`. Der Import-Flow entfällt — alle Exercises sind schon da.

**Neues Konzept:**
- Suchfeld durchsucht alle lokalen Exercises (Name, ggf. Description)
- Filter-Sheet zeigt Equipment und Muskelgruppen aus Bundle-JSON
- Ergebnisliste zeigt `Exercise`-Objekte direkt (kein DTO mehr)
- Tap auf Exercise → direkt zum Training hinzufügen (kein "Importieren" mehr)
- Favoriten-Markierung direkt in der Ergebnisliste möglich

### C4 — ExercisePickerSheet anpassen

`ExercisePickerSheet` nutzt eventuell noch den alten Suche-Flow. Umstellen auf lokale SwiftData-Suche.

---

> **STOPP — Block C muss kompilieren. Suche und Filter müssen vollständig offline funktionieren. Erst dann Block D.**

---

## BLOCK D — MP4 Video-Cache

**Dateien neu:** `VideoCacheService.swift`
**Dateien modifizieren:** `ExerciseVideoView.swift`

### D1 — VideoCacheService

Neuer Service: `VideoCacheService.swift`

Verantwortlichkeiten:
- Prüft ob ein Video lokal im Cache liegt (FileManager)
- Lädt Videos aus Supabase Storage und speichert sie lokal
- Gibt die lokale URL zurück (oder Remote-URL als Fallback)
- LRU-artige Bereinigung (z.B. max. 500 MB Cache, älteste zuerst löschen)

```swift
// Abschnitt: Services
// Beschreibung: Lokaler Cache für Exercise-Videos aus Supabase Storage

import Foundation

actor VideoCacheService {
    static let shared = VideoCacheService()
    
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500 MB
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("exercise-videos", isDirectory: true)
        
        // Verzeichnis erstellen falls nötig
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Gibt die URL für ein Video zurück.
    /// Falls gecacht: lokale File-URL.
    /// Falls nicht gecacht: startet Download im Hintergrund und gibt Remote-URL zurück.
    func videoURL(for exercise: Exercise) -> (url: URL, isCached: Bool)? {
        guard let videoPath = exercise.videoPath else { return nil }
        
        // 1. Lokaler Cache prüfen
        let localFile = cacheDirectory.appendingPathComponent(cacheKey(for: videoPath))
        if FileManager.default.fileExists(atPath: localFile.path) {
            return (localFile, true)
        }
        
        // 2. Remote-URL zurückgeben + Download anstoßen
        guard let remoteURL = SupabaseStorageURLBuilder.publicURL(
            bucket: .exerciseVideos, path: videoPath
        ) else { return nil }
        
        // Hintergrund-Download starten
        Task { await downloadAndCache(remoteURL: remoteURL, localFile: localFile) }
        
        return (remoteURL, false)
    }
    
    /// Expliziter Download (z.B. für Pre-Caching einer Trainingsplan-Übung)
    func preCache(videoPath: String) async {
        let localFile = cacheDirectory.appendingPathComponent(cacheKey(for: videoPath))
        guard !FileManager.default.fileExists(atPath: localFile.path) else { return }
        
        guard let remoteURL = SupabaseStorageURLBuilder.publicURL(
            bucket: .exerciseVideos, path: videoPath
        ) else { return }
        
        await downloadAndCache(remoteURL: remoteURL, localFile: localFile)
    }
    
    // MARK: - Private
    
    private func downloadAndCache(remoteURL: URL, localFile: URL) async {
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            try FileManager.default.moveItem(at: tempURL, to: localFile)
            print("✅ Video gecacht: \(localFile.lastPathComponent)")
            
            // Cache-Größe prüfen
            await trimCacheIfNeeded()
        } catch {
            print("⚠️ Video-Cache fehlgeschlagen: \(error.localizedDescription)")
        }
    }
    
    private func cacheKey(for videoPath: String) -> String {
        // videoPath ist z.B. "a1b2c3d4-uuid.mp4" — direkt als Dateiname nutzbar
        videoPath
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }
    
    private func trimCacheIfNeeded() async {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }
        
        // Gesamtgröße berechnen
        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, size: Int64, date: Date)] = []
        
        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { continue }
            totalSize += Int64(size)
            fileInfos.append((file, Int64(size), date))
        }
        
        // Älteste zuerst löschen bis unter maxCacheSize
        guard totalSize > maxCacheSize else { return }
        
        let sorted = fileInfos.sorted { $0.date < $1.date }
        for fileInfo in sorted {
            try? fm.removeItem(at: fileInfo.url)
            totalSize -= fileInfo.size
            print("🗑️ Cache bereinigt: \(fileInfo.url.lastPathComponent)")
            if totalSize <= maxCacheSize { break }
        }
    }
}
```

### D2 — ExerciseVideoView Integration

`ExerciseVideoView.swift` anpassen:

```swift
// Bestehende Priorität: Lokales Asset → Remote
// Neue Priorität: Lokales Asset → Cache → Remote (mit Cache-Start)

// Statt:
// videoURL = SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path)

// Neu:
if let result = await VideoCacheService.shared.videoURL(for: exercise) {
    videoURL = result.url
    if !result.isCached {
        isLoadingVideo = true  // Streaming bis Cache fertig
    }
}
```

### D3 — Pre-Caching für aktiven Trainingsplan

Optional, aber gute UX: Wenn ein User einen Trainingsplan startet, können die Videos der enthaltenen Exercises im Hintergrund vorgeladen werden:

```swift
// In ActiveWorkoutView oder beim Plan-Start:
Task {
    for exercise in plan.exercises {
        guard let path = exercise.videoPath else { continue }
        await VideoCacheService.shared.preCache(videoPath: path)
    }
}
```

### D4 — Poster-Cache

Poster-Bilder (JPG, je ~50–100 KB) werden analog zu Videos gecacht. Da Poster deutlich kleiner sind, wird der Cache in den bestehenden `VideoCacheService` integriert (statt eigenem Service) — als zweites Cache-Verzeichnis mit eigenem Limit.

Erweiterung in `VideoCacheService`:

```swift
// Zweites Cache-Verzeichnis für Poster
private let posterCacheDirectory: URL
private let maxPosterCacheSize: Int64 = 50 * 1024 * 1024 // 50 MB (reicht für ~500+ Poster)

// Init erweitern:
posterCacheDirectory = caches.appendingPathComponent("exercise-posters", isDirectory: true)
try? FileManager.default.createDirectory(at: posterCacheDirectory, withIntermediateDirectories: true)

/// Gibt die URL für ein Poster zurück (analog zu videoURL)
func posterURL(for exercise: Exercise) -> (url: URL, isCached: Bool)? {
    guard let posterPath = exercise.posterPath else { return nil }
    
    let localFile = posterCacheDirectory.appendingPathComponent(cacheKey(for: posterPath))
    if FileManager.default.fileExists(atPath: localFile.path) {
        return (localFile, true)
    }
    
    guard let remoteURL = SupabaseStorageURLBuilder.publicURL(
        bucket: .exercisePosters, path: posterPath
    ) else { return nil }
    
    Task { await downloadAndCachePoster(remoteURL: remoteURL, localFile: localFile) }
    
    return (remoteURL, false)
}
```

`ExerciseVideoView.swift` anpassen — `loadPosterIfNeeded()` nutzt den Cache:

```swift
// Statt direkt URLSession.shared.data(from: url):
if let result = await VideoCacheService.shared.posterURL(for: exercise) {
    if result.isCached {
        posterImage = UIImage(contentsOfFile: result.url.path)
    } else {
        // Remote laden (wird im Hintergrund gecacht)
        let (data, _) = try await URLSession.shared.data(from: result.url)
        posterImage = UIImage(data: data)
    }
}
```

**Service-Umbenennung:** Da der Service jetzt Videos UND Poster cached, wäre `MediaCacheService` der bessere Name. Alternativ bleibt `VideoCacheService` mit Poster-Erweiterung — Entscheidung liegt bei Claude Code, beides ist akzeptabel.

---

> **STOPP — Block D muss kompilieren. Videos müssen laden und gecacht werden. Cache-Bereinigung muss funktionieren. Erst dann Block E.**

---

## BLOCK E — Aufräumen & Supabase-Rolle reduzieren

**Dateien entfernen:**
- `SupabaseExerciseService.swift` → Search/Filter-Methoden entfernen, nur `fetchAllExercises` behalten (für einmaligen JSON-Export und ggf. Future-Sync)
- `SupabaseExerciseSearchResult.swift` → Entfernen (wird nicht mehr genutzt)
- `SupabaseFilterService.swift` → Entfernen (Equipment + Muscles kommen aus Bundle)
- `SupabaseEquipment.swift` → Entfernen (ersetzt durch `BundledEquipmentItem`)
- `SupabaseMuscles.swift` → Entfernen (ersetzt durch `BundledMuscleItem`)
- `SupabaseMusclesHierarchy.swift` → Entfernen (Hierarchie-Logik jetzt in `BundledMusclesService.grouped()`)
- `ExerciseSearchView.swift` → Durch `LocalExerciseSearchView.swift` ersetzt
- `ExerciseImportManager.swift` → `batchImportFromSupabase` und `importFullDatabase` entfernen. `enrichWithDetailedMuscles` behalten (Fallback). `deleteExercise` und `getImportStatistics` behalten.

**Dateien die BLEIBEN:**
- `SupabaseClient.swift` — wird weiterhin für Backups und Session-Streaming gebraucht
- `SupabaseConfig.swift` — Konfiguration bleibt
- `SupabaseStorageBucket.swift` — für MP4/Poster-URLs
- `SupabaseSessionService.swift` — Session-Backup
- `SupabaseFullBackupService.swift` — Full-Backup
- `SupabaseSessionModels.swift` — Backup-Modelle
- `SupabaseSyncSection.swift` — UI für Sync-Status
- `SupabaseFullBackupSection.swift` — UI für Full-Backup

### E1 — DataSettingsView anpassen

Die Statistik-Sektion "Übungsbibliothek" in `DataSettingsView` zeigt aktuell "Supabase Übungen" vs "Eigene Übungen". Anpassen auf "System-Übungen (Bundle)" vs "Eigene Übungen".

### E2 — ExerciseAPIView vereinfachen

`ExerciseAPIView.swift` ist **kein Import-Flow**, sondern eine Info-Anzeige in `ExerciseFormView` für importierte Exercises (zeigt Provider-Badge, Video-Button, API-Metadaten). Die View bleibt erhalten, da sie weiterhin sinnvolle Informationen zeigt (Video-Player, Quelle).

Einzige Anpassung: Den Header-Text "API-Informationen" zu "Übungsdaten" o.ä. umbenennen, da "API" für den User irrelevant ist. Das Cloud-Icon (`cloud.fill`) kann durch ein neutraleres Icon ersetzt werden.

---

> **STOPP — Block E muss kompilieren. Keine toten Imports, keine unbenutzten Dateien. App muss ohne aktive Internetverbindung funktionieren (außer MP4-Streaming). Erst dann abgeschlossen.**

---

## Zusammenfassung: Supabase-Rolle nach Umbau

| Funktion | Vorher | Nachher |
|----------|--------|---------|
| Exercise-Suche | Supabase RPC | Lokal (SwiftData) |
| Exercise-Import | Supabase → SwiftData | Bundle JSON → SwiftData (einmalig) |
| Equipment-Filter | Supabase RPC | Bundle JSON |
| Muskelgruppen-Filter | Supabase RPC | Bundle JSON |
| Muskel-Heatmap | Lokal (DetailedMuscle Enum) | Keine Änderung |
| MP4-Videos | Supabase Storage (Streaming) | Supabase Storage (Streaming + Cache) |
| Session-Backup | Supabase | Keine Änderung |
| Full-Backup | Supabase | Keine Änderung |

## Dateien im App-Bundle (neu)

| Datei | Größe (geschätzt) | Inhalt |
|-------|-------------------|--------|
| `exercises_seed.json` | 3–5 MB | 1.200 Exercises im SupabaseExercise-Format |
| `equipment_seed.json` | ~5 KB | ~20 Equipment-Items |
| `muscles_seed.json` | ~10 KB | ~50 MuscleGroup-Items (Level 1 + 2) |

## Risiken & Mitigationen

| Risiko | Mitigation |
|--------|------------|
| JSON-Format ändert sich | CodingKeys in SupabaseExercise explizit definiert (Block B4) |
| Bestehende Exercises verlieren User-Daten | Update-Logik ändert nur Seed-Felder, nie User-Felder |
| Cache wird zu groß | LRU-Bereinigung mit 500 MB Limit |
| App-Start wird langsam bei Seed | Seed läuft nur bei Version-Änderung, nicht bei jedem Start |
| Neue Exercises kommen hinzu | Neue exercises_seed.json im nächsten App-Update |
