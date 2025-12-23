//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Mock-Daten                                                       /
// Datei . . . . : WorkoutSessionPreview.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Beispieldaten für die Preview                                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
// MARK: - Preview Data für Canvas
import Foundation

#if DEBUG
extension CardioSession {
    static var previewMockData: [CardioSession] {
        let now = Date()

        return [
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -14, to: now)!,
                duration: 15,
                distance: 3.12,
                calories: 142,
                difficulty: 8,
                heartRate: 128,
                bodyWeight: 101.0,
                intensity: .medium,
                trainingProgram: .random,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -12, to: now)!,
                duration: 30,
                distance: 5.40,
                calories: 280,
                difficulty: 10,
                heartRate: 122,
                bodyWeight: 99.0,
                intensity: .easy,
                trainingProgram: .random,
                cardioDevice: .ergometer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -10, to: now)!,
                duration: 36,
                distance: 7.30,
                calories: 350,
                difficulty: 15,
                heartRate: 131,
                bodyWeight: 96,
                intensity: .medium,
                trainingProgram: .hill,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -9, to: now)!,
                duration: 22,
                distance: 4.80,
                calories: 240,
                difficulty: 9,
                heartRate: 118,
                bodyWeight: 96.0,
                intensity: .easy,
                trainingProgram: .random,
                cardioDevice: .ergometer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -8, to: now)!,
                duration: 15,
                distance: 3.22,
                calories: 153,
                difficulty: 8,
                heartRate: 137,
                bodyWeight: 96.0,
                intensity: .hard,
                trainingProgram: .random,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -7, to: now)!,
                duration: 40,
                distance: 8.20,
                calories: 410,
                difficulty: 8,
                heartRate: 137,
                bodyWeight: 97.0,
                intensity: .hard,
                trainingProgram: .random,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -5, to: now)!,
                duration: 30,
                distance: 6.00,
                calories: 300,
                difficulty: 12,
                heartRate: 124,
                bodyWeight: 98.0,
                intensity: .medium,
                trainingProgram: .fatBurn,
                cardioDevice: .ergometer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -4, to: now)!,
                duration: 26,
                distance: 5.25,
                calories: 260,
                difficulty: 10,
                heartRate: 120,
                bodyWeight: 105.0,
                intensity: .easy,
                trainingProgram: .random,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
                duration: 34,
                distance: 6.50,
                calories: 330,
                difficulty: 13,
                heartRate: 129,
                bodyWeight: 89.0,
                intensity: .medium,
                trainingProgram: .manual,
                cardioDevice: .ergometer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
                duration: 25,
                distance: 4.90,
                calories: 235,
                difficulty: 9,
                heartRate: 116,
                bodyWeight: 110.0,
                intensity: .easy,
                trainingProgram: .random,
                cardioDevice: .crosstrainer
            ),
            CardioSession(
                date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
                duration: 38,
                distance: 7.70,
                calories: 385,
                difficulty: 16,
                heartRate: 140,
                bodyWeight: 91.0,
                intensity: .hard,
                trainingProgram: .random,
                cardioDevice: .ergometer
            )
        ]
    }
}
#endif
