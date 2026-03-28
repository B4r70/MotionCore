//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ProgressionAnalyseCalcEngine.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Aggregierte Progressions-Übersicht über alle trainierten        /
//                 Übungen — delegiert Einzelanalysen an ProgressionCalcEngine.    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct ProgressionAnalyseCalcEngine {

    // MARK: - Input

    let sessions: [StrengthSession]
    let exercises: [Exercise]

    // MARK: - Interne Engine

    private let engine = ProgressionCalcEngine()

    // MARK: - Trainierte Übungen

    /// Alle Übungen, die in mindestens einer Session trainiert wurden (alphabetisch, ohne Duplikate).
    var trainedExercises: [Exercise] {
        let trainedNames: Set<String> = Set(
            sessions.flatMap { session in
                session.safeExerciseSets.compactMap { set -> String? in
                    let name = set.exerciseNameSnapshot
                    return name.isEmpty ? nil : name
                }
            }
        )
        var seen = Set<String>()
        return exercises
            .filter { trainedNames.contains($0.name) }
            .filter { seen.insert($0.name).inserted }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Einzel-Analyse

    /// Vollständige Progressions-Analyse für eine Übung.
    func analysis(for exercise: Exercise) -> ProgressionAnalysis {
        engine.analyze(exercise: exercise, sessions: sessions)
    }

    /// Session-Snapshots für eine Übung, chronologisch aufsteigend (für Charts).
    func snapshots(for exercise: Exercise) -> [SessionSnapshot] {
        Array(engine.extractSnapshots(for: exercise.name, from: sessions).reversed())
    }

    // MARK: - Chart-Daten

    /// Geschätzter 1RM-Verlauf für eine Übung (nur Datenpunkte mit berechenbarem 1RM).
    func oneRMTrend(for exercise: Exercise) -> [TrendPoint] {
        snapshots(for: exercise).compactMap { snapshot -> TrendPoint? in
            guard let oneRM = snapshot.estimatedOneRM else { return nil }
            return TrendPoint(trendDate: snapshot.date, trendValue: oneRM)
        }
    }

    /// Volumen-Verlauf für eine Übung.
    func volumeTrend(for exercise: Exercise) -> [TrendPoint] {
        snapshots(for: exercise).map {
            TrendPoint(trendDate: $0.date, trendValue: $0.totalVolume)
        }
    }

    // MARK: - Aggregierte Übersicht

    /// Alle Analysen auf einmal (lazy über trainedExercises).
    var allAnalyses: [ProgressionAnalysis] {
        trainedExercises.map { analysis(for: $0) }
    }

    /// Anzahl Übungen mit Aufwärtstrend.
    var improvingCount: Int {
        allAnalyses.filter { $0.trend == .improving }.count
    }

    /// Anzahl Übungen mit stabilem Trend (inkl. volatil — konsistent mit ProgressionViewModel).
    var stableCount: Int {
        allAnalyses.filter { $0.trend == .stable || $0.trend == .volatile }.count
    }

    /// Anzahl Übungen mit Abwärtstrend.
    var decliningCount: Int {
        allAnalyses.filter { $0.trend == .declining }.count
    }

    /// Deload-Warnung: mindestens 3 Übungen zeigen einen Abwärtstrend.
    var needsDeload: Bool { decliningCount >= 3 }

    // MARK: - Session-spezifische Analysen

    /// Gibt alle Analysen für Übungen zurück, die in der angegebenen Session trainiert wurden.
    /// Nützlich um eine Workout-Analyse auf die tatsächlich ausgeführten Übungen zu beschränken.
    func analysesForSession(_ session: StrengthSession) -> [ProgressionAnalysis] {
        let trainedNames: Set<String> = Set(
            session.safeExerciseSets.compactMap { set -> String? in
                let name = set.exerciseNameSnapshot
                return name.isEmpty ? nil : name
            }
        )
        return trainedExercises
            .filter { trainedNames.contains($0.name) }
            .map { analysis(for: $0) }
    }
}
