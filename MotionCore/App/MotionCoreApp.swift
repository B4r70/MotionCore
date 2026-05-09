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
//
import SwiftData
import SwiftUI
import Combine
import os.log

@main
struct MotionCoreApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var activeSessionManager = ActiveSessionManager.shared

    @Environment(\.scenePhase) private var scenePhase

    @State private var showSessionRestoreAlert = false
    @State private var pendingRestoreInfo: (sessionID: String, workoutType: WorkoutType)?

    init() {
        // PhoneSessionManager früh initialisieren damit WCSession sofort aktiviert wird
        _ = PhoneSessionManager.shared
    }

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
        ExerciseMetrics.self,
        ExerciseRating.self,
        Exercise.self,
        TrainingPlan.self,
        Studio.self,
        StudioEquipment.self,
        ExerciseProgressionState.self,
        SessionReadiness.self,
        HealthBaseline.self,
        BodyMeasurement.self
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
                .task {
                    let context = sharedModelContainer.mainContext
                    // 1. Bundle-Seeder zuerst (apiID-basiert, 1324 Übungen)
                    await BundledExerciseSeeder.seedIfNeeded(context: context)
                    // 2. Handgepflegte Übungen nur ergänzen wenn noch nicht vorhanden (Name-basiert)
                    ExerciseSeeder.seedMissing(context: context)
                    // 3. Primary-Studio + Default-Geräte anlegen (idempotent, nur beim ersten Start)
                    DefaultStudioSeeder.seedIfNeeded(context: context)
                    // 4. ExerciseProgressionStates für alle Bestandspläne sicherstellen (Backfill für alte Imports)
                    backfillProgressionStates(context: context)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    let context = sharedModelContainer.mainContext
                    let takesCardioMedication = appSettings.takesCardioMedication
                    Task {
                        let service = HealthBaselineUpdateService(
                            healthKit: .shared,
                            context: context
                        )
                        await service.updateIfNeeded(takesCardioMedication: takesCardioMedication)
                    }
                }
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

    /// Einmaliger Backfill beim App-Start: stellt für alle Pläne ExerciseProgressionStates sicher.
    /// Idempotent — existierende States bleiben unverändert. Kostet nichts wenn alle States schon da sind.
    private func backfillProgressionStates(context: ModelContext) {
        let descriptor = FetchDescriptor<TrainingPlan>()
        guard let plans = try? context.fetch(descriptor) else { return }
        for plan in plans {
            ProgressionStateEnsurer.ensureStates(forPlan: plan, sessionSets: nil, context: context)
        }
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
