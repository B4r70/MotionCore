//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : DefaultStudioSeeder.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Idempotenter Seeder fuer "Mein Studio" + 5 Default-Geraete       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

struct DefaultStudioSeeder {

    // MARK: - Öffentlicher Einstiegspunkt

    /// Legt "Mein Studio" + 5 Default-Geräte an, falls noch kein Primary-Studio existiert.
    /// Idempotent: Läuft bei jedem App-Start, schreibt aber nur beim ersten Mal.
    static func seedIfNeeded(context: ModelContext) {
        // Idempotenz-Check: Primary-Studio bereits vorhanden?
        var descriptor = FetchDescriptor<Studio>(
            predicate: #Predicate { $0.isPrimary == true }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return  // Primary-Studio existiert bereits — kein Seed nötig
        }

        // Primary-Studio anlegen
        let studio = Studio(name: "Mein Studio", isPrimary: true)
        context.insert(studio)

        // Default-Geräte anlegen und mit Studio verknüpfen
        for equipment in makeDefaultEquipment(for: studio) {
            context.insert(equipment)
        }

        try? context.save()
    }

    // MARK: - Default-Geräte

    /// Erstellt die 5 Standard-Geräte gemäß Concept 3.1.2
    private static func makeDefaultEquipment(for studio: Studio) -> [StudioEquipment] {
        let specs: [(
            name: String,
            type: StudioEquipmentType,
            start: Double,
            incr: Double,
            intermediate: [Double],
            max: Double?
        )] = [
            ("Kabelzug",       .cable,    1.25, 2.5, [0.625, 1.25], nil ),
            ("Kurzhanteln",    .dumbbell, 2.0,  2.0, [],             24.0),
            ("Beinpresse",     .machine,  0.0,  7.0, [3.5],          nil ),
            ("Brustpresse",    .machine,  0.0,  7.0, [3.5],          nil ),
            ("Latzugmaschine", .machine,  0.0,  7.0, [3.5],          nil )
        ]

        return specs.map { spec in
            let eq = StudioEquipment(
                name: spec.name,
                equipmentType: spec.type,
                startWeight: spec.start,
                increment: spec.incr,
                intermediateIncrements: spec.intermediate
            )
            eq.maxWeight = spec.max
            eq.studio = studio
            return eq
        }
    }
}
