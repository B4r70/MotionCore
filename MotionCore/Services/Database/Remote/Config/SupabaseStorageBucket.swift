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

enum SupabaseStorageBucket: String {
    case exerciseVideos = "exercise-videos"
    case exercisePosters = "exercise-posters"
}

enum SupabaseStorageURLBuilder {

    /// Builds a public URL:
    /// {SUPABASE_URL}/storage/v1/object/public/{bucket}/{path}
    static func publicURL(bucket: SupabaseStorageBucket, path: String) -> URL? {
        // ✅ "try?" weil SupabaseConfig.url bei dir throwen kann
        guard let base = try? SupabaseConfig.url else {
            print("⚠️ SupabaseConfig.url could not be loaded.")
            return nil
        }

        var url = base
        url.appendPathComponent("storage")
        url.appendPathComponent("v1")
        url.appendPathComponent("object")
        url.appendPathComponent("public")
        url.appendPathComponent(bucket.rawValue)

        url.appendPathComponent(
            path
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                .lowercased()
        )
        return url
    }
}
