# MotionCore — Muskel-Heatmap: Vollständiger Implementierungsplan

## ⚠️ OBERSTE PRIORITÄT: DATENSICHERHEIT

**Es dürfen KEINE bestehenden Daten, Relationships oder Funktionalitäten verloren gehen.**

- Keine bestehende Exercise löschen, verschieben oder re-importieren
- Keine bestehende Relationship (ExerciseSet → Exercise, TrainingPlan → templateSets) antasten
- `MuscleGroup` Enum bleibt in allen Blocks komplett unverändert
- Bestehende `primaryMusclesRaw` und `secondaryMusclesRaw` in `Exercise.swift` bleiben als Felder erhalten
- Alle bestehenden Views, CalcEngines und Imports müssen nach jedem Block identisch funktionieren
- Im Zweifel: lieber weniger ändern als zu viel

**Zusätzliche Informationen und Anweisungen
- Bitte lies dir zum Beginn dieses Projekts einmalig den kompletten SOurcecode von MotionCore ein
- Bitte arbeite gewissenhaft und vorausschauend
- Wir arbeiten grundsätzlich blockweise. Qualität steht über Quantität
- Die SVG für die Heatmap befindet sich unter dem folgenden Pfad: /Users/bartosz/Developments/MotionCore/MotionCore/Ressources/Muscles_Heatmap.svg

---

## Workflow: Block-für-Block Freigabe

Dieses Dokument enthält 4 Blocks (A → B → C → D). **Arbeite immer nur den aktuell freigegebenen Block ab.**

Nach Abschluss eines Blocks:
1. Melde dem User, dass der Block abgeschlossen ist
2. Zeige eine kurze Zusammenfassung: welche Dateien geändert/erstellt, was als nächstes kommt
3. **STOPP — Warte auf die Freigabe des nächsten Blocks.** Der User führt einen Xcode-Build aus und prüft die App. Erst wenn er den nächsten Block explizit freigibt, wird weitergearbeitet.

**Starte jetzt mit Block A.**

---

## Block A: DetailedMuscle Enum + Exercise-Felder

### Kontext

`DetailedMuscle` in `StrengthTypes.swift` (Zeile 55–120) existiert, wird aber nirgends im Code referenziert — es ist definiert aber unbenutzt. Es wird jetzt durch ein neues Enum mit 39 Cases ersetzt, das als Basis für die Muskel-Heatmap dient. Gleichzeitig bekommt `Exercise.swift` zwei neue Felder.

### Vor dem Start: Code lesen

Lies zuerst diese Dateien und verifiziere, dass die Zeilennummern und Strukturen stimmen:
- `StrengthTypes.swift` — besonders `DetailedMuscle` ab Zeile 53
- `Exercise.swift` — Properties ab Zeile 60, Init ab Zeile 71, Convenience Init ab Zeile 305, Computed Properties ab Zeile 191

### Schritt A1: DetailedMuscle Enum ersetzen

**Datei:** `StrengthTypes.swift`

**Was tun:** Das gesamte `enum DetailedMuscle` (Zeile 53 bis Zeile 120, inklusive `// MARK: - Detailed Muscles`) durch das neue Enum ersetzen.

**Was NICHT anfassen:** `enum StrengthWorkoutType` (Zeile 17–28), `enum MuscleGroup` (Zeile 30–51), File-Header, Imports.

**Neues Enum:**

```swift
// MARK: - Detailed Muscles (Feingranulare Muskel-Definition — 1:1 mit Supabase)

enum DetailedMuscle: String, CaseIterable, Identifiable, Codable {
    // Brust (5)
    case chestUpper = "chest_upper"
    case chestMiddle = "chest_middle"
    case chestLower = "chest_lower"
    case chestInner = "chest_inner"
    case chestOuter = "chest_outer"

    // Rücken (7)
    case backLats = "back_lats"
    case backTrapsUpper = "back_traps_upper"
    case backTrapsMiddle = "back_traps_middle"
    case backTrapsLower = "back_traps_lower"
    case backRhomboids = "back_rhomboids"
    case backErectorSpinae = "back_erector_spinae"
    case backTeres = "back_teres"

    // Schultern (3)
    case shouldersFront = "shoulders_front"
    case shouldersSide = "shoulders_side"
    case shouldersRear = "shoulders_rear"

    // Arme — Bizeps (2)
    case bicepsLong = "biceps_long"
    case bicepsShort = "biceps_short"

    // Arme — Trizeps (3)
    case tricepsLong = "triceps_long"
    case tricepsLateral = "triceps_lateral"
    case tricepsMedial = "triceps_medial"

    // Arme — Unterarme (2)
    case forearmFlexors = "forearms_flexors"
    case forearmExtensors = "forearms_extensors"

    // Beine — Quads (4)
    case quadsVastusLateralis = "quads_vastus_lateralis"
    case quadsVastusMedialis = "quads_vastus_medialis"
    case quadsVastusIntermedius = "quads_vastus_intermedius"
    case quadsRectusFemoris = "quads_rectus_femoris"

    // Beine — Hamstrings (3)
    case hamstringsBicepsFemoris = "hamstrings_biceps_femoris"
    case hamstringsSemitendinosus = "hamstrings_semitendinosus"
    case hamstringsSemimembranosus = "hamstrings_semimembranosus"

    // Beine — Glutes (3)
    case glutesMaximus = "glutes_maximus"
    case glutesMedius = "glutes_medius"
    case glutesMinimus = "glutes_minimus"

    // Beine — Waden (2)
    case calvesGastrocnemius = "calves_gastrocnemius"
    case calvesSoleus = "calves_soleus"

    // Beine — Hüfte (2)
    case adductors = "adductors"
    case abductors = "abductors"

    // Core (5)
    case absUpper = "abs_upper"
    case absLower = "abs_lower"
    case absObliques = "abs_obliques"
    case absTransverse = "abs_transverse"
    case lowerBack = "lower_back"

    // SVG-only — kein Supabase-Pendant (1)
    case neck = "neck"

    var id: String { rawValue }

    var description: String { displayName }
}

// MARK: - DetailedMuscle Computed Properties

extension DetailedMuscle {

    /// Supabase-Identifier — identisch mit rawValue für alle außer .neck
    var supabaseIdentifier: String? {
        self == .neck ? nil : rawValue
    }

    /// SVG-Element-ID für die Muskel-Heatmap
    /// nil für absTransverse (tiefe Muskulatur, kein sichtbares SVG-Element)
    var svgRegionId: String? {
        switch self {
        // Brust
        case .chestUpper: return "upper_pecs"
        case .chestMiddle, .chestInner, .chestOuter: return "middle_pecs"
        case .chestLower: return "lower_pecs"
        // Rücken
        case .backLats, .backTeres: return "lats"
        case .backTrapsUpper: return "upper_traps"
        case .backTrapsMiddle, .backTrapsLower: return "lower_traps"
        case .backRhomboids: return "rhomboids"
        case .backErectorSpinae: return "lower_back"
        // Schultern
        case .shouldersFront: return "front_delts"
        case .shouldersSide: return "side_delts"
        case .shouldersRear: return "rear_delts"
        // Arme
        case .bicepsLong, .bicepsShort: return "biceps"
        case .tricepsLong, .tricepsLateral, .tricepsMedial: return "triceps"
        case .forearmFlexors, .forearmExtensors: return "forearms"
        // Beine
        case .quadsVastusLateralis, .quadsVastusMedialis,
             .quadsVastusIntermedius, .quadsRectusFemoris: return "quads"
        case .hamstringsBicepsFemoris, .hamstringsSemitendinosus,
             .hamstringsSemimembranosus: return "hamstrings"
        case .glutesMaximus, .glutesMedius, .glutesMinimus: return "glutes"
        case .calvesGastrocnemius, .calvesSoleus: return "calves"
        case .adductors: return "hip_adductor"
        case .abductors: return "hip_abductor"
        // Core
        case .absUpper: return "upper_abs"
        case .absLower: return "lower_abs"
        case .absObliques: return "obliques"
        case .absTransverse: return nil
        case .lowerBack: return "lower_back"
        // SVG-only
        case .neck: return "neck"
        }
    }

    /// Übergeordnete Hauptmuskelgruppe (Rückwärtskompatibilität)
    var parentGroup: MuscleGroup {
        switch self {
        case .chestUpper, .chestMiddle, .chestLower, .chestInner, .chestOuter:
            return .chest
        case .backLats, .backTrapsUpper, .backTrapsMiddle, .backTrapsLower,
             .backRhomboids, .backErectorSpinae, .backTeres:
            return .back
        case .shouldersFront, .shouldersSide, .shouldersRear:
            return .shoulders
        case .bicepsLong, .bicepsShort, .tricepsLong, .tricepsLateral,
             .tricepsMedial, .forearmFlexors, .forearmExtensors:
            return .arms
        case .quadsVastusLateralis, .quadsVastusMedialis, .quadsVastusIntermedius,
             .quadsRectusFemoris, .hamstringsBicepsFemoris, .hamstringsSemitendinosus,
             .hamstringsSemimembranosus, .calvesGastrocnemius, .calvesSoleus,
             .adductors, .abductors:
            return .legs
        case .glutesMaximus, .glutesMedius, .glutesMinimus:
            return .glutes
        case .absUpper, .absLower, .absObliques, .absTransverse, .lowerBack:
            return .core
        case .neck:
            return .other
        }
    }

    /// Deutscher Anzeigename
    var displayName: String {
        switch self {
        case .chestUpper: return "Obere Brust"
        case .chestMiddle: return "Mittlere Brust"
        case .chestLower: return "Untere Brust"
        case .chestInner: return "Innere Brust"
        case .chestOuter: return "Äußere Brust"
        case .backLats: return "Latissimus"
        case .backTrapsUpper: return "Oberer Trapez"
        case .backTrapsMiddle: return "Mittlerer Trapez"
        case .backTrapsLower: return "Unterer Trapez"
        case .backRhomboids: return "Rhomboideus"
        case .backErectorSpinae: return "Rückenstrecker"
        case .backTeres: return "Teres"
        case .shouldersFront: return "Vordere Schulter"
        case .shouldersSide: return "Seitliche Schulter"
        case .shouldersRear: return "Hintere Schulter"
        case .bicepsLong: return "Bizeps (Langer Kopf)"
        case .bicepsShort: return "Bizeps (Kurzer Kopf)"
        case .tricepsLong: return "Trizeps (Langer Kopf)"
        case .tricepsLateral: return "Trizeps (Lateraler Kopf)"
        case .tricepsMedial: return "Trizeps (Medialer Kopf)"
        case .forearmFlexors: return "Unterarm-Beuger"
        case .forearmExtensors: return "Unterarm-Strecker"
        case .quadsVastusLateralis: return "Vastus Lateralis"
        case .quadsVastusMedialis: return "Vastus Medialis"
        case .quadsVastusIntermedius: return "Vastus Intermedius"
        case .quadsRectusFemoris: return "Rectus Femoris"
        case .hamstringsBicepsFemoris: return "Beinbizeps"
        case .hamstringsSemitendinosus: return "Semitendinosus"
        case .hamstringsSemimembranosus: return "Semimembranosus"
        case .glutesMaximus: return "Gluteus Maximus"
        case .glutesMedius: return "Gluteus Medius"
        case .glutesMinimus: return "Gluteus Minimus"
        case .calvesGastrocnemius: return "Gastrocnemius"
        case .calvesSoleus: return "Soleus"
        case .adductors: return "Adduktoren"
        case .abductors: return "Abduktoren"
        case .absUpper: return "Obere Bauchmuskeln"
        case .absLower: return "Untere Bauchmuskeln"
        case .absObliques: return "Seitliche Bauchmuskeln"
        case .absTransverse: return "Quere Bauchmuskeln"
        case .lowerBack: return "Unterer Rücken"
        case .neck: return "Nacken"
        }
    }
}
```

### Schritt A2: Exercise.swift — Neue Felder hinzufügen

**Datei:** `Exercise.swift`

**A2a — Neue gespeicherte Properties.**
Nach `var secondaryMusclesRaw: [String] = []` (Zeile 66), vor der `@Relationship`-Deklaration (Zeile 68) einfügen:

```swift
    // Feingranulare Muskeldaten (DetailedMuscle rawValues = Supabase-Identifier)
    // Diese Felder werden bei zukünftigen Imports und durch In-Place Enrichment befüllt.
    // Bestehende Exercises haben hier [] — der Fallback auf primaryMusclesRaw greift dann.
    var detailedPrimaryMusclesRaw: [String] = []
    var detailedSecondaryMusclesRaw: [String] = []
```

**A2b — Neue Computed Properties.**
Nach den bestehenden `secondaryMuscles` (ca. Zeile 196–198), vor `allMuscles` (ca. Zeile 201) einfügen:

```swift
    var detailedPrimaryMuscles: [DetailedMuscle] {
        get { detailedPrimaryMusclesRaw.compactMap { DetailedMuscle(rawValue: $0) } }
        set { detailedPrimaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    var detailedSecondaryMuscles: [DetailedMuscle] {
        get { detailedSecondaryMusclesRaw.compactMap { DetailedMuscle(rawValue: $0) } }
        set { detailedSecondaryMusclesRaw = newValue.map { $0.rawValue } }
    }
```

**A2c — Compat-Properties anpassen.**
Die bestehenden `primaryMuscles` und `secondaryMuscles` computed properties (ca. Zeile 191–198) ersetzen:

```swift
    var primaryMuscles: [MuscleGroup] {
        get {
            // Bevorzugt: Aus DetailedMuscle ableiten (feingranular → grob)
            if !detailedPrimaryMusclesRaw.isEmpty {
                return Array(Set(detailedPrimaryMuscles.map { $0.parentGroup }))
            }
            // Fallback: Alte Daten direkt lesen (bestehende Exercises)
            return primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
        }
        set { primaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    var secondaryMuscles: [MuscleGroup] {
        get {
            if !detailedSecondaryMusclesRaw.isEmpty {
                return Array(Set(detailedSecondaryMuscles.map { $0.parentGroup }))
            }
            return secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
        }
        set { secondaryMusclesRaw = newValue.map { $0.rawValue } }
    }
```

**A2d — Haupt-Init erweitern (Zeile 71–160).**
Parameter hinzufügen nach `secondaryMusclesRaw: [String] = []`:

```swift
        detailedPrimaryMusclesRaw: [String] = [],
        detailedSecondaryMusclesRaw: [String] = []
```

Assignment hinzufügen nach `self.secondaryMusclesRaw = secondaryMusclesRaw`:

```swift
        self.detailedPrimaryMusclesRaw = detailedPrimaryMusclesRaw
        self.detailedSecondaryMusclesRaw = detailedSecondaryMusclesRaw
```

**Convenience Init (Zeile 305–377) und Supabase Init (Zeile 382–449): NICHT ändern.** Beide haben Default-Werte oder werden in Block B angepasst.

### Validierung Block A

- [ ] Projekt kompiliert ohne Fehler
- [ ] `grep -rn "DetailedMuscle" --include="*.swift"` — nur Treffer in `StrengthTypes.swift` und `Exercise.swift`
- [ ] `grep -rn "detailedPrimaryMusclesRaw" --include="*.swift"` — nur Treffer in `Exercise.swift`
- [ ] Keine anderen Dateien verändert

### → STOPP. Melde Abschluss, warte auf Freigabe für Block B.

---

## Block B: Import-Pipeline + In-Place Enrichment

### Kontext

Aktuell liefert Supabase feingranulare Muscle-Identifier (z.B. `"chest_middle"`, `"biceps_long"`), aber `Exercise.init(from: SupabaseExercise)` mappt diese sofort auf grobe `MuscleGroup`-Werte (`"Brust"`, `"Arme"`) — die feingranulare Information geht verloren. Dieses Block behebt das für neue Imports und reichert bestehende Exercises an.

### Vor dem Start: Code lesen

- `MuscleGroupMapper.swift` — besonders `map(supabaseValue:)` ab Zeile 99
- `Exercise.swift` — `init(from supabase: SupabaseExercise)` ab Zeile 382
- `ExerciseImportManager.swift` — `importFromSupabase()` und `batchImportFromSupabase()`

### Schritt B1: MuscleGroupMapper erweitern

**Datei:** `MuscleGroupMapper.swift`

Am Ende der Datei (nach der bestehenden `map(supabaseValue:)` Extension) eine neue Extension hinzufügen:

```swift
// MARK: - DetailedMuscle Mapping

extension MuscleGroupMapper {
    /// Konvertiert Supabase-Identifier direkt zu DetailedMuscle.
    /// Da DetailedMuscle.rawValue == Supabase-Identifier, ist das ein direktes init.
    static func mapDetailed(supabaseValue: String) -> DetailedMuscle? {
        DetailedMuscle(rawValue: supabaseValue.lowercased())
    }
}
```

**Die bestehende `map(supabaseValue:) -> MuscleGroup?` Methode bleibt komplett unverändert.**

### Schritt B2: Exercise Supabase-Init anpassen

**Datei:** `Exercise.swift`, `init(from supabase: SupabaseExercise)` (ab Zeile 382)

Die Zeilen 388–396 (Muscle-Mapping) ersetzen:

**Bestehend (löschen):**
```swift
        let primaryMusclesList = supabase.primaryMuscles.compactMap {
            MuscleGroupMapper.map(supabaseValue: $0)
        }
        let secondaryMusclesList = supabase.secondaryMuscles.compactMap {
            MuscleGroupMapper.map(supabaseValue: $0)
        }

        let primaryMusclesRaw = primaryMusclesList.map { $0.rawValue }
        let secondaryMusclesRaw = secondaryMusclesList.map { $0.rawValue }
```

**Neu (einfügen):**
```swift
        // Feingranulare Muskeln: Supabase-Identifier direkt als DetailedMuscle speichern
        let detailedPrimaryList = supabase.primaryMuscles.compactMap {
            MuscleGroupMapper.mapDetailed(supabaseValue: $0)
        }
        let detailedSecondaryList = supabase.secondaryMuscles.compactMap {
            MuscleGroupMapper.mapDetailed(supabaseValue: $0)
        }

        // DetailedMuscle rawValues speichern (verlustfrei)
        let detailedPrimaryMusclesRaw = detailedPrimaryList.map { $0.rawValue }
        let detailedSecondaryMusclesRaw = detailedSecondaryList.map { $0.rawValue }

        // Grobe MuscleGroup für Compat ableiten (bestehende Views nutzen das weiterhin)
        let primaryMusclesRaw = Array(Set(detailedPrimaryList.map { $0.parentGroup.rawValue }))
        let secondaryMusclesRaw = Array(Set(detailedSecondaryList.map { $0.parentGroup.rawValue }))
```

Dann im `self.init(...)` Aufruf (ab Zeile 413) die neuen Parameter hinzufügen, nach `secondaryMusclesRaw: secondaryMusclesRaw`:

```swift
            detailedPrimaryMusclesRaw: detailedPrimaryMusclesRaw,
            detailedSecondaryMusclesRaw: detailedSecondaryMusclesRaw
```

### Schritt B3: In-Place Enrichment für bestehende Exercises

**Datei:** `ExerciseImportManager.swift`

Neue Methode am Ende der Klasse hinzufügen (vor der schließenden `}`):

```swift
    // MARK: - In-Place Enrichment

    /// Reichert bestehende Exercises um feingranulare DetailedMuscle-Daten an.
    /// Lädt Exercises von Supabase und aktualisiert NUR die neuen Felder.
    /// Alle Relationships, Favoriten, RepRanges, Trainingspläne etc. bleiben komplett unberührt.
    ///
    /// SICHERHEITS-GARANTIE: Diese Methode löscht KEINE Exercises und ändert KEINE
    /// bestehenden Felder. Sie befüllt ausschließlich detailedPrimaryMusclesRaw und
    /// detailedSecondaryMusclesRaw auf bestehenden Objekten.
    static func enrichWithDetailedMuscles(
        context: ModelContext,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws {
        print("🔬 Starte DetailedMuscle Enrichment...")

        // 1. Alle Supabase-Exercises laden (mit Muscle-Identifiers)
        let supabaseExercises = try await SupabaseExerciseService.shared.fetchAllExercises()
        print("📥 \(supabaseExercises.count) Exercises von Supabase geladen")

        // 2. Lokale Exercises mit apiID laden
        let descriptor = FetchDescriptor<Exercise>()
        let allLocal = try context.fetch(descriptor)
        let localWithApiID = allLocal.filter { $0.apiID != nil }
        print("📦 \(localWithApiID.count) lokale Exercises mit apiID gefunden")

        // 3. Lookup: apiID → lokale Exercise
        let localByApiID = Dictionary(
            uniqueKeysWithValues: localWithApiID.compactMap { ex -> (UUID, Exercise)? in
                guard let apiID = ex.apiID else { return nil }
                return (apiID, ex)
            }
        )

        // 4. Anreicherung — NUR die neuen Felder setzen
        var enriched = 0
        var skipped = 0
        for (index, supabaseExercise) in supabaseExercises.enumerated() {
            guard let local = localByApiID[supabaseExercise.id] else {
                skipped += 1
                continue
            }

            // Nur befüllen wenn noch leer (idempotent)
            guard local.detailedPrimaryMusclesRaw.isEmpty else {
                skipped += 1
                continue
            }

            local.detailedPrimaryMusclesRaw = supabaseExercise.primaryMuscles
                .compactMap { DetailedMuscle(rawValue: $0.lowercased())?.rawValue }
            local.detailedSecondaryMusclesRaw = supabaseExercise.secondaryMuscles
                .compactMap { DetailedMuscle(rawValue: $0.lowercased())?.rawValue }

            enriched += 1
            progressHandler?(index + 1, supabaseExercises.count)

            // Zwischenspeichern alle 100 Exercises
            if enriched % 100 == 0 {
                try context.save()
            }
        }

        // Finale Speicherung
        try context.save()

        print("✅ Enrichment abgeschlossen:")
        print("   - Angereichert: \(enriched)")
        print("   - Übersprungen: \(skipped)")
    }
```

### Validierung Block B

- [ ] Projekt kompiliert ohne Fehler
- [ ] `MuscleGroupMapper.swift` — bestehende `map()` Methode unverändert, neue `mapDetailed()` hinzugefügt
- [ ] Ein neuer Supabase-Import speichert `detailedPrimaryMusclesRaw` korrekt (z.B. `["chest_middle"]` statt `["Brust"]`)
- [ ] Die bestehende `primaryMusclesRaw` wird weiterhin korrekt befüllt
- [ ] `enrichWithDetailedMuscles()` kompiliert und ist aufrufbar
- [ ] Keine Exercises gelöscht, keine Relationships verändert

### → STOPP. Melde Abschluss, warte auf Freigabe für Block C.

---

## Block C: Heatmap Types + CalcEngine + ViewModel

### Kontext

Die Datengrundlage steht (Block A + B). Jetzt werden die reinen Logik-Dateien erstellt — keine UI, keine Views. Drei neue Dateien.

### Schritt C1: MuscleHeatmapTypes.swift erstellen

**Neue Datei:** `MuscleHeatmapTypes.swift`

Standard MotionCore File-Header verwenden (Abschnitt: Muskel-Heatmap).

Inhalte:

**HeatLevel Enum** — 6 Stufen für die Farbskala:

```swift
enum HeatLevel: Int, CaseIterable, Comparable {
    case none = 0
    case veryLow = 1
    case low = 2
    case medium = 3
    case high = 4
    case veryHigh = 5

    static func < (lhs: HeatLevel, rhs: HeatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// SwiftUI-Farbe für die Legende und Cards
    var color: Color {
        switch self {
        case .none:     return Color.gray.opacity(0.3)
        case .veryLow:  return Color(hex: "#3B82F6")
        case .low:      return Color(hex: "#22D3EE")
        case .medium:   return Color(hex: "#22C55E")
        case .high:     return Color(hex: "#F59E0B")
        case .veryHigh: return Color(hex: "#EF4444")
        }
    }

    /// Hex-Farbe für SVG CSS-Injection
    var hexColor: String {
        switch self {
        case .none:     return "#9CA3AF"
        case .veryLow:  return "#3B82F6"
        case .low:      return "#22D3EE"
        case .medium:   return "#22C55E"
        case .high:     return "#F59E0B"
        case .veryHigh: return "#EF4444"
        }
    }

    /// Deutscher Anzeigename
    var displayName: String {
        switch self {
        case .none:     return "Nicht trainiert"
        case .veryLow:  return "Sehr wenig"
        case .low:      return "Wenig"
        case .medium:   return "Moderat"
        case .high:     return "Viel"
        case .veryHigh: return "Sehr viel"
        }
    }

    /// Erstellt HeatLevel aus relativem Wert (0.0 - 1.0)
    init(relativeValue: Double) {
        switch relativeValue {
        case ..<0.01:   self = .none
        case ..<0.10:   self = .veryLow
        case ..<0.25:   self = .low
        case ..<0.50:   self = .medium
        case ..<0.75:   self = .high
        default:        self = .veryHigh
        }
    }
}
```

**MuscleHeatData Struct** — Daten pro SVG-Region:

```swift
struct MuscleHeatData: Identifiable {
    let id: String  // = svgRegionId
    let svgRegionId: String
    let displayName: String
    let totalVolume: Double
    let totalSets: Int
    let relativeIntensity: Double  // 0.0 - 1.0
    let heatLevel: HeatLevel
    let lastTrainedDate: Date?
    let contributingMuscles: [DetailedMuscle]

    var isNeglected: Bool { heatLevel <= .veryLow }

    var daysSinceLastTrained: Int? {
        guard let date = lastTrainedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }

    var volumeFormatted: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk kg", totalVolume / 1000)
        }
        return String(format: "%.0f kg", totalVolume)
    }
}
```

**MuscleHeatmapAnalysis Struct** — Gesamtergebnis:

```swift
struct MuscleHeatmapAnalysis {
    let timeframe: SummaryTimeframe
    let analysisDate: Date
    let regionData: [String: MuscleHeatData]  // Key = svgRegionId
    let totalVolume: Double
    let totalSets: Int

    /// Vernachlässigte Regionen (sortiert: am wenigsten trainierte zuerst)
    var neglectedRegions: [MuscleHeatData] {
        regionData.values
            .filter { $0.isNeglected }
            .sorted { $0.totalVolume < $1.totalVolume }
    }

    /// Top 5 meisttrainierte Regionen
    var topRegions: [MuscleHeatData] {
        Array(regionData.values
            .sorted { $0.totalVolume > $1.totalVolume }
            .prefix(5))
    }

    /// Gibt HeatData für eine SVG-Region zurück
    func data(for svgRegionId: String) -> MuscleHeatData? {
        regionData[svgRegionId]
    }

    /// CSS für SVG-Injection (dynamische Einfärbung der Muskelgruppen)
    var svgStylesCSS: String {
        regionData.map { svgId, data in
            "#\(svgId) path { fill: \(data.heatLevel.hexColor) !important; }"
        }.joined(separator: "\n")
    }
}
```

### Schritt C2: MuscleHeatmapCalcEngine.swift erstellen

**Neue Datei:** `MuscleHeatmapCalcEngine.swift`

Standard File-Header. Reiner Struct (CalcEngine Pattern — keine State, keine Side-Effects).

```swift
import Foundation

struct MuscleHeatmapCalcEngine {

    // MARK: - Haupt-Analyse

    func analyze(
        sessions: [StrengthSession],
        timeframe: SummaryTimeframe
    ) -> MuscleHeatmapAnalysis {

        // 1. Sessions im Zeitraum filtern
        let filteredSessions = filterSessions(sessions, for: timeframe)

        // 2. Volumen pro SVG-Region aggregieren
        var volumeByRegion: [String: Double] = [:]
        var setsByRegion: [String: Int] = [:]
        var lastTrainedByRegion: [String: Date] = [:]
        var musclesByRegion: [String: Set<DetailedMuscle>] = [:]

        for session in filteredSessions {
            for set in session.safeExerciseSets where set.isCompleted {
                let volume = set.weight * Double(set.reps)
                guard volume > 0 else { continue }

                // Primäre Muskeln ermitteln (Fallback-Kette)
                let primaryDetailed = resolveDetailedMuscles(for: set, type: .primary)
                let secondaryDetailed = resolveDetailedMuscles(for: set, type: .secondary)

                // Primäre Muskeln → volle Gewichtung
                for muscle in primaryDetailed {
                    guard let regionId = muscle.svgRegionId else { continue }
                    volumeByRegion[regionId, default: 0] += volume
                    setsByRegion[regionId, default: 0] += 1
                    musclesByRegion[regionId, default: []].insert(muscle)
                    updateLastTrained(&lastTrainedByRegion, regionId: regionId, date: session.date)
                }

                // Sekundäre Muskeln → halbe Gewichtung
                for muscle in secondaryDetailed {
                    guard let regionId = muscle.svgRegionId else { continue }
                    volumeByRegion[regionId, default: 0] += volume * 0.5
                    musclesByRegion[regionId, default: []].insert(muscle)
                    updateLastTrained(&lastTrainedByRegion, regionId: regionId, date: session.date)
                }
            }
        }

        // 3. Relative Intensität und HeatLevel berechnen
        let maxVolume = volumeByRegion.values.max() ?? 1.0

        // 4. MuscleHeatData für alle SVG-Regionen erstellen
        let allSvgRegionIds = Set(DetailedMuscle.allCases.compactMap { $0.svgRegionId })
        var regionData: [String: MuscleHeatData] = [:]

        for regionId in allSvgRegionIds {
            let volume = volumeByRegion[regionId] ?? 0
            let sets = setsByRegion[regionId] ?? 0
            let relativeIntensity = maxVolume > 0 ? volume / maxVolume : 0
            let contributing = Array(musclesByRegion[regionId] ?? [])

            // DisplayName aus dem ersten Contributing-Muscle ableiten
            let displayName = regionDisplayName(for: regionId)

            regionData[regionId] = MuscleHeatData(
                id: regionId,
                svgRegionId: regionId,
                displayName: displayName,
                totalVolume: volume,
                totalSets: sets,
                relativeIntensity: relativeIntensity,
                heatLevel: HeatLevel(relativeValue: relativeIntensity),
                lastTrainedDate: lastTrainedByRegion[regionId],
                contributingMuscles: contributing
            )
        }

        return MuscleHeatmapAnalysis(
            timeframe: timeframe,
            analysisDate: Date(),
            regionData: regionData,
            totalVolume: volumeByRegion.values.reduce(0, +),
            totalSets: setsByRegion.values.reduce(0, +)
        )
    }

    // MARK: - Muscle Resolution (Fallback-Kette)

    private enum MuscleType { case primary, secondary }

    /// Ermittelt DetailedMuscles für ein ExerciseSet.
    /// Fallback-Kette:
    /// 1. exercise?.detailedPrimaryMuscles (feingranular, nach Enrichment)
    /// 2. exercise?.primaryMuscles → alle DetailedMuscle mit passendem parentGroup (grob)
    /// 3. MuscleGroupMapper (Name-basiert, letzter Fallback)
    private func resolveDetailedMuscles(for set: ExerciseSet, type: MuscleType) -> [DetailedMuscle] {
        // 1. Feingranulare Daten vorhanden?
        if let exercise = set.exercise {
            let detailed = type == .primary ? exercise.detailedPrimaryMuscles : exercise.detailedSecondaryMuscles
            if !detailed.isEmpty { return detailed }
        }

        // 2. Grobe MuscleGroup → alle passenden DetailedMuscle
        let muscleGroups: [MuscleGroup]
        if let exercise = set.exercise {
            muscleGroups = type == .primary ? exercise.primaryMuscles : exercise.secondaryMuscles
        } else {
            // 3. Letzter Fallback: MuscleGroupMapper über ExerciseName
            if type == .primary {
                muscleGroups = [set.primaryMuscleGroup].compactMap { $0 }
            } else {
                muscleGroups = set.secondaryMuscleGroups
            }
        }

        // MuscleGroup → alle zugehörigen DetailedMuscle
        return muscleGroups.flatMap { group in
            DetailedMuscle.allCases.filter { $0.parentGroup == group }
        }
    }

    // MARK: - Hilfsmethoden

    private func filterSessions(
        _ sessions: [StrengthSession],
        for timeframe: SummaryTimeframe
    ) -> [StrengthSession] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return sessions
        }

        return sessions.filter { $0.date >= startDate }
    }

    private func updateLastTrained(
        _ dict: inout [String: Date],
        regionId: String,
        date: Date
    ) {
        if let existing = dict[regionId] {
            if date > existing { dict[regionId] = date }
        } else {
            dict[regionId] = date
        }
    }

    /// Deutscher Name für eine SVG-Region
    private func regionDisplayName(for svgRegionId: String) -> String {
        // Finde den ersten DetailedMuscle der auf diese Region mappt
        let mapping: [String: String] = [
            "upper_pecs": "Obere Brust",
            "middle_pecs": "Mittlere Brust",
            "lower_pecs": "Untere Brust",
            "lats": "Latissimus",
            "upper_traps": "Oberer Trapez",
            "lower_traps": "Unterer Trapez",
            "rhomboids": "Rhomboideus",
            "lower_back": "Unterer Rücken",
            "front_delts": "Vordere Schulter",
            "side_delts": "Seitliche Schulter",
            "rear_delts": "Hintere Schulter",
            "biceps": "Bizeps",
            "triceps": "Trizeps",
            "forearms": "Unterarme",
            "quads": "Quadrizeps",
            "hamstrings": "Beinbeuger",
            "glutes": "Gesäß",
            "calves": "Waden",
            "hip_adductor": "Adduktoren",
            "hip_abductor": "Abduktoren",
            "upper_abs": "Obere Bauchmuskeln",
            "lower_abs": "Untere Bauchmuskeln",
            "obliques": "Seitliche Bauchmuskeln",
            "neck": "Nacken"
        ]
        return mapping[svgRegionId] ?? svgRegionId
    }
}
```

### Schritt C3: MuscleHeatmapViewModel.swift erstellen

**Neue Datei:** `MuscleHeatmapViewModel.swift`

Standard File-Header. Pattern identisch zu `ProgressionViewModel.swift`.

```swift
import Foundation
import Observation
import SwiftData

@Observable
final class MuscleHeatmapViewModel {

    // MARK: - Gecachte Ergebnisse

    private(set) var analysis: MuscleHeatmapAnalysis?
    private(set) var isCalculating = false

    // MARK: - Cache-Keys

    private var cachedTimeframe: SummaryTimeframe?
    private var cachedSessionCount: Int = 0

    private let calcEngine = MuscleHeatmapCalcEngine()

    // MARK: - Neuberechnung

    /// Berechnet die Heatmap-Analyse und cached das Ergebnis.
    /// Nur bei echten Änderungen aufrufen (via .task / .onChange).
    func recalculate(sessions: [StrengthSession], timeframe: SummaryTimeframe) {
        guard timeframe != cachedTimeframe || sessions.count != cachedSessionCount else { return }

        isCalculating = true
        analysis = calcEngine.analyze(sessions: sessions, timeframe: timeframe)
        cachedTimeframe = timeframe
        cachedSessionCount = sessions.count
        isCalculating = false
    }
}
```

### Validierung Block C

- [ ] Projekt kompiliert ohne Fehler
- [ ] Drei neue Dateien erstellt: `MuscleHeatmapTypes.swift`, `MuscleHeatmapCalcEngine.swift`, `MuscleHeatmapViewModel.swift`
- [ ] Keine bestehenden Dateien verändert
- [ ] CalcEngine hat keine Side-Effects (reiner Struct)
- [ ] ViewModel folgt dem etablierten @Observable Pattern

### → STOPP. Melde Abschluss, warte auf Freigabe für Block D.

---

## Block D: SVG-Integration + Views + Tab-Umbau

### Kontext

Die Logik steht (Block A–C). Jetzt werden die UI-Dateien erstellt und die Heatmap in den Analyse-Tab integriert.

### Schritt D1: SVG in Bundle aufnehmen

Die Datei `Muscles_Heatmap.svg` befindet sich unter dem folgenden Pfad: /Users/bartosz/Developments/MotionCore/MotionCore/Ressources/Muscles_Heatmap.svg. Sicherstellen, dass sie im Target "MotionCore" enthalten ist (Build Phases → Copy Bundle Resources).

### Schritt D2: MuscleHeatmapSVGView.swift erstellen

**Neue Datei.** `UIViewRepresentable` mit `WKWebView`:
- SVG aus Bundle laden (`Bundle.main.url(forResource: "Muscles_Heatmap", withExtension: "svg")`)
- `WKWebView` transparent, kein Scrolling, `isOpaque = false`
- Dynamisches CSS injizieren aus `MuscleHeatmapAnalysis.svgStylesCSS`
- JavaScript Click-Handler für `<g id>`-Elemente → `WKScriptMessageHandler`
- Callback: `onRegionTap: ((String) -> Void)?` mit svgRegionId
- Borders: `#front_borders`, `#rear_borders` mit angepasstem Stroke
- Dark Mode: CSS `@media (prefers-color-scheme: dark)` für Border-Farben

### Schritt D3: MuscleHeatmapLegend.swift erstellen

**Neue Datei.** Kompakte GlassCard mit horizontalem HStack:
- `HeatLevel.allCases` durchiterieren
- Farbblock (RoundedRectangle) + displayName (caption2) pro Level

### Schritt D4: MuscleHeatmapView.swift erstellen

**Neue Datei.** Haupt-View der Heatmap:

```swift
struct MuscleHeatmapView: View {
    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted },
           sort: \StrengthSession.date, order: .reverse)
    private var sessions: [StrengthSession]

    @EnvironmentObject private var appSettings: AppSettings
    @State private var timeframe: SummaryTimeframe = .month
    @State private var viewModel = MuscleHeatmapViewModel()
    @State private var selectedRegionId: String?
    @State private var showingDetail = false

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    TimeframePicker(selection: $timeframe)

                    // SVG Heatmap
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                Text("Muskelaktivität")
                                    .font(.headline)
                                Spacer()
                                if let analysis = viewModel.analysis {
                                    Text(analysis.totalSets.formatted() + " Sets")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let analysis = viewModel.analysis {
                                MuscleHeatmapSVGView(analysis: analysis) { regionId in
                                    selectedRegionId = regionId
                                    showingDetail = true
                                }
                                .frame(height: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }

                    MuscleHeatmapLegend()

                    // Vernachlässigte Muskeln
                    if let analysis = viewModel.analysis, !analysis.neglectedRegions.isEmpty {
                        neglectedMusclesCard(regions: analysis.neglectedRegions)
                    }

                    // Top trainierte Muskeln
                    if let analysis = viewModel.analysis, !analysis.topRegions.isEmpty {
                        topMusclesCard(regions: analysis.topRegions)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)
        }
        .task { viewModel.recalculate(sessions: sessions, timeframe: timeframe) }
        .onChange(of: sessions) { _, new in viewModel.recalculate(sessions: new, timeframe: timeframe) }
        .onChange(of: timeframe) { _, new in viewModel.recalculate(sessions: sessions, timeframe: new) }
        .sheet(isPresented: $showingDetail) {
            if let regionId = selectedRegionId, let data = viewModel.analysis?.data(for: regionId) {
                MuscleDetailSheet(data: data)
            }
        }
    }

    // Subviews: neglectedMusclesCard, topMusclesCard, MuscleDetailSheet
    // als private var oder eigene Structs implementieren
}
```

### Schritt D5: MuscleHeatmapMiniView.swift erstellen

**Neue Datei.** Kompakte Session-Heatmap für `StrengthDetailView`:
- Input: `StrengthSession`
- Nicht-interaktiv (kein Click-Handler)
- Binär: trainierte Muskeln = Farbe, Rest = grau
- Feste Höhe ~200pt
- Kein ViewModel — direkte inline-Berechnung über die Sets der Session

### Schritt D6: Analyse-Tab Umbau

**Datei:** `ProgressionAnalyseView.swift`

**A) Neues Enum hinzufügen** (am Ende der Datei oder innerhalb der Datei):

```swift
enum AnalyseSegment: String, CaseIterable, Identifiable {
    case progression = "progression"
    case heatmap = "heatmap"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .progression: return "Progression"
        case .heatmap: return "Heatmap"
        }
    }
}
```

**B) ProgressionAnalyseView umbauen:**

- Neue `@State private var selectedSegment: AnalyseSegment = .progression`
- Bestehender Body-Inhalt (ZStack mit AnimatedBackground, ScrollView etc.) in eine `private var progressionContent: some View` extrahieren
- Neuer Body:

```swift
var body: some View {
    VStack(spacing: 0) {
        Picker("Ansicht", selection: $selectedSegment) {
            ForEach(AnalyseSegment.allCases) { segment in
                Text(segment.label).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)

        switch selectedSegment {
        case .progression:
            progressionContent
        case .heatmap:
            MuscleHeatmapView()
        }
    }
}
```

**WICHTIG:** Die bestehenden `@Query`, `@State`, `.task{}`, `.onChange(of:)` Properties und Modifier bleiben alle erhalten — sie werden nur in `progressionContent` verschoben.

### Schritt D7: Mini-Heatmap in StrengthDetailView einfügen

**Datei:** `StrengthDetailView.swift`

In der `body` zwischen `statisticsCard` und `exercisesDetailSection` einfügen:

```swift
                    // Mini-Heatmap
                    MuscleHeatmapMiniView(session: session)
```

### Validierung Block D

- [ ] Projekt kompiliert ohne Fehler
- [ ] Analyse-Tab zeigt Segmented Control mit "Progression" und "Heatmap"
- [ ] "Progression" zeigt den bisherigen Inhalt — identisch wie vorher
- [ ] "Heatmap" zeigt die neue MuscleHeatmapView
- [ ] SVG wird korrekt gerendert (Front + Back sichtbar)
- [ ] Tap auf Muskelgruppe öffnet Detail-Sheet
- [ ] StrengthDetailView zeigt Mini-Heatmap
- [ ] Alle bestehenden Features funktionieren wie vorher

### → Alle Blocks abgeschlossen!

---

## Gesamtübersicht: Neue Dateien

| Datei | Block | Typ |
|---|---|---|
| `MuscleHeatmapTypes.swift` | C | Types |
| `MuscleHeatmapCalcEngine.swift` | C | CalcEngine |
| `MuscleHeatmapViewModel.swift` | C | ViewModel |
| `MuscleHeatmapView.swift` | D | View |
| `MuscleHeatmapSVGView.swift` | D | View (UIViewRepresentable) |
| `MuscleHeatmapMiniView.swift` | D | View |
| `MuscleHeatmapLegend.swift` | D | View |

## Gesamtübersicht: Geänderte Dateien

| Datei | Block | Änderung |
|---|---|---|
| `StrengthTypes.swift` | A | DetailedMuscle Enum ersetzen |
| `Exercise.swift` | A+B | Neue Felder, Compat-Properties, Supabase-Init |
| `MuscleGroupMapper.swift` | B | `mapDetailed()` hinzufügen |
| `ExerciseImportManager.swift` | B | `enrichWithDetailedMuscles()` hinzufügen |
| `ProgressionAnalyseView.swift` | D | Segmented Control Container |
| `StrengthDetailView.swift` | D | MuscleHeatmapMiniView einfügen |
