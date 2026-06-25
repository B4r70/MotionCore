//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : DecimalTextField.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : Wiederverwendbares Dezimal-Eingabefeld mit lokalem String-Puffer /
//                 Formatierung erst beim Focus-Verlust, kein Nullen-Auffüllen      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Dezimal-Eingabefeld mit internem String-Puffer.
/// Hält den rohen Eingabetext während der Eingabe und formatiert erst beim Focus-Verlust.
/// Akzeptiert Komma (deutsche Locale) und Punkt als Dezimaltrennzeichen.
struct DecimalTextField: View {
    @Binding var value: Double
    var placeholder: String = "0"
    var decimalPlaces: Int = 1

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .onAppear {
                // Initialwert formatiert setzen, leer lassen wenn 0
                if value > 0 {
                    text = formatValue(value)
                }
            }
            .onChange(of: value) { _, newValue in
                // Externen Wert-Update übernehmen wenn das Feld nicht fokussiert ist
                // (z.B. beim Reset oder programmatischen Setzen)
                if !isFocused {
                    text = newValue > 0 ? formatValue(newValue) : ""
                }
            }
            .onChange(of: text) { _, newText in
                // Während der Eingabe: rohen Text in value schreiben
                let normalized = newText.replacingOccurrences(of: ",", with: ".")
                if let parsed = Double(normalized) {
                    value = parsed
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    // Focus verloren: normalisieren, parsen, formatieren
                    let normalized = text.replacingOccurrences(of: ",", with: ".")
                    if let parsed = Double(normalized), parsed > 0 {
                        value = parsed
                        text = formatValue(parsed)
                    } else {
                        // Leeres Feld oder ungültige Eingabe → auf 0 setzen, Text leeren
                        value = 0
                        text = ""
                    }
                }
            }
    }

    // MARK: - Hilfsmethoden

    /// Formatiert einen Double-Wert gemäß der konfigurierten Dezimalstellen
    private func formatValue(_ val: Double) -> String {
        String(format: "%.\(decimalPlaces)f", val)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var dist: Double = 0
    @Previewable @State var speed: Double = 25.5
    @Previewable @State var elevation: Double = 0
    @Previewable @State var weight: Double = 75.0

    ScrollView {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("DecimalTextField Preview").font(.title3.bold())

                HStack {
                    Text("Distanz")
                    Spacer()
                    DecimalTextField(value: $dist, placeholder: "0", decimalPlaces: 2)
                    Text("km").foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Ø Speed")
                    Spacer()
                    DecimalTextField(value: $speed, placeholder: "0", decimalPlaces: 1)
                    Text("km/h").foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Höhenmeter")
                    Spacer()
                    DecimalTextField(value: $elevation, placeholder: "0", decimalPlaces: 0)
                    Text("m").foregroundStyle(.secondary)
                }

                Divider()

                HStack {
                    Text("Gewicht")
                    Spacer()
                    DecimalTextField(value: $weight, placeholder: "0", decimalPlaces: 1)
                    Text("kg").foregroundStyle(.secondary)
                }
            }
            .card()
        }
        .padding()
    }
}
