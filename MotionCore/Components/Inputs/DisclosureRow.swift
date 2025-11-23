//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : DisclosureRow.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Definition der DisclosureRow für die Anzeige der Werte im Wheel  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct DisclosureRow<Content: View>: View {
    let title: String
    let value: String?
    @Binding var isExpanded: Bool
    let content: () -> Content
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if let displayValue = value {
                    Text(displayValue)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
