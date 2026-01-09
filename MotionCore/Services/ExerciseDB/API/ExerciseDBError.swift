//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : API                                                              /
// Datei . . . . : ExerciseDBError.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.01.2026                                                       /
// Beschreibung  : Fehlerbehandlung für ExerciseDB API-Aufrufe                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Definiert alle möglichen Fehlertypen, die bei der Kommunikation   /
//                mit der ExerciseDB API auftreten können. Implementiert            /
//                LocalizedError für benutzerfreundliche Fehlermeldungen.           /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Fehlertypen für ExerciseDB API-Aufrufe
enum ExerciseDBError: LocalizedError {
    case invalidResponse               // Server-Antwort konnte nicht verarbeitet werden
    case httpError(Int)                // HTTP-Fehlercode (z.B. 404, 500)
    case decodingError                 // JSON konnte nicht in Model dekodiert werden
    case networkError                  // Netzwerkverbindung fehlgeschlagen
    case rateLimitExceeded             // API-Rate-Limit überschritten
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Ungültige Server-Antwort"
        case .httpError(let code):
            return "HTTP Fehler: \(code)"
        case .decodingError:
            return "Fehler beim Verarbeiten der Daten"
        case .networkError:
            return "Netzwerkverbindung fehlgeschlagen"
        case .rateLimitExceeded:
            return "API-Rate-Limit überschritten. Bitte später erneut versuchen."
        }
    }
}
