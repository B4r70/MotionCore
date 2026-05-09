//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyMeasurementEntrySlide.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Generische Eingabe-Slide für das Körpermaß-Karussell             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct BodyMeasurementEntrySlide: View {

    // MARK: - Props

    let title: String
    let unit: String
    let iconSystemName: String
    @Binding var value: Double?
    var secondValue: Binding<Double?>?
    var bothSidesLabels: (String, String)?   // z.B. ("Links", "Rechts")
    var bothSides: Binding<Bool>?
    var step: Double = 0.1
    let onSkip: () -> Void

    // MARK: - Lokaler State

    @State private var primaryText: String = ""
    @State private var secondaryText: String = ""
    @FocusState private var primaryFocused: Bool
    @FocusState private var secondaryFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // SF-Symbol
            Image(systemName: iconSystemName)
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            // Titel
            Text(title)
                .font(.title2)
                .bold()

            // Toggle "Beide Seiten" — nur wenn Binding vorhanden
            if let bothSides {
                Toggle("Beide Seiten messen", isOn: bothSides)
                    .onChange(of: bothSides.wrappedValue) { _, newValue in
                        if !newValue {
                            secondValue?.wrappedValue = nil
                            secondaryText = ""
                        }
                    }
            }

            // Eingabe-Bereich
            if bothSides?.wrappedValue == true {
                bothSidesInputView
            } else {
                singleInputView
            }

            Spacer()

            // Skip-Button
            Button("Heute überspringen") {
                value = nil
                secondValue?.wrappedValue = nil
                onSkip()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Fertig") {
                        primaryFocused = false
                        secondaryFocused = false
                    }
                }
            }
        }
        .onAppear {
            primaryText = value.map { formatValue($0) } ?? ""
            secondaryText = secondValue?.wrappedValue.map { formatValue($0) } ?? ""
        }
        .onChange(of: primaryText) { _, new in
            value = parseText(new)
        }
        .onChange(of: secondaryText) { _, new in
            secondValue?.wrappedValue = parseText(new)
        }
    }

    // MARK: - Single-Modus

    private var singleInputView: some View {
        HStack {
            HoldButton(systemName: "minus.circle.fill", font: .title) { step in
                let result = stepDown(value ?? 0, by: step)
                value = result
                primaryText = formatValue(result)
            }

            TextField("0.0", text: $primaryText)
                .keyboardType(.decimalPad)
                .font(.system(size: 64, weight: .light, design: .rounded))
                .multilineTextAlignment(.center)
                .focused($primaryFocused)
                .frame(minWidth: 120)

            Text(unit)
                .font(.title3)
                .foregroundStyle(.secondary)

            HoldButton(systemName: "plus.circle.fill", font: .title) { step in
                let result = stepUp(value ?? 0, by: step)
                value = result
                primaryText = formatValue(result)
            }
        }
    }

    // MARK: - Both-Sides-Modus

    private var bothSidesInputView: some View {
        HStack(spacing: 16) {
            // Linke Spalte
            VStack(spacing: 8) {
                Text(bothSidesLabels?.0 ?? "Links")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    HoldButton(systemName: "minus.circle.fill", font: .title3) { step in
                        let result = stepDown(secondValue?.wrappedValue ?? 0, by: step)
                        secondValue?.wrappedValue = result
                        secondaryText = formatValue(result)
                    }

                    TextField("0.0", text: $secondaryText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .multilineTextAlignment(.center)
                        .focused($secondaryFocused)
                        .frame(minWidth: 80)

                    HoldButton(systemName: "plus.circle.fill", font: .title3) { step in
                        let result = stepUp(secondValue?.wrappedValue ?? 0, by: step)
                        secondValue?.wrappedValue = result
                        secondaryText = formatValue(result)
                    }
                }
            }

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Rechte Spalte
            VStack(spacing: 8) {
                Text(bothSidesLabels?.1 ?? "Rechts")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    HoldButton(systemName: "minus.circle.fill", font: .title3) { step in
                        let result = stepDown(value ?? 0, by: step)
                        value = result
                        primaryText = formatValue(result)
                    }

                    TextField("0.0", text: $primaryText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .light, design: .rounded))
                        .multilineTextAlignment(.center)
                        .focused($primaryFocused)
                        .frame(minWidth: 80)

                    HoldButton(systemName: "plus.circle.fill", font: .title3) { step in
                        let result = stepUp(value ?? 0, by: step)
                        value = result
                        primaryText = formatValue(result)
                    }
                }
            }
        }
    }

    // MARK: - Hilfsmethoden (Stepper)

    private func stepUp(_ current: Double, by step: Double = 0.1) -> Double {
        let precision = step < 1.0 ? 10.0 : 1.0
        return (current * precision + step * precision).rounded() / precision
    }

    private func stepDown(_ current: Double, by step: Double = 0.1) -> Double {
        let precision = step < 1.0 ? 10.0 : 1.0
        let result = (current * precision - step * precision).rounded() / precision
        return result > 0 ? result : 0
    }

    // MARK: - String-Konvertierung

    private func formatValue(_ v: Double) -> String {
        String(format: "%.1f", v)
            .replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
    }

    private func parseText(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

// MARK: - HoldButton

private struct HoldButton: View {
    let systemName: String
    let font: Font
    let onStep: (Double) -> Void

    @State private var timer: Timer?
    @State private var pressDate: Date?

    var body: some View {
        Image(systemName: systemName)
            .font(font)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPressStart() }
                    .onEnded { _ in onPressEnd() }
            )
    }

    private func onPressStart() {
        guard pressDate == nil else { return }
        pressDate = Date()
        let t = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            DispatchQueue.main.async { tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func onPressEnd() {
        let elapsed = pressDate.map { Date().timeIntervalSince($0) } ?? 0
        timer?.invalidate()
        timer = nil
        pressDate = nil
        if elapsed < 0.3 { onStep(0.1) }
    }

    private func tick() {
        guard let start = pressDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed >= 0.3 else { return }
        onStep(elapsed >= 3.3 ? 5.0 : 1.0)
    }
}

// MARK: - Preview

#Preview("Single") {
    @Previewable @State var value: Double? = 85.0
    BodyMeasurementEntrySlide(
        title: "Körpergewicht",
        unit: "kg",
        iconSystemName: "scalemass",
        value: $value,
        onSkip: {}
    )
    .padding()
}

#Preview("Both Sides") {
    @Previewable @State var right: Double? = 38.0
    @Previewable @State var left: Double? = 37.5
    @Previewable @State var bothSides: Bool = true
    BodyMeasurementEntrySlide(
        title: "Armumfang",
        unit: "cm",
        iconSystemName: "figure.strengthtraining.traditional",
        value: $right,
        secondValue: $left,
        bothSidesLabels: ("Links", "Rechts"),
        bothSides: $bothSides,
        onSkip: {}
    )
    .padding()
}
