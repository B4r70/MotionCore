//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : Studio.swift                                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Studio-Definition (Equipment-Profil-Container)                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class Studio {

    // MARK: - Identifikation

    var id: UUID = UUID()

    // MARK: - Stammdaten

    var name: String = ""

    // Aktuell genutztes Studio (Multi-Studio-vorbereitet, UI zeigt nur eins)
    var isPrimary: Bool = false

    var createdAt: Date = Date()

    // MARK: - Beziehungen

    @Relationship(deleteRule: .cascade, inverse: \StudioEquipment.studio)
    var equipment: [StudioEquipment]? = []

    // MARK: - Initialisierung

    init(name: String = "", isPrimary: Bool = false) {
        self.name = name
        self.isPrimary = isPrimary
    }
}

// MARK: - Hilfszugriffe

extension Studio {
    var safeEquipment: [StudioEquipment] { equipment ?? [] }
}
