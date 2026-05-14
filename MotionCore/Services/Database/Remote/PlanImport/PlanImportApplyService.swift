// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Database / Remote / PlanImport                       /
// Datei . . . . : PlanImportApplyService.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Reines Mapping: PlanImportPayloadDTO → SwiftData TrainingPlan   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Kein context.save() hier – Caller entscheidet.                   /
//                exerciseNameSnapshot wird IMMER gesetzt, auch bei Exercise-Treffer./
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

/// Stateless CalcEngine-Style: wandelt einen Payload-DTO in einen neuen SwiftData TrainingPlan um.
enum PlanImportApplyService {

    // MARK: - Datums-Parser (wiederverwendet für start_date / end_date)

    private static let iso8601DateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    private static func parseDate(_ string: String?) -> Date? {
        guard let s = string, !s.isEmpty else { return nil }
        return iso8601DateOnly.date(from: s)
    }

    // MARK: - Apply

    /// Erstellt einen neuen `TrainingPlan` inkl. aller `ExerciseSet`-Templates aus dem Payload.
    /// Fügt den Plan via `context.insert` ein — **kein** `context.save()`.
    ///
    /// - Parameters:
    ///   - payload: Der importierte Payload aus `plan_data`.
    ///   - context: Aktiver ModelContext für den Insert.
    /// - Returns: Der neue (noch ungespeicherte) `TrainingPlan`.
    static func apply(payload: PlanImportPayloadDTO, in context: ModelContext) -> TrainingPlan {

        // MARK: Plan anlegen

        let planType = PlanType(rawValue: payload.planType) ?? .mixed
        let startDate = parseDate(payload.startDate) ?? Date()
        let endDate = parseDate(payload.endDate)

        let plan = TrainingPlan(
            title: payload.title,
            planDescription: payload.description,
            startDate: startDate,
            endDate: endDate,
            planType: planType,
            isActive: true
        )

        // MARK: Exercise-Lookup-Dictionaries (einmaliger Fetch, O(1) Lookup danach)

        let exerciseLookup: [String: Exercise] = buildExerciseLookup(in: context)
        let nameLookup: [String: [Exercise]] = buildNameLookup(in: context)

        // MARK: Sets aus Exercises mappen

        for exerciseDTO in payload.exercises {
            // Primärer Lookup via apiID (kanonische UUID aus dem Server-Katalog)
            var foundExercise = exerciseLookup[exerciseDTO.exerciseUuid.lowercased()]

            // Fallback: Name-Lookup (bei Exercises noch nicht im lokalen Katalog per apiID)
            if foundExercise == nil {
                let nameMatches = nameLookup[exerciseDTO.exerciseName] ?? []
                if nameMatches.count == 1 { foundExercise = nameMatches[0] }
            }

            for setDTO in exerciseDTO.sets {
                let set = mapSet(
                    setDTO: setDTO,
                    exerciseDTO: exerciseDTO,
                    foundExercise: foundExercise
                )
                plan.addTemplateSet(set)
            }
        }

        context.insert(plan)
        return plan
    }

    // MARK: - Hilfsmethoden (privat)

    /// Fetcht alle Exercises und baut:
    ///   1. lowercased-UUID-String (apiID) → Exercise  (primärer Lookup)
    ///   2. Name → Exercise  (Fallback für name-based Resolution)
    private static func buildExerciseLookup(in context: ModelContext) -> [String: Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        guard let all = try? context.fetch(descriptor) else { return [:] }

        var dict: [String: Exercise] = [:]
        for exercise in all {
            guard let apiID = exercise.apiID else { continue }
            dict[apiID.uuidString.lowercased()] = exercise
        }
        return dict
    }

    /// Fetcht alle Exercises für name-basierten Fallback-Lookup.
    private static func buildNameLookup(in context: ModelContext) -> [String: [Exercise]] {
        let descriptor = FetchDescriptor<Exercise>()
        guard let all = try? context.fetch(descriptor) else { return [:] }

        var dict: [String: [Exercise]] = [:]
        for exercise in all {
            dict[exercise.name, default: []].append(exercise)
        }
        return dict
    }

    /// Mappt einen `PlanImportSetDTO` auf einen neuen `ExerciseSet`.
    private static func mapSet(
        setDTO: PlanImportSetDTO,
        exerciseDTO: PlanImportExerciseDTO,
        foundExercise: Exercise?
    ) -> ExerciseSet {

        // setKind: Fallback auf .work wenn unbekannter Rohwert
        let setKind = SetKind(rawValue: setDTO.setKind) ?? .work

        // weightPerSide in DTO ist Bool: zeigt an ob weight pro Seite gilt
        let weight: Double
        let weightPerSide: Double
        if setDTO.weightPerSide {
            // Gewicht ist pro Seite angegeben
            weight = 0.0
            weightPerSide = setDTO.weight
        } else {
            weight = setDTO.weight
            weightPerSide = 0.0
        }

        // groupId: Contract sendet null → Mapping auf "" (iOS-Feld ist non-nullable)
        let groupId = exerciseDTO.groupId ?? ""

        // exerciseNameSnapshot: IMMER setzen (auch bei Exercise-Treffer — Regel aus CLAUDE.md)
        let nameSnapshot = exerciseDTO.exerciseName

        let mediaAsset = foundExercise?.mediaAssetName ?? exerciseDTO.exerciseMediaAssetName
        let uuidSnapshot = ExerciseSet.resolveSnapshot(
            existing: exerciseDTO.exerciseUuid,
            exercise: foundExercise
        )
        let isUnilateral = foundExercise?.isUnilateral ?? false

        let set = ExerciseSet(
            exerciseName: exerciseDTO.exerciseName,
            exerciseNameSnapshot: nameSnapshot,
            exerciseUUIDSnapshot: uuidSnapshot,
            exerciseMediaAssetName: mediaAsset,
            isUnilateralSnapshot: isUnilateral,
            setNumber: setDTO.setNumber,
            weight: weight,
            weightPerSide: weightPerSide,
            reps: setDTO.reps,
            duration: setDTO.duration,
            distance: setDTO.distance,
            restSeconds: setDTO.restSeconds,
            setKind: setKind,
            isCompleted: false,
            rpe: 0,
            notes: setDTO.notes,
            targetRepsMin: setDTO.targetRepsMin,
            targetRepsMax: setDTO.targetRepsMax,
            targetRIR: setDTO.targetRir,
            groupId: groupId,
            sortOrder: exerciseDTO.sortOrder,
            supersetGroupId: exerciseDTO.supersetGroupId
        )

        // Exercise-Link setzen falls im lokalen Katalog gefunden
        set.exercise = foundExercise

        return set
    }
}
