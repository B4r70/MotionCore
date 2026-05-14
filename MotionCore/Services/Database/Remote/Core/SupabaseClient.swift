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

    private let baseURL: URL?
    private let anonKey: String?

    private init() {
        self.baseURL = try? SupabaseConfig.url
        self.anonKey = try? SupabaseConfig.anonKey
        if baseURL == nil || anonKey == nil {
            print("⚠️ SupabaseClient: Konfiguration fehlt — Supabase deaktiviert")
        }
    }

    // MARK: - Decoder/Encoder

    // Gecachte Formatter – ISO8601DateFormatter ist thread-safe ab iOS 10+
    private static let isoFormatterFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Kein keyDecodingStrategy: Alle Decodable-DTOs haben explizite snake_case CodingKeys.
        // convertFromSnakeCase würde JSON-Keys vorab in camelCase wandeln und das Lookup
        // gegen die rawValues (z.B. "created_at") brechen → keyNotFound.

        // Supabase liefert z.B. 2026-01-11T13:51:01.816726+00:00 (microseconds!)
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            let raw = try container.decode(String.self)

            // 1) ISO8601 mit fractional seconds
            if let date = isoFormatterFractional.date(from: raw) { return date }

            // 2) ISO8601 ohne fractional seconds
            if let date = isoFormatter.date(from: raw) { return date }

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

        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFormatterFractional.string(from: date))
        }

        return encoder
    }

    // MARK: - HTTP

    private func makeRequest(url: URL, method: String) throws -> URLRequest {
        guard let anonKey else { throw SupabaseError.notConfigured }
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
        guard let baseURL else { throw SupabaseError.notConfigured }

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
        let request = try makeRequest(url: url, method: "GET")

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
        guard let baseURL else { throw SupabaseError.notConfigured }

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 POST \(url.absoluteString)")
        var request = try makeRequest(url: url, method: "POST")
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
        guard let baseURL else { throw SupabaseError.notConfigured }

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🌐 POST \(url.absoluteString)")
        print("📤 Body: \(body)")

        var request = try makeRequest(url: url, method: "POST")
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
        guard let baseURL else { throw SupabaseError.notConfigured }

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("rpc")
            .appendingPathComponent(function)

        print("🔧 RPC \(function)")
        print("📤 Params: \(params)")

        var request = try makeRequest(url: url, method: "POST")
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

    // MARK: - Upsert (INSERT OR UPDATE)

    /// Fügt einen einzelnen Datensatz ein oder aktualisiert ihn bei id-Konflikt.
    /// `schema` setzt den PostgREST-`Content-Profile`-Header (Default: `public`).
    /// Das Ziel-Schema muss in den Supabase-Project-API-Settings als „Exposed schema" freigegeben sein.
    func upsert<Body: Encodable>(
        endpoint: String,
        body: Body,
        schema: String? = nil
    ) async throws {
        guard let baseURL else { throw SupabaseError.notConfigured }

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🔄 UPSERT \(url.absoluteString)\(schema.map { " [schema: \($0)]" } ?? "")")
        var request = try makeRequest(url: url, method: "POST")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        if let schema { request.setValue(schema, forHTTPHeaderField: "Content-Profile") }

        let encoder = Self.makeEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }

    /// Batch-Upsert für ein Array von Datensätzen.
    /// `schema` setzt den PostgREST-`Content-Profile`-Header (Default: `public`).
    func upsert<Body: Encodable>(
        endpoint: String,
        body: [Body],
        schema: String? = nil
    ) async throws {
        guard !body.isEmpty else { return }
        guard let baseURL else { throw SupabaseError.notConfigured }

        let url = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        print("🔄 BATCH UPSERT \(url.absoluteString) (\(body.count) Einträge)\(schema.map { " [schema: \($0)]" } ?? "")")
        var request = try makeRequest(url: url, method: "POST")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        if let schema { request.setValue(schema, forHTTPHeaderField: "Content-Profile") }

        let encoder = Self.makeEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }

    // MARK: - PATCH

    /// Aktualisiert Datensätze anhand eines Supabase-Filterstrings.
    /// Beispiel: patchWhere(endpoint: "pending_plan_imports", filter: "id=eq.UUID-STRING", body: body)
    func patchWhere<Body: Encodable>(
        endpoint: String,
        filter: String,
        body: Body
    ) async throws {
        guard !filter.isEmpty else {
            throw SupabaseError.invalidFilter
        }
        guard let baseURL else { throw SupabaseError.notConfigured }

        let fullURL = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.query = filter

        guard let url = components?.url else {
            throw SupabaseError.invalidURL
        }

        print("📝 PATCH \(url.absoluteString)")
        var request = try makeRequest(url: url, method: "PATCH")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let encoder = Self.makeEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }

    // MARK: - DELETE

    /// Löscht Datensätze anhand eines Supabase-Filterstrings.
    /// Beispiel: deleteWhere(endpoint: "exercise_sets", filter: "session_id=eq.UUID-STRING")
    func deleteWhere(
        endpoint: String,
        filter: String
    ) async throws {
        guard !filter.isEmpty else {
            throw SupabaseError.invalidFilter
        }
        guard let baseURL else { throw SupabaseError.notConfigured }

        let fullURL = baseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(endpoint)

        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.query = filter

        guard let url = components?.url else {
            throw SupabaseError.invalidURL
        }

        print("🗑️ DELETE \(url.absoluteString)")
        let request = try makeRequest(url: url, method: "DELETE")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
    }
}

