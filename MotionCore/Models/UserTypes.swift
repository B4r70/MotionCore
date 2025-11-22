//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : UserTypes.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.11.2025                                                       /
// Beschreibung  : Benutzerspezifische Angaben                                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//

enum Gender: String, CaseIterable, Identifiable {
    case male = "Männlich"
    case female = "Weiblich"
    case other = "Divers"

    var id: String { self.rawValue }
    
    // Für die Anzeige in der Picker-View
    var description: String {
        self.rawValue
    }
}
