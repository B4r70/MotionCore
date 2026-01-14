// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseClient.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 13.01.2026                                                       /
// Beschreibung  : Basis-Client für alle Supabase-Datenbankverbindungen             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Basis-Client für die Kommunikation mit Supabase
/// Stellt wiederverwendbare HTTP-Methoden für alle Services bereit
class SupabaseClient {
    static let shared = SupabaseClient()

    private let baseURL: URL
    private let anonKey: String

    private init() {
        do {
            self.baseURL = try SupabaseConfig.url
            self.anonKey = try SupabaseConfig.anonKey
        } catch {
            fatalError("Supabase Konfiguration fehlt: \(error)")
        }
    }

    // MARK: - HTTP Methods

    /// Führt eine GET-Anfrage an Supabase aus
    /// - Parameters:
    ///   - endpoint: Der Table-Name oder Endpunkt (z.B. "exercises" oder "rpc/function_name")
    ///   - queryItems: Optional - Query-Parameter für Filterung/Sortierung
    /// - Returns: Decodiertes Objekt vom Typ T
    func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        // Konstruiere vollständige URL: baseURL + /rest/v1/ + endpoint
        let fullURL = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            print("❌ Konnte URL nicht erstellen:")
            print("   baseURL: \(baseURL)")
            print("   endpoint: \(endpoint)")
            print("   queryItems: \(queryItems ?? [])")
            throw SupabaseError.invalidURL
        }

        // Debug: Ausgabe der finalen URL
        print("🌐 Fetching URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Debug: Ausgabe der Headers
        print("📤 Request Headers:")
        print("   apikey: \(anonKey.prefix(20))...")
        print("   Authorization: Bearer \(anonKey.prefix(20))...")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .cannotFindHost, .dnsLookupFailed:
                print("❌ DNS / Hostname konnte nicht aufgelöst werden: \(error.code.rawValue) \(error.localizedDescription)")
                throw SupabaseError.network(error)
            default:
                throw SupabaseError.network(error)
            }
        } catch {
            throw error
        }

        // Debug: Response Status
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response Status: \(httpResponse.statusCode)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error \(httpResponse.statusCode)")
            print("   Response: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(T.self, from: data)
            print("✅ Decode successful")
            return result
        } catch {
            print("❌ Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }

    /// Führt eine POST-Anfrage an Supabase aus
    /// - Parameters:
    ///   - endpoint: Der Table-Name oder Endpunkt
    ///   - body: Das zu sendende Objekt (wird zu JSON encodiert)
    /// - Returns: Decodiertes Response-Objekt vom Typ T
    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body
    ) async throws -> T {
        // Konstruiere vollständige URL: baseURL + /rest/v1/ + endpoint
        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 Posting to URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .cannotFindHost, .dnsLookupFailed:
                print("❌ DNS / Hostname konnte nicht aufgelöst werden: \(error.code.rawValue) \(error.localizedDescription)")
                throw SupabaseError.network(error)
            default:
                throw SupabaseError.network(error)
            }
        } catch {
            throw error
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response Status: \(httpResponse.statusCode)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error \(httpResponse.statusCode)")
            print("   Response: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    /// Führt eine POST-Anfrage mit Dictionary-Body an Supabase aus (für RPC-Calls)
    /// - Parameters:
    ///   - endpoint: Der RPC-Endpunkt
    ///   - body: Dictionary mit Parametern
    /// - Returns: Decodiertes Response-Objekt vom Typ T
    func post<T: Decodable>(
        endpoint: String,
        body: [String: Any]
    ) async throws -> T {
        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 Posting to URL: \(url.absoluteString)")
        print("📤 Body: \(body)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        // JSON Serialization statt Encoder
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .cannotFindHost, .dnsLookupFailed:
                print("❌ DNS / Hostname konnte nicht aufgelöst werden: \(error.code.rawValue) \(error.localizedDescription)")
                throw SupabaseError.network(error)
            default:
                throw SupabaseError.network(error)
            }
        } catch {
            throw error
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response Status: \(httpResponse.statusCode)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error \(httpResponse.statusCode)")
            print("   Response: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let result = try decoder.decode(T.self, from: data)
            print("✅ Decode successful")
            return result
        } catch {
            print("❌ Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }
}

// MARK: - Error Types

enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case network(URLError)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Server-Antwort"
        case .httpError(let statusCode, let data):
            let message = String(data: data, encoding: .utf8) ?? "Keine Details"
            return "HTTP Fehler \(statusCode): \(message)"
        case .decodingError(let error):
            return "Fehler beim Dekodieren: \(error.localizedDescription)"
        case .network(let error):
            return "Netzwerkfehler: \(error.localizedDescription) (\(error.code.rawValue))"
        }
    }
}
