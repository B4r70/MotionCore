//
//  SwiftDataFactory.swift
//  MotionCore
//
//  Created by Barto on 18.01.26.
//
/*

import SwiftData
import Foundation
import os.log

enum SwiftDataFactory {
    static let logger = Logger(subsystem: "MotionCore", category: "SwiftData")

    static func makeContainer() -> ModelContainer {
        do {
            // 1) CloudKit-Config
            let cloudConfig = ModelConfiguration(
                schema: Schema([
                    Exercise.self,
                    ExerciseSet.self,
                    StrengthSession.self,
                    TrainingPlan.self,
                    TrainingEntry.self
                ]),
                // IMPORTANT: Use a persistent store (not inMemory) for CloudKit
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            return try ModelContainer(for: cloudConfig)

        } catch {
            logger.error("❌ SwiftData CloudKit container init failed: \(String(describing: error))")

            // 2) Fallback: local-only, to avoid hard crash while you debug CloudKit
            do {
                let localConfig = ModelConfiguration(
                    schema: Schema([
                        Exercise.self,
                        ExerciseSet.self,
                        StrengthSession.self,
                        TrainingPlan.self,
                        TrainingEntry.self
                    ]),
                    isStoredInMemoryOnly: false
                )
                logger.warning("⚠️ Falling back to LOCAL SwiftData container (no CloudKit).")
                return try ModelContainer(for: localConfig)
            } catch {
                logger.critical("💥 Local SwiftData container init also failed: \(String(describing: error))")
                // Final fallback - but at least now you KNOW why in logs
                fatalError("SwiftData init failed completely. Check logs.")
            }
        }
    }
}
*/
