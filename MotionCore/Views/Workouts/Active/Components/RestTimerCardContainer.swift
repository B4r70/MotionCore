//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / Components                                     /
// Datei . . . . : RestTimerCardContainer.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Kapselt RestTimerCard mit eigenem @ObservedObject für            /
//                 restTimerManager — sekündliche Timer-Ticks lösen nur Re-Renders  /
//                 dieser Sub-View aus, nicht die gesamte ActiveWorkoutView.        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Kapselt RestTimerCard mit eigenem @ObservedObject für restTimerManager.
/// Dadurch lösen sekündliche Timer-Ticks nur Re-Renders dieser Sub-View aus,
/// nicht die gesamte ActiveWorkoutView.
struct RestTimerCardContainer: View {
    @ObservedObject var restTimerManager: RestTimerManager
    let completedSet: ExerciseSet
    let currentSet: ExerciseSet?
    let setsForCurrentExercise: Int
    let supersetNextRoundNames: [String]?
    let onSkip: () -> Void
    let onAdjust: (Int) -> Void

    var body: some View {
        RestTimerCard(
            remainingSeconds: restTimerManager.remainingSeconds,
            targetSeconds: completedSet.restSeconds,
            onSkip: onSkip,
            onAdjust: onAdjust,
            nextExerciseName: currentSet?.exerciseName,
            nextSetNumber: currentSet?.setNumber,
            totalSetsForExercise: setsForCurrentExercise,
            supersetNextRoundNames: supersetNextRoundNames
        )
    }
}
