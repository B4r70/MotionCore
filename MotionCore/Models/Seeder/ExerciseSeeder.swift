//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten                                                            /
// Datei . . . . : ExerciseSeeder.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 29.12.2025                                                       /
// Beschreibung  : Seeder für Standard-Übungen in der Übungsbibliothek              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - Exercise Seeder

struct ExerciseSeeder {

    // Prüft ob bereits Übungen existieren und seedet falls nötig (Missing-only)
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        if existingCount == 0 {
            _ = seedMissing(context: context)
        }
    }

    // Fügt nur Übungen hinzu, die anhand ihres Namens noch nicht existieren.
    // - Returns: Anzahl neu eingefügter Übungen
    @discardableResult
    static func seedMissing(context: ModelContext) -> Int {
        let seeds = createAllExercises()

        // Bestehende Namen laden
        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetch(descriptor)) ?? []

        let existingNames = Set(existing.map { normalizeName($0.name) })

        var inserted = 0
        for seed in seeds {
            let key = normalizeName(seed.name)
            guard !existingNames.contains(key) else { continue }
            context.insert(seed)
            inserted += 1
        }

        if inserted > 0 {
            try? context.save()
        }

        print("✅ ExerciseSeeder(seedMissing): \(inserted) neue Übungen ergänzt")
        return inserted
    }

    // Optional: überschreibt bestehende Übungen (nach Name) mit den Seeder-Defaults.
    // - Returns: (inserted, updated)
    @discardableResult
    static func upsertAll(context: ModelContext) -> (inserted: Int, updated: Int) {
        let seeds = createAllExercises()

        let descriptor = FetchDescriptor<Exercise>()
        let existing = (try? context.fetch(descriptor)) ?? []

        // Index: Name(normalized) -> Exercise
        var index: [String: Exercise] = [:]
        index.reserveCapacity(existing.count)
        for e in existing {
            index[normalizeName(e.name)] = e
        }

        var inserted = 0
        var updated = 0

        for seed in seeds {
            let key = normalizeName(seed.name)

            if let current = index[key] {
                // Update existing
                apply(seed: seed, to: current)
                updated += 1
            } else {
                // Insert missing
                context.insert(seed)
                inserted += 1
            }
        }

        if inserted > 0 || updated > 0 {
            try? context.save()
        }

        print("✅ ExerciseSeeder(upsertAll): inserted=\(inserted), updated=\(updated)")
        return (inserted, updated)
    }

    // Löscht alle Übungen und seedet neu (für Reset)
    static func reseed(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        if let existing = try? context.fetch(descriptor) {
            for exercise in existing {
                context.delete(exercise)
            }
        }

        // Danach sauber neu anlegen
        _ = seedMissing(context: context) // oder: seed(context:) wenn du unbedingt willst
    }

    // MARK: - Helpers

    private static func normalizeName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
            .lowercased()
    }

    // Kopiert die Seeder-Werte in ein bestehendes Objekt.
    // Wichtig: wir ändern NICHT die Identität, nur die Felder.
    private static func apply(seed: Exercise, to existing: Exercise) {
        existing.name = seed.name
        existing.exerciseDescription = seed.exerciseDescription
        existing.category = seed.category
        existing.equipment = seed.equipment
        existing.difficulty = seed.difficulty
        existing.movementPattern = seed.movementPattern
        existing.bodyPosition = seed.bodyPosition
        existing.primaryMuscles = seed.primaryMuscles
        existing.secondaryMuscles = seed.secondaryMuscles
        existing.isUnilateral = seed.isUnilateral
        existing.repRangeMin = seed.repRangeMin
        existing.repRangeMax = seed.repRangeMax
        existing.sortIndex = seed.sortIndex
        existing.cautionNote = seed.cautionNote
    }

    // MARK: - Exercise Factory
    
    private static func createAllExercises() -> [Exercise] {
        var exercises: [Exercise] = []
        var sortIndex = 0
        
        // MARK: - BRUST (Chest)
        
        exercises.append(Exercise(
            name: "Bankdrücken (Langhantel)",
            exerciseDescription: "Flach auf der Bank liegend, Langhantel mit schulterbreitem Griff zur Brust senken und explosiv nach oben drücken. Schulterblätter zusammen, Brust raus.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .lying,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .arms],
            repRangeMin: 6,
            repRangeMax: 10,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Schultern nicht nach vorne rollen lassen"
        ))
        
        exercises.append(Exercise(
            name: "Schrägbankdrücken (Langhantel)",
            exerciseDescription: "Bank auf 30-45° Neigung. Langhantel zur oberen Brust senken und nach oben drücken. Betont die obere Brust.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .incline,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kurzhantel-Bankdrücken",
            exerciseDescription: "Flach auf der Bank, Kurzhanteln neben der Brust. Hanteln nach oben drücken und oben leicht zusammenführen.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .lying,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kurzhantel-Schrägbankdrücken",
            exerciseDescription: "Schrägbank 30-45°, Kurzhanteln zur oberen Brust senken. Größerer Bewegungsradius als mit Langhantel.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .incline,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders, .arms],
            isUnilateral: true,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Butterfly (Maschine)",
            exerciseDescription: "Arme seitlich an den Polstern, kontrolliert vor der Brust zusammenführen. Isoliert die Brustmuskulatur.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabelzug-Flys (Mitte)",
            exerciseDescription: "Kabel auf Brusthöhe, Arme vor dem Körper in einem Bogen zusammenführen. Ellbogen leicht gebeugt.",
            category: .isolation,
            equipment: .cable,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.chest],
            secondaryMuscles: [.shoulders],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabelzug-Flys (Hoch-Tief)",
            exerciseDescription: "Kabel oben, Arme nach unten-vorne zusammenführen. Betont die untere Brust.",
            category: .isolation,
            equipment: .cable,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Dips (Brust-betont)",
            exerciseDescription: "An den Dip-Barren, Oberkörper nach vorne lehnen, tief runter und hoch drücken. Betont Brust mehr als Trizeps.",
            category: .compound,
            equipment: .bodyweight,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .hanging,
            primaryMuscles: [.chest],
            secondaryMuscles: [.arms, .shoulders],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Nicht zu tief bei Schulterproblemen"
        ))
        
        exercises.append(Exercise(
            name: "Liegestütze",
            exerciseDescription: "Hände schulterbreit, Körper gerade, Brust zum Boden senken und hochdrücken. Grundübung für die Brust.",
            category: .compound,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .plank,
            primaryMuscles: [.chest],
            secondaryMuscles: [.arms, .shoulders, .core],
            repRangeMin: 10,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - RÜCKEN (Back)
        
        exercises.append(Exercise(
            name: "Kreuzheben (Konventionell)",
            exerciseDescription: "Füße hüftbreit, Griff schulterbreit. Rücken gerade, Stange nah am Körper nach oben ziehen. Die Königsübung.",
            category: .compound,
            equipment: .barbell,
            difficulty: .advanced,
            movementPattern: .hinge,
            bodyPosition: .standing,
            primaryMuscles: [.back, .legs],
            secondaryMuscles: [.glutes, .core],
            repRangeMin: 5,
            repRangeMax: 8,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Rücken IMMER gerade halten! Bei Schmerzen sofort stoppen."
        ))
        
        exercises.append(Exercise(
            name: "Rumänisches Kreuzheben",
            exerciseDescription: "Beine fast gestreckt, Hüfte nach hinten schieben, Stange an den Beinen entlang senken. Dehnt Hamstrings.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .hinge,
            bodyPosition: .standing,
            primaryMuscles: [.back, .glutes],
            secondaryMuscles: [.legs],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Rücken gerade, nicht runden!"
        ))
        
        exercises.append(Exercise(
            name: "Klimmzüge",
            exerciseDescription: "Schulterbreiter Obergriff, aus dem Hang bis Kinn über die Stange ziehen. Beste Übung für den Lat.",
            category: .compound,
            equipment: .bodyweight,
            difficulty: .advanced,
            movementPattern: .pull,
            bodyPosition: .hanging,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 6,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Latzug (Breit)",
            exerciseDescription: "Breiter Obergriff, Stange zur Brust ziehen. Schulterblätter zusammen, Ellbogen nach unten.",
            category: .compound,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Latzug (Eng, Untergriff)",
            exerciseDescription: "Enger Untergriff, Stange zur Brust ziehen. Mehr Bizeps-Beteiligung.",
            category: .compound,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Langhantel-Rudern (Vorgebeugt)",
            exerciseDescription: "Vorgebeugt, Rücken gerade, Stange zum Bauchnabel ziehen. Schulterblätter zusammenpressen.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Unterer Rücken stabil halten"
        ))
        
        exercises.append(Exercise(
            name: "Kurzhantel-Rudern (Einarmig)",
            exerciseDescription: "Eine Hand und Knie auf Bank gestützt, andere Hand zieht Hantel zur Hüfte. Schulterblatt zusammenziehen.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .kneeling,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            isUnilateral: true,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabelrudern (Sitzend)",
            exerciseDescription: "Sitzend am Kabelzug, V-Griff oder breiten Griff zum Bauch ziehen. Brust raus, Rücken gerade.",
            category: .compound,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "T-Bar Rudern",
            exerciseDescription: "Vorgebeugt über der T-Bar, Griff zum Bauch ziehen. Gute Alternative zum Langhantel-Rudern.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.back],
            secondaryMuscles: [.arms],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Face Pulls",
            exerciseDescription: "Kabel auf Gesichtshöhe, Seil zum Gesicht ziehen mit Außenrotation. Super für Schultergesundheit.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.back, .shoulders],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Hyperextensions",
            exerciseDescription: "Am Hyperextension-Gerät, Oberkörper senken und mit unterem Rücken wieder anheben.",
            category: .isolation,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .hinge,
            bodyPosition: .lying,
            primaryMuscles: [.back, .glutes],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - SCHULTERN (Shoulders)
        
        exercises.append(Exercise(
            name: "Schulterdrücken (Langhantel)",
            exerciseDescription: "Stehend oder sitzend, Langhantel von den Schultern über Kopf drücken. Grundübung für Schultermasse.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.arms],
            repRangeMin: 6,
            repRangeMax: 10,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Schulterdrücken (Kurzhanteln)",
            exerciseDescription: "Sitzend, Kurzhanteln neben den Ohren, über Kopf drücken. Größerer Bewegungsradius.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.arms],
            isUnilateral: true,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Arnold Press",
            exerciseDescription: "Kurzhanteln vor dem Gesicht (Untergriff), drehen während dem Hochdrücken zum Obergriff.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.arms],
            isUnilateral: true,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Seitheben (Kurzhanteln)",
            exerciseDescription: "Stehend, Arme seitlich bis Schulterhöhe heben. Ellbogen leicht gebeugt, kontrolliert.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Nicht schwingen! Leichtes Gewicht, saubere Form."
        ))
        
        exercises.append(Exercise(
            name: "Seitheben (Kabel)",
            exerciseDescription: "Einarmig am Kabel, Arm seitlich anheben. Konstante Spannung durch Kabel.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Frontheben",
            exerciseDescription: "Kurzhanteln vor dem Körper nach vorne-oben heben bis Schulterhöhe. Für vordere Schulter.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Reverse Flys (Kurzhanteln)",
            exerciseDescription: "Vorgebeugt, Arme seitlich nach hinten heben. Für hintere Schulter und oberen Rücken.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.back],
            isUnilateral: true,
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Reverse Flys (Maschine)",
            exerciseDescription: "An der Butterfly-Maschine rückwärts sitzend, Arme nach hinten führen.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.back],
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Aufrechtes Rudern",
            exerciseDescription: "Langhantel oder Kurzhanteln eng greifen, an der Körpervorderseite bis Kinnhöhe ziehen.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [.arms],
            repRangeMin: 10,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Kann bei manchen Schulterprobleme verursachen"
        ))
        
        exercises.append(Exercise(
            name: "Shrugs (Kurzhanteln)",
            exerciseDescription: "Kurzhanteln seitlich halten, Schultern zu den Ohren ziehen. Für den Trapezmuskel.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.shoulders],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - ARME (Arms)
        
        exercises.append(Exercise(
            name: "Langhantel-Curls",
            exerciseDescription: "Stehend, Langhantel im Untergriff, nur mit den Bizeps beugen. Ellbogen am Körper.",
            category: .isolation,
            equipment: .barbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Nicht schwingen!"
        ))
        
        exercises.append(Exercise(
            name: "Kurzhantel-Curls",
            exerciseDescription: "Stehend oder sitzend, Kurzhanteln abwechselnd oder gleichzeitig curlen.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 10,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Hammer Curls",
            exerciseDescription: "Kurzhanteln mit neutralem Griff (Daumen oben) curlen. Trainiert auch den Unterarm.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 10,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Konzentrations-Curls",
            exerciseDescription: "Sitzend, Ellbogen am Oberschenkel abgestützt, Kurzhantel curlen. Maximale Isolation.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabelzug-Curls",
            exerciseDescription: "Am unteren Kabelzug, Seil oder Stange curlen. Konstante Spannung.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Trizepsdrücken (Kabel, Seil)",
            exerciseDescription: "Am hohen Kabel, Seil nach unten drücken. Ellbogen am Körper fixiert.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Trizepsdrücken (Kabel, Stange)",
            exerciseDescription: "Am hohen Kabel, gerade Stange nach unten drücken. Klassiker für Trizeps.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "French Press (SZ-Stange)",
            exerciseDescription: "Liegend, SZ-Stange über der Stirn, nur Unterarme beugen und strecken.",
            category: .isolation,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .lying,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Ellbogen stabil halten, nicht zu schwer"
        ))
        
        exercises.append(Exercise(
            name: "Trizeps Kickbacks",
            exerciseDescription: "Vorgebeugt, Oberarm parallel zum Boden, Unterarm nach hinten strecken.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Dips (Trizeps-betont)",
            exerciseDescription: "An den Dip-Barren, Oberkörper aufrecht, tief runter und hoch drücken. Betont Trizeps.",
            category: .compound,
            equipment: .bodyweight,
            difficulty: .intermediate,
            movementPattern: .push,
            bodyPosition: .hanging,
            primaryMuscles: [.arms],
            secondaryMuscles: [.chest, .shoulders],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Überkopf-Trizepsstrecken (Kurzhantel)",
            exerciseDescription: "Sitzend oder stehend, Kurzhantel mit beiden Händen hinter dem Kopf, Arme strecken.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.arms],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - BEINE (Legs)
        
        exercises.append(Exercise(
            name: "Kniebeugen (Langhantel)",
            exerciseDescription: "Stange auf dem oberen Rücken, tief in die Hocke gehen, explosiv aufstehen. König der Übungen.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .squat,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes, .core],
            repRangeMin: 6,
            repRangeMax: 10,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Knie in Richtung Zehen, Rücken gerade!"
        ))
        
        exercises.append(Exercise(
            name: "Frontkniebeugen",
            exerciseDescription: "Stange vorne auf den Schultern, aufrechter Oberkörper, tief beugen. Betont Quadrizeps.",
            category: .compound,
            equipment: .barbell,
            difficulty: .advanced,
            movementPattern: .squat,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes, .core],
            repRangeMin: 6,
            repRangeMax: 10,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Goblet Squats",
            exerciseDescription: "Kurzhantel oder Kettlebell vor der Brust halten, in die Hocke gehen. Gut für Anfänger.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .squat,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes, .core],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Beinpresse",
            exerciseDescription: "Sitzend an der Maschine, Plattform wegdrücken. Knie nicht ganz durchstrecken.",
            category: .compound,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .squat,
            bodyPosition: .seated,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Knie nie ganz durchstrecken!"
        ))
        
        exercises.append(Exercise(
            name: "Ausfallschritte (Kurzhanteln)",
            exerciseDescription: "Mit Kurzhanteln große Schritte nach vorne, hinteres Knie fast zum Boden.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .intermediate,
            movementPattern: .squat,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes],
            isUnilateral: true,
            repRangeMin: 10,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Bulgarische Split Squats",
            exerciseDescription: "Hinterer Fuß auf Bank, vorderes Bein beugen. Sehr effektiv für Beine und Balance.",
            category: .compound,
            equipment: .dumbbell,
            difficulty: .intermediate,
            movementPattern: .squat,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [.glutes],
            isUnilateral: true,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Beinstrecker (Maschine)",
            exerciseDescription: "Sitzend, Beine gegen Polster strecken. Isoliert den Quadrizeps.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }(),
            cautionNote: "Nicht ruckartig, kontrollierte Bewegung"
        ))
        
        exercises.append(Exercise(
            name: "Beinbeuger (Liegend)",
            exerciseDescription: "Liegend, Fersen zum Gesäß ziehen. Für die hinteren Oberschenkel.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .lying,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Beinbeuger (Sitzend)",
            exerciseDescription: "Sitzend, Beine nach unten beugen. Alternative zum liegenden Beinbeuger.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .pull,
            bodyPosition: .seated,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Wadenheben (Stehend)",
            exerciseDescription: "Auf einer Erhöhung, Fersen senken und auf die Zehenspitzen drücken.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .standing,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Wadenheben (Sitzend)",
            exerciseDescription: "Sitzend an der Maschine, Knie gebeugt, Fersen heben. Betont den Schollenmuskel.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - GESÄSS (Glutes)
        
        exercises.append(Exercise(
            name: "Hip Thrust",
            exerciseDescription: "Rücken an Bank gelehnt, Langhantel auf der Hüfte, Hüfte nach oben drücken. Beste Gesäßübung.",
            category: .compound,
            equipment: .barbell,
            difficulty: .intermediate,
            movementPattern: .hinge,
            bodyPosition: .lying,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.legs],
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Glute Bridge",
            exerciseDescription: "Auf dem Rücken liegend, Hüfte nach oben drücken. Mit oder ohne Gewicht.",
            category: .isolation,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .hinge,
            bodyPosition: .lying,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.legs],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabel-Kickbacks",
            exerciseDescription: "Am Kabelzug, Bein nach hinten-oben strecken. Isoliert das Gesäß.",
            category: .isolation,
            equipment: .cable,
            difficulty: .beginner,
            movementPattern: .hinge,
            bodyPosition: .standing,
            primaryMuscles: [.glutes],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Abduktoren (Maschine)",
            exerciseDescription: "Sitzend, Beine gegen Widerstand nach außen drücken. Für die seitliche Hüfte.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.glutes],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Adduktoren (Maschine)",
            exerciseDescription: "Sitzend, Beine gegen Widerstand zusammendrücken. Für die Innenseite der Oberschenkel.",
            category: .isolation,
            equipment: .machine,
            difficulty: .beginner,
            movementPattern: .push,
            bodyPosition: .seated,
            primaryMuscles: [.legs],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        // MARK: - CORE (Bauch)
        
        exercises.append(Exercise(
            name: "Crunches",
            exerciseDescription: "Auf dem Rücken, Schultern vom Boden heben, Bauch anspannen. Klassiker.",
            category: .isolation,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .isometric,
            bodyPosition: .lying,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 15,
            repRangeMax: 25,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Beinheben (Hängend)",
            exerciseDescription: "An der Klimmzugstange hängend, gestreckte Beine anheben. Sehr effektiv.",
            category: .isolation,
            equipment: .bodyweight,
            difficulty: .advanced,
            movementPattern: .isometric,
            bodyPosition: .hanging,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Beinheben (Liegend)",
            exerciseDescription: "Auf dem Rücken, gestreckte Beine anheben und langsam senken.",
            category: .isolation,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .isometric,
            bodyPosition: .lying,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Plank",
            exerciseDescription: "Unterarm-Stütz, Körper gerade wie ein Brett halten. Zeit statt Wiederholungen.",
            category: .core,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .isometric,
            bodyPosition: .plank,
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders],
            repRangeMin: 30,
            repRangeMax: 60,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Side Plank",
            exerciseDescription: "Seitlicher Unterarm-Stütz, Hüfte oben halten. Für die seitlichen Bauchmuskeln.",
            category: .core,
            equipment: .bodyweight,
            difficulty: .intermediate,
            movementPattern: .isometric,
            bodyPosition: .plank,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            isUnilateral: true,
            repRangeMin: 20,
            repRangeMax: 45,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Russian Twist",
            exerciseDescription: "Sitzend, Oberkörper zurückgelehnt, mit Gewicht von Seite zu Seite drehen.",
            category: .isolation,
            equipment: .dumbbell,
            difficulty: .beginner,
            movementPattern: .rotation,
            bodyPosition: .seated,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 15,
            repRangeMax: 25,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Cable Woodchop",
            exerciseDescription: "Am Kabel, diagonale Drehbewegung von oben nach unten oder umgekehrt.",
            category: .isolation,
            equipment: .cable,
            difficulty: .intermediate,
            movementPattern: .rotation,
            bodyPosition: .standing,
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders],
            repRangeMin: 12,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Ab Wheel Rollout",
            exerciseDescription: "Kniend, mit dem Ab-Wheel nach vorne rollen und zurück. Sehr anspruchsvoll.",
            category: .isolation,
            equipment: .other,
            difficulty: .advanced,
            movementPattern: .isometric,
            bodyPosition: .kneeling,
            primaryMuscles: [.core],
            secondaryMuscles: [.shoulders],
            repRangeMin: 8,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Kabelzug-Crunches",
            exerciseDescription: "Kniend am hohen Kabel, Oberkörper einrollen. Ermöglicht Gewichtsprogression.",
            category: .isolation,
            equipment: .cable,
            difficulty: .intermediate,
            movementPattern: .isometric,
            bodyPosition: .kneeling,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 12,
            repRangeMax: 20,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        exercises.append(Exercise(
            name: "Dead Bug",
            exerciseDescription: "Auf dem Rücken, gegenüberliegende Arme und Beine abwechselnd strecken. Core stabil.",
            category: .core,
            equipment: .bodyweight,
            difficulty: .beginner,
            movementPattern: .isometric,
            bodyPosition: .lying,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            repRangeMin: 10,
            repRangeMax: 15,
            sortIndex: { sortIndex += 1; return sortIndex }()
        ))
        
        return exercises
    }
}
