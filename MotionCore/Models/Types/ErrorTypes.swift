//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Types                                                            /
// Datei . . . . : ErrorTypes.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.01.2026                                                       /
// Beschreibung  : Error Types für gesamte App                                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Supabase Errors
enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "Ungültige URL"
            case .invalidResponse:
                return "Ungültige Server-Antwort"
            case .httpError(let statusCode, let data):
                let msg = String(data: data, encoding: .utf8) ?? "Keine Details"
                return "HTTP Fehler \(statusCode): \(msg)"
            case .decodingError(let error):
                return "Fehler beim Dekodieren: \(error.localizedDescription)"
        }
    }
}


// MARK: - Data IO Errors

    // MARK: - Fehlerbehandlung
    enum DataIOError: LocalizedError {
        case noDataToExport
        case accessDenied
        case importFailed
        case unsupportedVersion
        case deleteError(Error)
        case generalError(Error)

        var errorDescription: String? {
            switch self {
                case .noDataToExport:
                    return "Es sind keine Workouts zum Exportieren vorhanden."
                case .accessDenied:
                    return "Zugriff auf die ausgewählte Datei verweigert."
                case .importFailed:
                    return "Der Importvorgang ist fehlgeschlagen."
                case .unsupportedVersion:
                    return "Das Format der Datei wird von dieser App-Version nicht unterstützt."
                case .deleteError(let error):
                    return "Löschen fehlgeschlagen: \(error.localizedDescription)"
                case .generalError(let error):
                    return "Ein allgemeiner Fehler ist aufgetreten: \(error.localizedDescription)"
            }
        }
    }
