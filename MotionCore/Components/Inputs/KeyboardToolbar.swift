//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Hilftools                                                     /
// Datei . . . . : KeyboardDismiss.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.12.2025                                                       /
// Beschreibung  : Wiederverwendbare Funktionen für Keyboard-Management             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Keyboard Dismiss Helper

// Schließt die Tastatur programmatisch
func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

// MARK: - View Extension für Tap-Gesture

extension View {
    // Fügt einen Tap-Gesture hinzu, der die Tastatur schließt
    // Verwendung: `.hideKeyboardOnTap()` auf AnimatedBackground oder ZStack
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            dismissKeyboard()
        }
    }
}

// MARK: - Keyboard Toolbar Modifier (DHL-Style)

struct KeyboardToolbarModifier: ViewModifier {
    @FocusState.Binding var focusedField: FocusedField?
    let allFields: [FocusedField]

    // Prüft ob Navigation möglich ist
    private var canNavigatePrevious: Bool {
        guard let current = focusedField,
              let currentIndex = allFields.firstIndex(of: current) else {
            return false
        }
        return currentIndex > 0
    }

    private var canNavigateNext: Bool {
        guard let current = focusedField,
              let currentIndex = allFields.firstIndex(of: current) else {
            return false
        }
        return currentIndex < allFields.count - 1
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    // Navigation Buttons (Links)
                    HStack(spacing: 0) {
                        // Vorheriges Feld
                        Button {
                            navigatePrevious()
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.body.weight(.medium))
                                .foregroundStyle(canNavigatePrevious ? .primary : .secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .disabled(!canNavigatePrevious)

                        // Nächstes Feld
                        Button {
                            navigateNext()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.body.weight(.medium))
                                .foregroundStyle(canNavigateNext ? .primary : .secondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .disabled(!canNavigateNext)
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                    Spacer()

                    // Fertig-Button (Rechts)
                    Button {
                        dismissKeyboard()
                        focusedField = nil
                    } label: {
                        Text("Fertig")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
    }

    // Navigation-Funktionen
    private func navigatePrevious() {
        guard let current = focusedField,
              let currentIndex = allFields.firstIndex(of: current),
              currentIndex > 0 else {
            return
        }
        focusedField = allFields[currentIndex - 1]
    }

    private func navigateNext() {
        guard let current = focusedField,
              let currentIndex = allFields.firstIndex(of: current),
              currentIndex < allFields.count - 1 else {
            return
        }
        focusedField = allFields[currentIndex + 1]
    }
}

// MARK: - FocusedField Enum

// Definition der Eingabefelder in deiner Form
enum FocusedField: Hashable {
    case distance
    case bodyWeight
    case duration
    case difficulty
    case calories
    case heartRate
}

// MARK: - View Extension

extension View {
    // Fügt eine Keyboard-Toolbar mit Navigation hinzu
    // Verwendung: `.keyboardToolbar(focusedField: $focusedField, fields: [.distance, .bodyWeight, ...])`
    func keyboardToolbar(
        focusedField: FocusState<FocusedField?>.Binding,
        fields: [FocusedField]
    ) -> some View {
        self.modifier(
            KeyboardToolbarModifier(
                focusedField: focusedField,
                allFields: fields
            )
        )
    }
}
