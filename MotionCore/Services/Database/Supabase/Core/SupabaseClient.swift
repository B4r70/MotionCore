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

final class SupabaseClient {
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

    // MARK: - Decoder/Encoder

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Supabase liefert z.B. 2026-01-11T13:51:01.816726+00:00 (microseconds!)
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let raw = try container.decode(String.self)

            // 1) ISO8601 mit fractional seconds
            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = isoFrac.date(from: raw) {
                return date
            }

            // 2) ISO8601 ohne fractional seconds
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: raw) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(raw)"
            )
        }

        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFrac.string(from: date))
        }

        return encoder
    }

    // MARK: - HTTP

    private func makeRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseError.httpError(statusCode: http.statusCode, data: data)
        }
    }

    // MARK: - Public API

    func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {

        let fullURL = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseError.invalidURL
        }

        print("🌐 GET \(url.absoluteString)")
        let request = makeRequest(url: url, method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)

        do {
            let decoder = Self.makeDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }

    func post<T: Decodable, Body: Encodable>(
        endpoint: String,
        body: Body
    ) async throws -> T {

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 POST \(url.absoluteString)")
        var request = makeRequest(url: url, method: "POST")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let encoder = Self.makeEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)

        do {
            let decoder = Self.makeDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }

    func post<T: Decodable>(
        endpoint: String,
        body: [String: Any]
    ) async throws -> T {

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 POST \(url.absoluteString)")
        print("📤 Body: \(body)")

        var request = makeRequest(url: url, method: "POST")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)

        do {
            let decoder = Self.makeDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }

    // MARK: - RPC (Remote Procedure Call)

    /// Ruft eine Supabase PostgreSQL Function auf
    /// - Parameters:
    ///   - function: Name der Function (z.B. "search_exercises")
    ///   - params: Dictionary mit Parametern (z.B. ["p_language_code": "de"])
    /// - Returns: Decoded result vom Typ T
    func rpc<T: Decodable>(
        function: String,
        params: [String: Any] = [:]
    ) async throws -> T {

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("rpc")
            .appendingPathComponent(function)

        print("🔧 RPC \(function)")
        print("📤 Params: \(params)")

        var request = makeRequest(url: url, method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)

        do {
            let decoder = Self.makeDecoder()
            let result = try decoder.decode(T.self, from: data)

            // Logging für Arrays
            if let array = result as? [Any] {
                print("✅ RPC returned \(array.count) items")
            } else {
                print("✅ RPC returned result")
            }

            return result
        } catch {
            print("❌ RPC Decode error: \(error)")
            print("   Data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            throw SupabaseError.decodingError(error)
        }
    }
}

// MARK: - Errors

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
