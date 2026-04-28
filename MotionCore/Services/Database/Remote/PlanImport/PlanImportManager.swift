// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Database / Remote / PlanImport                       /
// Datei . . . . : PlanImportManager.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Polling, State und Marker-Retry für Plan-Imports                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : isPolling-Guard verhindert parallele Polling-Aufrufe.             /
//                Marker-Set speichert akzeptierte IDs für Retry bei Netzausfall.   /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation
import SwiftData

// MARK: - ListSheet Trigger (Identifiable Wrapper statt Bool — kein Race-Condition)

/// Identifiable-Wrapper damit `.sheet(item:)` verwendet werden kann (nie `.sheet(isPresented:)`).
struct ListSheetTrigger: Identifiable {
    let id = UUID()
}

// MARK: - Manager

@MainActor
final class PlanImportManager: ObservableObject {

    // MARK: - Published State

    /// Alle kompatiblen, wartenden Import-DTOs (schema_version == supported).
    @Published var pendingImports: [SupabasePendingPlanImportDTO] = []

    /// Ist true wenn mindestens ein Eintrag mit zu hoher schema_version vorhanden ist.
    @Published var schemaMismatchVisible: Bool = false

    /// Aktiver Preview-DTO (nil = Preview-Sheet geschlossen).
    @Published var activeImport: SupabasePendingPlanImportDTO?

    /// Non-nil = List-Sheet anzeigen.
    @Published var listTrigger: ListSheetTrigger?

    // MARK: - Private State

    /// Verhindert parallele Poll-Aufrufe (App-Open + scenePhase + Pull-to-Refresh gleichzeitig).
    private var isPolling: Bool = false

    /// Marker-Set: importId → planUUID, persistiert in UserDefaults.
    /// Einträge hier wurden lokal akzeptiert aber noch nicht erfolgreich zu Supabase gemeldet.
    private var acceptedMarkers: [UUID: UUID] = [:]

    private let markersKey = "plan_import_accepted_ids"
    private let service = SupabasePlanImportService.shared

    // MARK: - Init

    init() {
        loadMarkers()
    }

    // MARK: - Polling

    /// Haupt-Polling-Methode. Wird beim App-Start, scenePhase.active und Pull-to-Refresh aufgerufen.
    func poll(context: ModelContext) async {
        // Guard: kein paralleles Polling, kein Polling während offenem Sheet
        guard !isPolling && activeImport == nil && listTrigger == nil else {
            print("📋 PlanImport poll() übersprungen (aktiv: \(isPolling), sheet offen: \(activeImport != nil || listTrigger != nil))")
            return
        }

        isPolling = true
        defer { isPolling = false }

        // 1. Ausstehende Marker retryten (bei vorherigem Netzausfall)
        await retryPendingMarkers()

        // 2. Neue Imports holen
        let all: [SupabasePendingPlanImportDTO]
        do {
            all = try await service.fetchPending()
        } catch {
            print("⚠️ PlanImport poll() Netzfehler: \(error.localizedDescription)")
            return
        }

        // 3. Bereits lokal akzeptierte Einträge herausfiltern (Marker-Set)
        let markerIDs = Set(acceptedMarkers.keys)
        let unprocessed = all.filter { !markerIDs.contains($0.id) }

        // 4. Schema-Version filtern
        let compatible = unprocessed.filter { $0.schemaVersion <= SupabasePendingPlanImportDTO.supportedImportSchemaVersion }
        let incompatible = unprocessed.filter { $0.schemaVersion > SupabasePendingPlanImportDTO.supportedImportSchemaVersion }

        // 5. State aktualisieren
        schemaMismatchVisible = !incompatible.isEmpty
        pendingImports = compatible

        // 6. Hybrid-Routing: 1 → Preview, ≥2 → Liste, 0 → nichts
        switch compatible.count {
        case 1:
            activeImport = compatible[0]
        case let n where n >= 2:
            listTrigger = ListSheetTrigger()
        default:
            break
        }
    }

    // MARK: - Accept

    /// Mappt den Import-Payload in SwiftData, speichert und meldet Akzept zurück.
    func acceptImport(_ dto: SupabasePendingPlanImportDTO, context: ModelContext) async {
        // 1. Plan anlegen
        let plan = PlanImportApplyService.apply(payload: dto.planData, in: context)

        // 2. SwiftData-Save — bei Fehler rollback, Akzept abbrechen
        do {
            try context.save()
        } catch {
            context.rollback()
            print("❌ PlanImport acceptImport: SwiftData-Save fehlgeschlagen: \(error.localizedDescription)")
            activeImport = nil
            return
        }

        // 3. ExerciseProgressionStates für alle Plan-Übungen sicherstellen (workingWeight aus Template-Sets)
        ProgressionStateEnsurer.ensureStates(forPlan: plan, sessionSets: nil, context: context)

        // 4. Plan nach Supabase hochladen (training_plans) — analog TrainingFormView
        let uploaded = await SupabaseSessionService.shared.upload(plan)
        if uploaded {
            plan.syncedToSupabase = true
            try? context.save()
        }

        // 4. pending_plan_imports auf 'accepted' setzen; bei Netzfehler Marker persistieren
        do {
            try await service.markAccepted(id: dto.id, planUUID: plan.planUUID)
        } catch {
            print("⚠️ PlanImport markAccepted Netzfehler – Marker gespeichert für Retry: \(error.localizedDescription)")
            acceptedMarkers[dto.id] = plan.planUUID
            persistMarkers()
        }

        // 5. Lokalen State bereinigen
        pendingImports.removeAll { $0.id == dto.id }
        activeImport = nil

        // List-Sheet schließen wenn keine weiteren Imports mehr vorhanden
        if pendingImports.isEmpty {
            listTrigger = nil
        }
    }

    // MARK: - Reject

    /// Lehnt einen Import ab und meldet es direkt nach Supabase.
    func rejectImport(_ dto: SupabasePendingPlanImportDTO) async {
        do {
            try await service.markRejected(id: dto.id)
        } catch {
            print("⚠️ PlanImport markRejected Netzfehler: \(error.localizedDescription)")
        }

        pendingImports.removeAll { $0.id == dto.id }
        activeImport = nil

        if pendingImports.isEmpty {
            listTrigger = nil
        }
    }

    // MARK: - Later

    /// "Später" — kein DB-Update, nur Preview-Sheet schließen. Beim nächsten Poll erscheint es wieder.
    func laterImport(_ dto: SupabasePendingPlanImportDTO) {
        activeImport = nil
    }

    // MARK: - Marker Retry

    /// Versucht alle gespeicherten Marker erneut nach Supabase zu melden.
    /// Erfolgreich übermittelte Marker werden entfernt.
    private func retryPendingMarkers() async {
        guard !acceptedMarkers.isEmpty else { return }

        var toRemove: [UUID] = []

        for (importId, planUUID) in acceptedMarkers {
            do {
                try await service.markAccepted(id: importId, planUUID: planUUID)
                toRemove.append(importId)
                print("✅ PlanImport Marker-Retry erfolgreich: \(importId.uuidString)")
            } catch {
                print("⚠️ PlanImport Marker-Retry fehlgeschlagen: \(importId.uuidString) — \(error.localizedDescription)")
            }
        }

        if !toRemove.isEmpty {
            toRemove.forEach { acceptedMarkers.removeValue(forKey: $0) }
            persistMarkers()
        }
    }

    // MARK: - UserDefaults Persistenz

    private func loadMarkers() {
        guard let raw = UserDefaults.standard.dictionary(forKey: markersKey) as? [String: String] else { return }
        var loaded: [UUID: UUID] = [:]
        for (key, value) in raw {
            if let importId = UUID(uuidString: key), let planId = UUID(uuidString: value) {
                loaded[importId] = planId
            }
        }
        acceptedMarkers = loaded
        if !loaded.isEmpty {
            print("📋 PlanImport: \(loaded.count) ausstehende Marker geladen")
        }
    }

    private func persistMarkers() {
        var raw: [String: String] = [:]
        for (importId, planId) in acceptedMarkers {
            raw[importId.uuidString] = planId.uuidString
        }
        UserDefaults.standard.set(raw, forKey: markersKey)
    }
}
