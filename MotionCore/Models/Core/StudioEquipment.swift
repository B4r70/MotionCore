//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : StudioEquipment.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Konkretes Studio-Gerät mit Gewichtsprofil und Sprüngen          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class StudioEquipment {

    // MARK: - Identifikation

    var id: UUID = UUID()

    // MARK: - Stammdaten

    var name: String = ""

    // Rohwert für CloudKit-Kompatibilität (String statt Enum)
    var equipmentTypeRaw: String = "machine"

    // MARK: - Gewichtsprofil

    var startWeight: Double = 0.0
    var increment: Double = 2.5
    var minWeight: Double = 0.0
    var maxWeight: Double? = nil

    // Zwischengewichte für Feintuning-Chips; standardmäßig leer
    var intermediateIncrements: [Double] = []

    // MARK: - Sonstiges

    var notes: String = ""
    var createdAt: Date = Date()

    // MARK: - Beziehungen

    // Rückbeziehung zum Studio (Kind-Seite, inverse wird auf Studio-Seite definiert)
    var studio: Studio?

    // MARK: - Typisierter Accessor (computed)

    // Gibt den typisierten Gerätetyp zurück, Fallback auf .machine
    var equipmentType: StudioEquipmentType {
        get { StudioEquipmentType(rawValue: equipmentTypeRaw) ?? .machine }
        set { equipmentTypeRaw = newValue.rawValue }
    }

    // MARK: - Initialisierung

    init(
        name: String = "",
        equipmentType: StudioEquipmentType = .machine,
        startWeight: Double = 0.0,
        increment: Double = 2.5,
        intermediateIncrements: [Double] = []
    ) {
        self.name = name
        self.equipmentTypeRaw = equipmentType.rawValue
        self.startWeight = startWeight
        self.increment = increment
        self.minWeight = startWeight
        self.intermediateIncrements = intermediateIncrements
    }
}
