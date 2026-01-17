//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseConfig.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 13.01.2026                                                       /
// Beschreibung  : Supabase Konfiguration (liest aus .xcconfig)                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//

import Foundation

private func debugLog(_ message: @autoclosure () -> String) {
#if DEBUG
    print(message())
#endif
}

enum SupabaseConfig {

    enum Error: Swift.Error {
        case missingKey(String)
        case invalidURL
    }

    // MARK: - Supabase Base URL

    // Supabase Base URL (OHNE /rest/v1)
    static var url: URL {
        get throws {
            guard let urlString = Bundle.main
                .object(forInfoDictionaryKey: "MOTIONCORE_SUPABASE_URL") as? String else {
                throw Error.missingKey("MOTIONCORE_SUPABASE_URL")
            }

            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty,
                  !trimmed.contains("$("),
                  !trimmed.contains("your-project") else {
                throw Error.missingKey("MOTIONCORE_SUPABASE_URL not configured")
            }

            guard let url = URL(string: trimmed) else {
                throw Error.invalidURL
            }

            debugLog("✅ Supabase URL loaded: \(url.host ?? url.absoluteString)")
            return url
        }
    }

    // MARK: - Supabase Anon Key

    // Supabase public anon key
    static var anonKey: String {
        get throws {
            guard let key = Bundle.main
                .object(forInfoDictionaryKey: "MOTIONCORE_SUPABASE_ANON_KEY") as? String else {
                throw Error.missingKey("MOTIONCORE_SUPABASE_ANON_KEY")
            }

            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty,
                  !trimmed.contains("$("),
                  !trimmed.contains("your_anon_key") else {
                throw Error.missingKey("MOTIONCORE_SUPABASE_ANON_KEY not configured")
            }

                // 🔒 NIEMALS den Key selbst loggen
            debugLog("🔐 Supabase anon key loaded (length: \(trimmed.count))")

            return trimmed
        }
    }
}
