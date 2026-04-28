//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Plan                                                  /
// Datei . . . . : SessionSyncUndoService.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 28.04.2026                                                       /
// Beschreibung  : Snapshot-Capture, JSON-(De)Serialisierung und 72h-Undo für      /
//                 den Session-Plan-Sync (Option A)                                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Snapshot VOR Apply aufrufen, danach Änderungen am Plan.          /
//                Undo: alle Template-Sets löschen, aus Snapshot wiederherstellen.  /
//                Versionsfeld im Wrapper verhindert Decode-Crashes bei zukünftigen  /
//                ExerciseSetSnapshot-Erweiterungen → führt zu "Undo nicht verfügbar".
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

// MARK: - Snapshot Wrapper (mit Version für Forward-Kompatibilität)

private struct SnapshotWrapper: Codable {
    let version: Int
    let snapshots: [ExerciseSetSnapshot]
}

// MARK: - Session-Sync Undo Service

struct SessionSyncUndoService {

    private static let currentVersion = 1
    private static let undoWindowSeconds: Double = 72 * 3600 // 72 Stunden

    // MARK: - Snapshot erfassen

    /// Serialisiert alle aktuellen Template-Sets des Plans als JSON-Snapshot.
    /// Muss VOR dem Apply aufgerufen werden, damit der Snapshot den Vor-Apply-Stand enthält.
    static func captureSnapshot(for plan: TrainingPlan) {
        let snapshots = plan.safeTemplateSets
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { set in
                ExerciseSetSnapshot(
                    exerciseName: set.exerciseName,
                    exerciseNameSnapshot: set.exerciseNameSnapshot,
                    exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
                    exerciseMediaAssetName: set.exerciseMediaAssetName,
                    isUnilateralSnapshot: set.isUnilateralSnapshot,
                    setNumber: set.setNumber,
                    weight: set.weight,
                    weightPerSide: set.weightPerSide,
                    reps: set.reps,
                    targetRepsMin: set.targetRepsMin,
                    targetRepsMax: set.targetRepsMax,
                    targetRIR: set.targetRIR,
                    setKind: set.setKind,
                    restSeconds: set.restSeconds,
                    sortOrder: set.sortOrder,
                    groupId: set.groupId,
                    supersetGroupId: set.supersetGroupId
                )
            }

        let wrapper = SnapshotWrapper(version: currentVersion, snapshots: snapshots)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(wrapper)
            plan.lastSyncSnapshotJSON = String(data: data, encoding: .utf8)
        } catch {
            print("⚠️ SessionSyncUndoService: captureSnapshot fehlgeschlagen: \(error.localizedDescription)")
            plan.lastSyncSnapshotJSON = nil
        }
    }

    // MARK: - Undo (Restore aus Snapshot)

    /// Löscht alle aktuellen Template-Sets und stellt den Zustand aus dem Snapshot wieder her.
    /// Undo-Felder werden danach zurückgesetzt.
    static func undo(plan: TrainingPlan, context: ModelContext) {
        guard let jsonString = plan.lastSyncSnapshotJSON,
              let data = jsonString.data(using: .utf8) else {
            print("⚠️ SessionSyncUndoService: kein Snapshot vorhanden — Undo abgebrochen")
            return
        }

        let wrapper: SnapshotWrapper
        do {
            wrapper = try JSONDecoder().decode(SnapshotWrapper.self, from: data)
        } catch {
            print("⚠️ SessionSyncUndoService: Snapshot-Decode fehlgeschlagen — Undo abgebrochen: \(error.localizedDescription)")
            discard(plan: plan, context: context)
            return
        }

        guard wrapper.version == currentVersion else {
            print("⚠️ SessionSyncUndoService: Snapshot-Version \(wrapper.version) nicht unterstützt — Undo abgebrochen")
            discard(plan: plan, context: context)
            return
        }

        // Alle aktuellen Template-Sets löschen
        let currentSets = plan.safeTemplateSets
        for set in currentSets {
            plan.removeTemplateSets { $0.persistentModelID == set.persistentModelID }
            context.delete(set)
        }

        // Aus Snapshot wiederherstellen
        for snapshot in wrapper.snapshots {
            let restored = ExerciseSet(
                exerciseName: snapshot.exerciseName,
                exerciseNameSnapshot: snapshot.exerciseNameSnapshot,
                exerciseUUIDSnapshot: snapshot.exerciseUUIDSnapshot,
                exerciseMediaAssetName: snapshot.exerciseMediaAssetName,
                isUnilateralSnapshot: snapshot.isUnilateralSnapshot,
                setNumber: snapshot.setNumber,
                weight: snapshot.weight,
                weightPerSide: snapshot.weightPerSide,
                reps: snapshot.reps,
                restSeconds: snapshot.restSeconds,
                setKind: snapshot.setKind,
                isCompleted: false,
                targetRepsMin: snapshot.targetRepsMin,
                targetRepsMax: snapshot.targetRepsMax,
                targetRIR: snapshot.targetRIR,
                groupId: snapshot.groupId,
                sortOrder: snapshot.sortOrder,
                supersetGroupId: snapshot.supersetGroupId
            )
            context.insert(restored)
            plan.addTemplateSet(restored)
        }

        // Undo-Felder zurücksetzen
        plan.lastSyncSnapshotJSON = nil
        plan.lastSessionSyncDate = nil
        plan.lastSessionSyncSourceUUID = nil

        do {
            try context.save()
        } catch {
            print("⚠️ SessionSyncUndoService: save nach undo fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - Undo verfügbar?

    /// True wenn ein gültiger Snapshot vorhanden und lastSessionSyncDate < 72h.
    static func isUndoAvailable(for plan: TrainingPlan) -> Bool {
        guard plan.lastSyncSnapshotJSON != nil,
              let syncDate = plan.lastSessionSyncDate else {
            return false
        }
        return Date().timeIntervalSince(syncDate) < undoWindowSeconds
    }

    // MARK: - Snapshot verwerfen (ohne Restore)

    /// Setzt nur die Snapshot-Felder auf nil — kein Restore der Template-Sets.
    /// context.save() stellt sicher, dass die nil-Werte auch bei einem unmittelbaren
    /// Background-Kill nicht verloren gehen und der Banner beim nächsten Start nicht erneut erscheint.
    static func discard(plan: TrainingPlan, context: ModelContext) {
        plan.lastSyncSnapshotJSON = nil
        plan.lastSessionSyncDate = nil
        plan.lastSessionSyncSourceUUID = nil

        do {
            try context.save()
        } catch {
            print("⚠️ SessionSyncUndoService: save nach discard fehlgeschlagen: \(error.localizedDescription)")
        }
    }
}
