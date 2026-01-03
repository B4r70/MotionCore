//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI Extensions                                                    /
// Datei . . . . : ViewVisibility.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.01.2026                                                       /
// Beschreibung  : Sichtbarkeits- und Anzeige-Helfer für SwiftUI Views              /
//                 (z. B. bedingtes Ein-/Ausblenden von Views)                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Foundation

extension View {

    // MARK: - Visibility

    // Hides the view but keeps its layout space.
    @ViewBuilder
    func hiddenIf(_ condition: Bool) -> some View {
        if condition { hidden() } else { self }
    }

    // Removes the view entirely from the layout.
    @ViewBuilder
    func removeIf(_ condition: Bool) -> some View {
        if condition { EmptyView() } else { self }
    }

    // MARK: - Conditional Modifiers

    // Applies a transform to the view only if the condition is true.
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool,
                                transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    // Applies a transform to the view only if the optional value exists.
    @ViewBuilder
    func applyIfLet<T, Content: View>(_ value: T?,
                                      transform: (Self, T) -> Content) -> some View {
        if let value { transform(self, value) } else { self }
    }

        // MARK: - Interaction

    // Disables interaction and visually dims the view.
    func disableIf(_ condition: Bool, opacity: Double = 0.5) -> some View {
        disabled(condition).opacity(condition ? opacity : 1)
    }

    // Adds a content shape only when needed (useful for hit testing).
    @ViewBuilder
    func contentShapeIf(_ condition: Bool) -> some View {
        if condition { contentShape(Rectangle()) } else { self }
    }
}
