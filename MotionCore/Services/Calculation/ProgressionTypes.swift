//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : ProgressionTypes.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Reasoning-Cases für ProgressionCalcEngine                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Progressions-Begründung

/// Beschreibt warum die Engine eine bestimmte Gewichts-Empfehlung ausgegeben hat.
/// String-RawValue für Debug-Ausgaben und künftigen Supabase-Sync.
enum ProgressionReasoning: String, Codable {
    case holdWeight
    case increaseWeight
    case bigIncrease
    case rollbackSuggested
    case firstSession
    case readinessReduced
    case noProgression
}
