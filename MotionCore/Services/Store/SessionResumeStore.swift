// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : ActiveWorkoutResumeStore.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Beschreibung  : Persistenz-Service für Workout-Resume-States via UserDefaults    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

enum SessionResumeStore {
    private static let key = "motioncore.activeWorkout.resumeState"

    static func save(_ state: SessionResumeState) {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("❌ ResumeState save failed: \(error)")
        }
    }

    static func load() -> SessionResumeState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(SessionResumeState.self, from: data)
        } catch {
            print("❌ ResumeState load failed: \(error)")
            return nil
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
