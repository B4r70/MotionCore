//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : API                                                              /
// Datei . . . . : ExerciseDBResponse.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 08.01.2026                                                       /
// Beschreibung  : Model für die API Response von ExerciseDB                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Diese Engine arbeitet mit dem CoreSession-Protokoll und kann      /
//                für CardioSession, StrengthSession und OutdoorSession verwendet   /
//                werden. Typ-spezifische Berechnungen bleiben in den jeweiligen    /
//                spezialisierten CalcEngines (StatisticCalcEngine, etc.)           /
// ---------------------------------------------------------------------------------/
//
import Foundation

    // MARK: - API Service
class ExerciseDBService {
    static let shared = ExerciseDBService()

    private let apiKey = "c93ef2fc70msh2bb751147c5abc5p125bb7jsn5581944e8cbc"
    private let apiHost = "exercisedb.p.rapidapi.com"
    private let baseURL = "https://exercisedb.p.rapidapi.com"

    private init() {}

        // MARK: - Fetch Single Exercise
    func fetchExercise(id: String) async throws -> UnifiedExercise {
        let exercise = try await fetchRapidAPIExercise(id: id)
        return exercise.toUnified()
    }

    private func fetchRapidAPIExercise(id: String) async throws -> RapidAPIExercise {
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        let url = URL(string: "\(baseURL)/exercises/exercise/\(encodedId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        guard http.statusCode == 200 else {
            print("❌ HTTP \(http.statusCode) für ID: \(id)")
            debugDump(data, response)
            throw ExerciseDBError.httpError(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(RapidAPIExercise.self, from: data)
        } catch {
            print("❌ Decoding Error für ID: \(id)")
            debugDump(data, response)
            throw ExerciseDBError.decodingError
        }
    }

        // MARK: - Search Exercises
    func searchExercises(
        query: String? = nil,
        offset: Int = 0,
        limit: Int = 10
    ) async throws -> [UnifiedExercise] {
        let urlString = "\(baseURL)/exercises?offset=\(offset)&limit=\(limit)"

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            debugDump(data, response)
            throw ExerciseDBError.invalidResponse
        }

        let exercises = try JSONDecoder().decode([RapidAPIExercise].self, from: data)
        return exercises.map { $0.toUnified() }
    }

        // MARK: - Search by Name
    func searchByName(_ name: String) async throws -> [UnifiedExercise] {
        let encodedName = encodeForURL(name)
        let url = URL(string: "\(baseURL)/exercises/name/\(encodedName)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            debugDump(data, response)
            throw ExerciseDBError.invalidResponse
        }

        let exercises = try JSONDecoder().decode([RapidAPIExercise].self, from: data)
        return exercises.map { $0.toUnified() }
    }

        // MARK: - Get by Target Muscle  *NEU*
    func getByTarget(_ target: String) async throws -> [UnifiedExercise] {  
        let encodedTarget = encodeForURL(target)  // *NEU*
        let url = URL(string: "\(baseURL)/exercises/target/\(encodedTarget)")!

        var request = URLRequest(url: url)  
        request.httpMethod = "GET"  
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")  
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")  
        request.timeoutInterval = 30  
        
        let (data, response) = try await URLSession.shared.data(for: request)  
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {  
            debugDump(data, response)  
            throw ExerciseDBError.invalidResponse  
        }  
        
        let exercises = try JSONDecoder().decode([RapidAPIExercise].self, from: data)  
        return exercises.map { $0.toUnified() }  
    }  
    
        // MARK: - Get by Equipment  *NEU*
    func getByEquipment(_ equipment: String) async throws -> [UnifiedExercise] {  
        let encodedEquipment = encodeForURL(equipment)  // *NEU*
        let url = URL(string: "\(baseURL)/exercises/equipment/\(encodedEquipment)")!

        var request = URLRequest(url: url)  
        request.httpMethod = "GET"  
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")  
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")  
        request.timeoutInterval = 30  
        
        let (data, response) = try await URLSession.shared.data(for: request)  
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {  
            debugDump(data, response)  
            throw ExerciseDBError.invalidResponse  
        }  
        
        let exercises = try JSONDecoder().decode([RapidAPIExercise].self, from: data)  
        return exercises.map { $0.toUnified() }  
    }  
    
        // MARK: - Get Target List  *NEU*
    func getTargetList() async throws -> [String] {  
        let url = URL(string: "\(baseURL)/exercises/targetList")!  
        var request = URLRequest(url: url)  
        request.httpMethod = "GET"  
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")  
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")  
        request.timeoutInterval = 30  
        
        let (data, _) = try await URLSession.shared.data(for: request)  
        return try JSONDecoder().decode([String].self, from: data)  
    }  

        // MARK: - Get by Body Part
    func getByBodyPart(_ bodyPart: String) async throws -> [UnifiedExercise] {
        let encodedBodyPart = encodeForURL(bodyPart)
        let url = URL(string: "\(baseURL)/exercises/bodyPart/\(encodedBodyPart)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ExerciseDBError.invalidResponse
        }

        let exercises = try JSONDecoder().decode([RapidAPIExercise].self, from: data)
        return exercises.map { $0.toUnified() }
    }

        // MARK: - Get Available Lists
    func getBodyPartList() async throws -> [String] {
        let url = URL(string: "\(baseURL)/exercises/bodyPartList")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([String].self, from: data)
    }

    func getEquipmentList() async throws -> [String] {
        let url = URL(string: "\(baseURL)/exercises/equipmentList")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([String].self, from: data)
    }

        // MARK: - Debug Helper
    private func debugDump(_ data: Data, _ response: URLResponse?) {
        if let http = response as? HTTPURLResponse {
            print("🌐 HTTP \(http.statusCode)")
        }

        let previewBytes = min(500, data.count)
        if let raw = String(data: data.prefix(previewBytes), encoding: .utf8) {
            print("📦 RAW (\(data.count) bytes):", raw)
            if data.count > previewBytes {
                print("   ... (\(data.count - previewBytes) weitere bytes)")
            }
        }
    }

        // MARK: - URL Encoding Helper *NEU*
    private func encodeForURL(_ string: String) -> String {
        string
            .trimmingCharacters(in: .whitespaces)
            .lowercased()  // API erwartet lowercase
            .replacingOccurrences(of: " ", with: "%20")
    }
}
