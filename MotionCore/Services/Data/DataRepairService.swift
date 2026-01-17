//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : DataRepairService.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.01.2026                                                       /
// Beschreibung  : Repair-/Bereinigungsfunktionen für MotionCore                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@MainActor
enum DataRepairService {

    // Erhöhe die Version, wenn du später noch weitere Reparaturen ergänzt.
    private static let repairVersionKey = "motioncore.data_repair.version"
    private static let currentRepairVersion = 1

    static func runIfNeeded(container: ModelContainer) {
        let stored = UserDefaults.standard.integer(forKey: repairVersionKey)
        guard stored < currentRepairVersion else {
            print("🧹 DataRepair: already applied (v\(stored)).")
            return
        }

        print("🧹 DataRepair: running v\(currentRepairVersion)...")
        let context = ModelContext(container)

        do {
            try repairExerciseSetSnapshots(context: context)
            try context.save()

            UserDefaults.standard.set(currentRepairVersion, forKey: repairVersionKey)
            print("✅ DataRepair: completed v\(currentRepairVersion).")
        } catch {
            // Wichtig: keine fatalError — App soll starten, auch wenn Repair scheitert
            print("⚠️ DataRepair failed:", error)
        }
    }

    private static func repairExerciseSetSnapshots(context: ModelContext) throws {
        // Hol ALLE ExerciseSets
        let sets = try context.fetch(FetchDescriptor<ExerciseSet>())

        var fixedUUID = 0
        var skippedNoExercise = 0
        var skippedNoApiID = 0

        for s in sets {
            guard let ex = s.exercise else {
                skippedNoExercise += 1
                continue
            }
            guard let api = ex.apiID?.uuidString, !api.isEmpty else {
                skippedNoApiID += 1
                continue
            }

            if s.exerciseUUIDSnapshot != api {
                s.exerciseUUIDSnapshot = api
                fixedUUID += 1
            }

            // Optional: falls du auch MediaAssetSnapshots angleichen willst
            // (nur wenn das sinnvoll ist)
            // if s.exerciseMediaAssetName != ex.mediaAssetName {
            //     s.exerciseMediaAssetName = ex.mediaAssetName
            // }
        }

        print("🧹 DataRepair stats:")
        print("   fixedUUID=\(fixedUUID)")
        print("   skippedNoExercise=\(skippedNoExercise)")
        print("   skippedNoApiID=\(skippedNoApiID)")
    }
}
