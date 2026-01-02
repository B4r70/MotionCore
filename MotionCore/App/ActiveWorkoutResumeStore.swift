//
//  ActiveWorkoutResumeStore.swift
//  MotionCore
//
//  Created by Barto on 02.01.26.
//


import Foundation

enum ActiveWorkoutResumeStore {
    private static let key = "motioncore.activeWorkout.resumeState"

    static func save(_ state: ActiveWorkoutResumeState) {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("❌ ResumeState save failed: \(error)")
        }
    }

    static func load() -> ActiveWorkoutResumeState? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(ActiveWorkoutResumeState.self, from: data)
        } catch {
            print("❌ ResumeState load failed: \(error)")
            return nil
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}