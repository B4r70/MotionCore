//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : API                                                              /
// Datei . . . . : ExerciseImportManager.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 08.01.2026                                                       /
// Beschreibung  : Import-Manager für Übungen aus ExerciseDB                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: Exercise Import Manager
// Dieser Manager lädt Übungen von der ExerciseDB API und
// erstellt daraus Exercise-Objekte für die SwiftData-Datenbank.

class ExerciseImportManager {

    // MARK: - Import from API
    static func importFromAPI(context: ModelContext, limit: Int = 10) async throws -> ExerciseImportResult {
        print("🚀 Starte ExerciseDB Import (Limit: \(limit))...")

        // Übungen über unified API laden
        let allExercises = try await ExerciseDBService.shared.searchExercises(offset: 0, limit: limit)

        print("✅ \(allExercises.count) Übungen werden importiert")

        // Bestehende Übungen prüfen
        let existingDescriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(existingDescriptor)
        let existingNames = Set(existingExercises.map { $0.name.lowercased() })
        let existingAPIIDs = Set(existingExercises.compactMap { $0.apiID })

        print("📊 Bestehende Übungen: \(existingExercises.count)")

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        // Für jede Übung importieren
        for (index, apiExercise) in allExercises.enumerated() {
            // Überspringen wenn bereits vorhanden (nach API-ID)
            if existingAPIIDs.contains(apiExercise.id) {
                skipped += 1
                print("⭐️ [\(index+1)/\(allExercises.count)] Überspringe: \(apiExercise.id) (bereits vorhanden)")
                continue
            }

            do {
                print("📥 [\(index+1)/\(allExercises.count)] Importiere: \(apiExercise.name)...")

                let germanName = translateToGerman(apiExercise.name)
                if existingNames.contains(germanName.lowercased()) {
                    skipped += 1
                    print("⭐️ Überspringe: \(apiExercise.name) (Name existiert schon)")
                    continue
                }

                let exercise = createExercise(from: apiExercise)
                context.insert(exercise)

                imported += 1
                print("✅ Importiert: \(apiExercise.name) → \(germanName)")

                // Speichern nach jedem Import
                try context.save()

            } catch {
                let errorMsg = "Fehler bei \(apiExercise.name): \(error.localizedDescription)"
                errors.append(errorMsg)
                print("❌ \(errorMsg)")

                // Bei zu vielen Fehlern abbrechen
                if errors.count > 5 {
                    print("⚠️ Zu viele Fehler (\(errors.count)), breche Batch ab")
                    break
                }
            }
        }

        // Finale Speicherung
        try context.save()

        print("✅ Import abgeschlossen:")
        print("   - Geladen: \(allExercises.count)")
        print("   - Importiert: \(imported)")
        print("   - Übersprungen: \(skipped)")
        print("   - Fehler: \(errors.count)")

        return ExerciseImportResult(
            totalFetched: allExercises.count,
            imported: imported,
            skipped: skipped,
            errors: errors
        )
    }

    // MARK: - Import with Batching (für große Mengen)
    static func importBatch(
        context: ModelContext,
        startIndex: Int = 0,
        batchSize: Int = 10
    ) async throws -> ExerciseImportResult {
        print("🚀 Starte Batch-Import ab Index \(startIndex), Batch-Größe: \(batchSize)")

        let allExercises = try await ExerciseDBService.shared.searchExercises(
            offset: startIndex,
            limit: batchSize
        )

        print("✅ Lade \(allExercises.count) Übungen ab Index \(startIndex)")

        // Bestehende Übungen prüfen
        let existingDescriptor = FetchDescriptor<Exercise>()
        let existingExercises = try context.fetch(existingDescriptor)
        let existingNames = Set(existingExercises.map { $0.name.lowercased() })
        let existingAPIIDs = Set(existingExercises.compactMap { $0.apiID })

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        for (index, apiExercise) in allExercises.enumerated() {
            // Überspringen wenn bereits vorhanden (nach API-ID)
            if existingAPIIDs.contains(apiExercise.id) {
                skipped += 1
                print("⭐️ [\(index+1)/\(allExercises.count)] Überspringe: \(apiExercise.id) (bereits vorhanden)")
                continue
            }

            do {
                print("📥 [\(index+1)/\(allExercises.count)] Importiere: \(apiExercise.name)...")

                let germanName = translateToGerman(apiExercise.name)
                if existingNames.contains(germanName.lowercased()) {
                    skipped += 1
                    print("⭐️ Überspringe: \(apiExercise.name) (Name existiert schon)")
                    continue
                }

                let exercise = createExercise(from: apiExercise)
                context.insert(exercise)

                imported += 1
                print("✅ Importiert: \(apiExercise.name) → \(germanName)")

                // Speichern nach jedem Import
                try context.save()

            } catch {
                let errorMsg = "Fehler bei \(apiExercise.name): \(error.localizedDescription)"
                errors.append(errorMsg)
                print("❌ \(errorMsg)")

                // Bei zu vielen Fehlern abbrechen
                if errors.count > 5 {
                    print("⚠️ Zu viele Fehler (\(errors.count)), breche Batch ab")
                    break
                }
            }

            // Rate Limiting
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        print("✅ Batch-Import abgeschlossen:")
        print("   - Verarbeitet: \(allExercises.count)")
        print("   - Importiert: \(imported)")
        print("   - Übersprungen: \(skipped)")
        print("   - Fehler: \(errors.count)")

        return ExerciseImportResult(
            totalFetched: allExercises.count,
            imported: imported,
            skipped: skipped,
            errors: errors
        )
    }

    // MARK: - Import Single Exercise *NEU*
    /// Importiert eine einzelne Übung aus der API in die Datenbank
    static func importSingleExercise(
        _ apiExercise: UnifiedExercise,
        context: ModelContext
    ) throws -> Bool {
        // Prüfen ob bereits vorhanden
        let apiID = apiExercise.id  // *NEU* - Lokale Konstante für Capture
        let existingDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID == apiID }  // *NEU* - Capture der lokalen Variable
        )
        let existing = try context.fetch(existingDescriptor)

        if !existing.isEmpty {
            print("⭐️ Übung bereits vorhanden: \(apiExercise.name)")
            return false
        }

        let exercise = createExercise(from: apiExercise)
        context.insert(exercise)
        try context.save()

        print("✅ Importiert: \(apiExercise.name)")
        return true
    }

    // MARK: - Delete Imported Exercise *NEU*
    /// Löscht eine aus der API importierte Übung
    static func deleteExercise(
        _ exercise: Exercise,
        context: ModelContext
    ) throws {
        // Nur API-Übungen können gelöscht werden
        guard exercise.isSystemExercise else {
            print("⚠️ Nur API-importierte Übungen können gelöscht werden")
            return
        }

        let name = exercise.name
        context.delete(exercise)
        try context.save()
        print("🗑️ Gelöscht: \(name)")
    }

    // MARK: - Check if Exercise Exists *NEU*
    /// Prüft ob eine Übung bereits in der Datenbank existiert
    static func exerciseExists(
        apiID: String,
        context: ModelContext
    ) -> Bool {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID == apiID }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    // MARK: - Create Exercise from Unified API Data
    private static func createExercise(from api: UnifiedExercise) -> Exercise {
        let exercise = Exercise(
            name: translateToGerman(api.name),
            exerciseDescription: api.description ?? "",
            mediaAssetName: "",
            category: mapCategory(api.category),
            equipment: mapEquipment(api.equipment.first),
            difficulty: mapDifficulty(api.difficulty),
            movementPattern: mapMovementPattern(api.bodyParts.first),
            bodyPosition: mapBodyPosition(api.category),
            primaryMuscles: api.targetMuscles.map { mapMuscleGroup($0) },
            secondaryMuscles: api.secondaryMuscles.map { mapMuscleGroup($0) },
            isCustom: false,
            isFavorite: false,
            isUnilateral: detectUnilateral(api.name),
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: 0,
            cautionNote: "",
            isArchived: false,

            // API-spezifische Felder
            apiID: api.id,
            isSystemExercise: true,
            videoURL: api.videoURL,
            instructions: api.instructions.joined(separator: "\n\n"),
            localVideoFileName: nil,
            apiBodyPart: api.bodyParts.first,
            apiTarget: api.targetMuscles.first,
            apiEquipment: api.equipment.first,
            apiSecondaryMuscles: api.secondaryMuscles
        )

        return exercise
    }

    // MARK: - Mapping Functions

    private static func mapCategory(_ category: String?) -> ExerciseCategory {
        guard let category = category else { return .compound }

        switch category.lowercased() {
        case "strength":
            return .compound
        case "stretching", "plyometrics", "mobility":
            return .cardio
        case "cardio", "olympic weightlifting", "powerlifting":
            return .compound
        case "balance", "rehabilitation":
            return .isolation
        default:
            return .compound
        }
    }

    private static func mapDifficulty(_ level: String?) -> ExerciseDifficulty {
        guard let level = level else { return .intermediate }

        switch level.lowercased() {
        case "beginner":
            return .beginner
        case "intermediate":
            return .intermediate
        case "expert", "advanced":
            return .advanced
        default:
            return .intermediate
        }
    }

    private static func mapMovementPattern(_ bodyPart: String?) -> MovementPattern {
        guard let bodyPart = bodyPart else { return .push }

        switch bodyPart.lowercased() {
        case "back", "lats", "traps":
            return .pull
        case "chest", "shoulders", "triceps":
            return .push
        case "legs", "quads", "hamstrings", "glutes":
            return .squat
        case "core", "abs":
            return .other
        default:
            return .push
        }
    }

    private static func mapBodyPosition(_ category: String?) -> BodyPosition {
        guard let category = category else { return .standing }

        switch category.lowercased() {
        case "strength":
            return .standing
        case "stretching":
            return .lying
        case "plyometrics", "cardio":
            return .standing
        default:
            return .standing
        }
    }

    private static func mapMuscleGroup(_ value: String) -> MuscleGroup {
        let lowercased = value.lowercased()

        switch lowercased {
        // Direkte Muskelgruppen
        case "pectoralis major", "pectoralis minor", "pectorals", "chest":
            return .chest
        case "latissimus dorsi", "lats", "rhomboids", "erector spinae", "lower back", "upper back", "back", "traps", "trapezius", "spine":
            return .back
        case "deltoid", "deltoids", "delts", "shoulders", "deltoid anterior", "deltoid posterior", "deltoid lateral":
            return .shoulders
        case "biceps", "biceps brachii", "triceps", "triceps brachii", "forearms", "brachialis":
            return .arms
        case "quadriceps", "quads", "hamstrings", "calves", "adductors", "abductors", "hip flexors", "legs":
            return .legs
        case "gluteus maximus", "gluteus medius", "glutes", "gluteus":
            return .glutes
        case "rectus abdominis", "obliques", "abs", "abdominals", "core", "serratus anterior", "transverse abdominis":
            return .core
        case "full body", "total body":
            return .fullBody

        default:
            return .other
        }
    }

    private static func mapEquipment(_ equipment: String?) -> ExerciseEquipment {
        guard let equipment = equipment else { return .bodyweight }

        switch equipment.lowercased() {
        case "barbell", "ez barbell", "olympic barbell", "trap bar":
            return .barbell
        case "dumbbell", "dumbbells":
            return .dumbbell
        case "body weight", "bodyweight", "body only", "assisted", "none":
            return .bodyweight
        case "cable", "cables":
            return .cable
        case "machine", "leverage machine", "smith machine", "sled machine",
            "elliptical machine", "stationary bike", "stepmill machine":
            return .machine
        case "kettlebell", "kettlebells":
            return .kettlebell
        case "band", "resistance band", "bands":
            return .band
        case "foam roll", "medicine ball", "stability ball", "bosu ball":
            return .other
        default:
            return .other
        }
    }

    // MARK: - Unilateral Detection

    private static func detectUnilateral(_ exerciseName: String) -> Bool {
        let lowercased = exerciseName.lowercased()

        let unilateralKeywords = [
            "single", "one arm", "one leg", "unilateral",
            "bulgarian", "pistol", "step up", "lunge",
            "single leg", "single arm", "one-arm", "one-leg"
        ]

        return unilateralKeywords.contains { lowercased.contains($0) }
    }

    // MARK: - Translation
    private static func translateToGerman(_ englishName: String) -> String {
        let translations: [String: String] = [
            // Chest
            "barbell bench press": "Bankdrücken Langhantel",
            "dumbbell bench press": "Bankdrücken Kurzhantel",
            "incline barbell bench press": "Schrägbankdrücken Langhantel",
            "incline dumbbell bench press": "Schrägbankdrücken Kurzhantel",
            "decline barbell bench press": "Negativbankdrücken Langhantel",
            "decline dumbbell bench press": "Negativbankdrücken Kurzhantel",
            "push-up": "Liegestütze",
            "push up": "Liegestütze",
            "cable fly": "Kabelflys",
            "dumbbell fly": "Kurzhantel Flys",
            "chest dip": "Brust-Dips",
            "dip": "Dips",
            "bench press": "Bankdrücken",

            // Back
            "barbell bent over row": "Vorgebeugtes Rudern Langhantel",
            "dumbbell row": "Kurzhantelrudern",
            "one arm dumbbell row": "Einarmiges Kurzhantelrudern",
            "pull-up": "Klimmzug",
            "pull up": "Klimmzug",
            "chin up": "Chin-up",
            "chin-up": "Chin-up",
            "lat pulldown": "Latzug",
            "deadlift": "Kreuzheben",
            "barbell deadlift": "Kreuzheben Langhantel",
            "romanian deadlift": "Rumänisches Kreuzheben",
            "seated cable row": "Rudern am Kabel sitzend",
            "cable row": "Kabelrudern",
            "t-bar row": "T-Bar Rudern",

            // Legs
            "squat": "Kniebeuge",
            "barbell squat": "Kniebeuge Langhantel",
            "back squat": "Rückenkniebeuge",
            "front squat": "Frontkniebeuge",
            "goblet squat": "Goblet Squat",
            "leg press": "Beinpresse",
            "leg curl": "Beinbeuger",
            "lying leg curl": "Beinbeuger liegend",
            "seated leg curl": "Beinbeuger sitzend",
            "leg extension": "Beinstrecker",
            "lunge": "Ausfallschritte",
            "walking lunge": "Ausfallschritte gehend",
            "bulgarian split squat": "Bulgarische Split-Kniebeuge",
            "split squat": "Split-Kniebeuge",
            "calf raise": "Wadenheben",
            "standing calf raise": "Wadenheben stehend",
            "seated calf raise": "Wadenheben sitzend",

            // Shoulders
            "military press": "Schulterdrücken",
            "overhead press": "Überkopfdrücken",
            "shoulder press": "Schulterdrücken",
            "barbell shoulder press": "Schulterdrücken Langhantel",
            "dumbbell shoulder press": "Schulterdrücken Kurzhantel",
            "lateral raise": "Seitheben",
            "dumbbell lateral raise": "Seitheben Kurzhantel",
            "front raise": "Frontheben",
            "rear delt fly": "Reverse Flys",
            "face pull": "Face Pulls",
            "arnold press": "Arnold Press",
            "upright row": "Aufrechtes Rudern",

            // Arms - Biceps
            "barbell curl": "Bizeps-Curl Langhantel",
            "dumbbell curl": "Bizeps-Curl Kurzhantel",
            "hammer curl": "Hammer-Curls",
            "concentration curl": "Konzentrationscurls",
            "preacher curl": "Scott-Curls",
            "cable curl": "Bizeps-Curl am Kabel",

            // Arms - Triceps
            "tricep dip": "Dips",
            "tricep pushdown": "Trizepsdrücken am Kabel",
            "triceps pushdown": "Trizepsdrücken am Kabel",
            "overhead tricep extension": "Überkopf Trizepsdrücken",
            "close grip bench press": "Bankdrücken enger Griff",
            "skull crusher": "Stirndrücken",
            "diamond push up": "Diamant-Liegestütze",

            // Core
            "plank": "Unterarmstütz",
            "side plank": "Seitstütz",
            "crunch": "Crunches",
            "sit-up": "Sit-ups",
            "sit up": "Sit-ups",
            "russian twist": "Russian Twist",
            "bicycle crunch": "Fahrrad-Crunches",
            "leg raise": "Beinheben",
            "hanging leg raise": "Beinheben hängend",
            "ab wheel": "Ab Wheel",
            "mountain climber": "Mountain Climbers",

            // Compound
            "clean and jerk": "Umsetzen und Ausstoßen",
            "snatch": "Reißen",
            "thruster": "Thruster",
            "burpee": "Burpees"
        ]

        let lowercased = englishName.lowercased()

        if let translated = translations[lowercased] {
            return translated
        }

        // Intelligenterer Fallback - ersetze englische Wörter
        return englishName
            .replacingOccurrences(of: "barbell", with: "Langhantel", options: .caseInsensitive)
            .replacingOccurrences(of: "dumbbell", with: "Kurzhantel", options: .caseInsensitive)
            .replacingOccurrences(of: "cable", with: "Kabel", options: .caseInsensitive)
            .replacingOccurrences(of: "machine", with: "Maschine", options: .caseInsensitive)
            .replacingOccurrences(of: "press", with: "Drücken", options: .caseInsensitive)
            .capitalized
    }
}
