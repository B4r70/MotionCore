// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hauptprogramm                                                    /
// Datei . . . . : MotionCoreApp.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Einstiegspunkt und Startkonfiguration für den Ablauf der App     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
import SwiftData
import SwiftUI
import os.log

@main
struct MotionCoreApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var activeSessionManager = ActiveSessionManager.shared

    @State private var showSessionRestoreAlert = false
    @State private var pendingRestoreInfo: (sessionID: String, workoutType: WorkoutType)?

    // ✅ Wenn true: KEIN Fallback, Crash wenn CloudKit nicht geht
    private static let requireCloudKit: Bool = false

    // ✅ DEINE AppGroup-ID eintragen (Xcode → App Groups)
    private static let appGroupID: String = "group.com.barto.motioncore"

    private static let log = Logger(subsystem: "MotionCore", category: "SwiftData")

    private static let appSchema = Schema([
        CardioSession.self,
        StrengthSession.self,
        OutdoorSession.self,
        ExerciseSet.self,
        Exercise.self,
        TrainingPlan.self,
        TrainingEntry.self
    ])

    // ✅ CloudKit im Simulator standardmäßig AUS (Widget/LiveActivity kann trotzdem via AppGroup lokal lesen)
    private static var useCloudKit: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    // ✅ Bau den Store-URL im AppGroup-Container + stelle sicher, dass der Ordner existiert
    private static func appGroupStoreURL() -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("❌ AppGroup container not found. Check App Groups entitlement: \(appGroupID)")
        }

        let appSupport = container.appendingPathComponent("Library/Application Support", isDirectory: true)
        let storeURL = appSupport.appendingPathComponent("default.store")

        do {
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        } catch {
            fatalError("❌ Could not create AppGroup Application Support directory: \(error)")
        }

        return storeURL
    }

    // ✅ Container wird einmal gebaut
    let sharedModelContainer: ModelContainer = {
        let storeURL = MotionCoreApp.appGroupStoreURL()

        do {
            let config = ModelConfiguration(
                schema: MotionCoreApp.appSchema,
                url: storeURL,
                cloudKitDatabase: MotionCoreApp.useCloudKit ? .automatic : .none
            )

            MotionCoreApp.log.info("✅ Creating ModelContainer (CloudKit=\(MotionCoreApp.useCloudKit ? "ON" : "OFF")) store=\(storeURL.path)")
            return try ModelContainer(for: MotionCoreApp.appSchema, configurations: [config])

        } catch {
            MotionCoreApp.log.error("❌ ModelContainer init failed: \(String(describing: error))")

            if MotionCoreApp.requireCloudKit {
                fatalError("💥 CloudKit required but failed: \(error)")
            }

            // Fallback: lokal (aber weiterhin AppGroup-Store, damit Widget/LiveActivity mitliest)
            let localConfig = ModelConfiguration(
                schema: MotionCoreApp.appSchema,
                url: storeURL,
                cloudKitDatabase: .none
            )
            MotionCoreApp.log.warning("⚠️ Falling back to LOCAL (CloudKit OFF) store=\(storeURL.path)")
            return try! ModelContainer(for: MotionCoreApp.appSchema, configurations: [localConfig])
        }
    }()

    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(appSettings)
                .environmentObject(activeSessionManager)
                .preferredColorScheme(appSettings.appTheme.colorScheme)
                .handleSessionLifecycle()
                .onAppear { checkForActiveSession() }
                .alert("Aktive Session gefunden", isPresented: $showSessionRestoreAlert) {
                    Button("Fortsetzen") { restoreSession() }
                    Button("Verwerfen", role: .cancel) {
                        activeSessionManager.discardSession()
                        pendingRestoreInfo = nil
                    }
                } message: {
                    if let info = pendingRestoreInfo {
                        let formattedTime = activeSessionManager.formattedElapsedTime
                        Text("Du hast eine pausierte \(info.workoutType.description)-Session (\(formattedTime)). Möchtest du fortfahren?")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func checkForActiveSession() {
        if let restoreInfo = activeSessionManager.getRestorationInfo() {
            pendingRestoreInfo = restoreInfo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSessionRestoreAlert = true
            }
        }
    }

    private func restoreSession() {
        guard let info = pendingRestoreInfo else { return }
        NotificationCenter.default.post(
            name: .restoreActiveSession,
            object: nil,
            userInfo: ["sessionID": info.sessionID, "workoutType": info.workoutType]
        )
        pendingRestoreInfo = nil
    }
}
