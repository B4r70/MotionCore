//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : RatingInsightCalcEngine.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.04.2026                                                       /
// Beschreibung  : Erkennt auffällige Muster in Übungsbewertungen                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Pure, zustandslose Berechnung — kein SwiftUI-Import               /
//                Struggling-Insights werden vor Thriving-Insights ausgegeben       /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Erkennt auffällige Bewertungsmuster in abgeschlossenen Krafttrainings.
/// Gibt Insights aus wenn eine Übung consecutiveThreshold-mal hintereinander
/// schlecht (struggling) oder gut (thriving) bewertet wurde.
struct RatingInsightCalcEngine {

    // MARK: - Nested Types

    /// Art des erkannten Musters
    enum InsightType: Equatable {
        case struggling  // Mehrfach schlecht bewertet → Handlungsbedarf
        case thriving    // Mehrfach gut bewertet → positives Feedback
    }

    /// Ein einzelner Insight mit Kontext und Handlungsempfehlung
    struct ExerciseInsight: Identifiable {
        let id: UUID = UUID()
        let exerciseName: String
        let exerciseGroupKey: String
        let insightType: InsightType
        let consecutiveCount: Int   // Anzahl der aufeinanderfolgenden Bewertungen
        let suggestion: String      // Deutschsprachige Handlungsempfehlung
    }

    // MARK: - Konfiguration

    /// Mindestanzahl gleichartiger aufeinanderfolgender Bewertungen für einen Insight
    let consecutiveThreshold: Int

    init(consecutiveThreshold: Int = 3) {
        self.consecutiveThreshold = consecutiveThreshold
    }

    // MARK: - Analyse

    /// Analysiert alle Ratings aus den übergebenen Sessions und gibt relevante Insights zurück.
    /// Struggling-Insights erscheinen zuerst (höherer Handlungsbedarf).
    func analyze(sessions: [StrengthSession]) -> [ExerciseInsight] {
        // Alle Ratings aus allen Sessions sammeln
        let allRatings: [ExerciseRating] = sessions.flatMap { $0.safeExerciseRatings }

        guard !allRatings.isEmpty else { return [] }

        // Ratings nach exerciseGroupKey gruppieren
        let grouped = Dictionary(grouping: allRatings) { $0.exerciseGroupKey }

        var struggling: [ExerciseInsight] = []
        var thriving: [ExerciseInsight] = []

        for (groupKey, ratings) in grouped {
            // Chronologisch sortieren (ältestes zuerst)
            let sorted = ratings.sorted { $0.ratedAt < $1.ratedAt }

            // Name-Snapshot des neuesten Eintrags verwenden
            let exerciseName = sorted.last?.exerciseNameSnapshot ?? groupKey

            // Letzte N Bewertungen prüfen (aufeinanderfolgende Bewertungen am Ende)
            let recent = Array(sorted.suffix(consecutiveThreshold))
            guard recent.count == consecutiveThreshold else { continue }

            let allPoor = recent.allSatisfy { $0.rating == .poor }
            let allGood = recent.allSatisfy { $0.rating == .good }

            if allPoor {
                struggling.append(ExerciseInsight(
                    exerciseName: exerciseName,
                    exerciseGroupKey: groupKey,
                    insightType: .struggling,
                    consecutiveCount: consecutiveThreshold,
                    suggestion: strugglingSuggestion(for: exerciseName, count: consecutiveThreshold)
                ))
            } else if allGood {
                thriving.append(ExerciseInsight(
                    exerciseName: exerciseName,
                    exerciseGroupKey: groupKey,
                    insightType: .thriving,
                    consecutiveCount: consecutiveThreshold,
                    suggestion: thrivingSuggestion(for: exerciseName, count: consecutiveThreshold)
                ))
            }
        }

        // Struggling zuerst, dann Thriving
        return struggling + thriving
    }

    // MARK: - Textbausteine

    private func strugglingSuggestion(for name: String, count: Int) -> String {
        "\(name) war \(count)× hintereinander schlecht. Überprüfe Technik, Gewicht oder Erholung."
    }

    private func thrivingSuggestion(for name: String, count: Int) -> String {
        "\(name) lief \(count)× hintereinander gut. Bereit für eine Steigerung?"
    }
}
