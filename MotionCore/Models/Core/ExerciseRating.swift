//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ExerciseRating.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.04.2026                                                       /
// Beschreibung  : Subjektive Qualitätsbewertung einer Übung nach Abschluss         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Alle Properties haben Defaults → CloudKit-kompatibel              /
//                ratingRaw als String gespeichert (rawValue von ExerciseQualityRating)
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class ExerciseRating {

    // MARK: - Identifikation

    // Stabile UUID für Sync-Tracking (CloudKit-Dedup-Bug beachten, s. SupabaseFullBackupService)
    var ratingUUID: UUID = UUID()

    // MARK: - Übungs-Referenz

    // Stabiler Schlüssel der Übungsgruppe (entspricht ExerciseSet.groupKey)
    var exerciseGroupKey: String = ""

    // Name-Snapshot zum Zeitpunkt der Bewertung (entkoppelt von Umbenennung)
    var exerciseNameSnapshot: String = ""

    // MARK: - Bewertungsdaten

    // Rohwert für CloudKit-Kompatibilität (String statt Enum)
    var ratingRaw: String = "neutral"

    // Zeitpunkt der Bewertung
    var ratedAt: Date = Date()

    // MARK: - Beziehungen

    // Rückbeziehung zur Session — nullify damit Rating nicht die Session blockt beim Löschen
    @Relationship(deleteRule: .nullify) var session: StrengthSession?

    // MARK: - Typisiertes Rating (computed)

    // Gibt die typisierte Bewertung zurück, Fallback auf .neutral
    var rating: ExerciseQualityRating {
        get { ExerciseQualityRating(rawValue: ratingRaw) ?? .neutral }
        set { ratingRaw = newValue.rawValue }
    }

    // MARK: - Initialisierung

    init(
        exerciseGroupKey: String,
        exerciseNameSnapshot: String,
        rating: ExerciseQualityRating,
        ratedAt: Date = Date(),
        session: StrengthSession? = nil
    ) {
        self.exerciseGroupKey = exerciseGroupKey
        self.exerciseNameSnapshot = exerciseNameSnapshot
        self.ratingRaw = rating.rawValue
        self.ratedAt = ratedAt
        self.session = session
    }
}
