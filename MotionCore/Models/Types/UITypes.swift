//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Types                                                            /
// Datei . . . . : UITypes.swift                                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.01.2026                                                       /
// Beschreibung  : UI-bezogene Types und Enums                                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Form Mode

enum FormMode {
    case add
    case edit
    
    var title: String {
        switch self {
        case .add: return "Hinzufügen"
        case .edit: return "Bearbeiten"
        }
    }
    
    var buttonLabel: String {
        switch self {
        case .add: return "Erstellen"
        case .edit: return "Speichern"
        }
    }
    
    var isEditing: Bool {
        self == .edit
    }
}
