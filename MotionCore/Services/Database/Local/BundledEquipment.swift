//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Database/Local                                          /
// Datei . . . . : BundledEquipment.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.04.2026                                                       /
// Beschreibung  : Equipment-Modell und Service für lokale Bundle-JSON-Daten        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - BundledEquipmentItem

struct BundledEquipmentItem: Codable, Identifiable, Hashable {
    let id: UUID
    let identifier: String
    let category: String?
    let displayOrder: Int?
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case identifier
        case category
        case displayOrder = "display_order"
        case name
        case description
    }
}

// MARK: - BundledEquipmentService

struct BundledEquipmentService {

    /// Lädt alle Equipment-Items aus dem App-Bundle (equipment_seed.json).
    /// Unterstützt sowohl direktes Array-Format als auch Supabase json_agg-Wrapper-Format.
    /// Gibt ein leeres Array zurück falls die Datei fehlt oder nicht dekodierbar ist.
    static func loadAll() -> [BundledEquipmentItem] {
        guard let url = Bundle.main.url(forResource: "equipment_seed", withExtension: "json") else {
            print("⚠️ BundledEquipmentService: equipment_seed.json nicht im Bundle gefunden")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // Supabase Dashboard Export: json_agg-Wrapper-Format
            let items: [BundledEquipmentItem]
            if let containers = try? decoder.decode([JSONAggContainer].self, from: data),
               let first = containers.first {
                items = first.jsonAgg
            } else {
                items = try decoder.decode([BundledEquipmentItem].self, from: data)
            }

            return items.sorted { ($0.displayOrder ?? 999) < ($1.displayOrder ?? 999) }
        } catch {
            print("⚠️ BundledEquipmentService: Dekodierung fehlgeschlagen – \(error)")
            return []
        }
    }

    /// Sucht ein Equipment-Item anhand seines Identifiers in einer vorgeladenen Liste.
    static func find(identifier: String, in items: [BundledEquipmentItem]) -> BundledEquipmentItem? {
        items.first { $0.identifier == identifier }
    }
}

// MARK: - JSON-Hilfswrapper

/// Wrapper für Supabase Dashboard JSON-Export (json_agg-Format)
private struct JSONAggContainer: Decodable {
    let jsonAgg: [BundledEquipmentItem]
    enum CodingKeys: String, CodingKey { case jsonAgg = "json_agg" }
}
