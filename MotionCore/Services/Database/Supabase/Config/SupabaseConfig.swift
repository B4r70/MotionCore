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

enum SupabaseConfig {
    enum Error: Swift.Error {
        case missingKey(String)
        case invalidURL
    }

    /// Supabase Base URL (OHNE /rest/v1 - wird vom Client hinzugefügt)
    static var url: URL {
        get throws {
            // Debug: Alle Info.plist Keys ausgeben
            print("📋 Alle Info.plist Keys:")
            if let dict = Bundle.main.infoDictionary {
                for (key, value) in dict {
                    if key.contains("SUPABASE") {
                        print("   \(key) = \(value)")
                    }
                }
            }

            // Versuche URL zu laden
            guard let urlString = Bundle.main.object(forInfoDictionaryKey: "MOTIONCORE_SUPABASE_URL") as? String else {
                print("❌ MOTIONCORE_SUPABASE_URL nicht gefunden in Info.plist")
                throw Error.missingKey("MOTIONCORE_SUPABASE_URL")
            }

            print("🔍 URL String aus Info.plist: '\(urlString)'")
            print("🔍 URL String Länge: \(urlString.count) Zeichen")
            print("🔍 URL String isEmpty: \(urlString.isEmpty)")
            print("🔍 URL String enthält $(: \(urlString.contains("$("))")

            guard !urlString.isEmpty,
                  !urlString.contains("$("),
                  !urlString.contains("your-project") else {
                print("❌ URL String ist leer oder nicht ersetzt")
                throw Error.missingKey("MOTIONCORE_SUPABASE_URL nicht konfiguriert")
            }

            guard let url = URL(string: urlString) else {
                print("❌ Kann keine URL erstellen aus: '\(urlString)'")
                throw Error.invalidURL
            }

            print("✅ URL erfolgreich geladen: \(url)")
            return url
        }
    }

    /// Supabase Anon/Public API Key
    static var anonKey: String {
        get throws {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "MOTIONCORE_SUPABASE_ANON_KEY") as? String else {
                print("❌ MOTIONCORE_SUPABASE_ANON_KEY nicht gefunden in Info.plist")
                throw Error.missingKey("MOTIONCORE_SUPABASE_ANON_KEY")
            }

            print("🔍 API Key Länge: \(key.count) Zeichen")
            print("🔍 API Key Prefix: \(key.prefix(20))...")

            guard !key.isEmpty,
                  !key.contains("$("),
                  !key.contains("your_anon_key") else {
                print("❌ API Key ist leer oder nicht ersetzt")
                throw Error.missingKey("MOTIONCORE_SUPABASE_ANON_KEY nicht konfiguriert")
            }

            print("✅ API Key erfolgreich geladen")
            return key
        }
    }
}
