//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body / BodyMeasurements                                  /
// Datei . . . . : BodyMeasurementsEmptyState.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Empty-State für die Körpermaße-Übersicht                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyMeasurementsEmptyState

struct BodyMeasurementsEmptyState: View {
    let onAddMeasurement: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.arms.open")
                .font(.system(size: 100, weight: .light))
                .foregroundStyle(.tint)
            Text("Körpermaße tracken")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Konsistente Maße zeigen dir, wo dein Training wirkt. Erfasse alle 1–2 Wochen Brust, Taille, Arme & Co. — MotionCore zeigt dir die Entwicklung.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onAddMeasurement) {
                Label("Erste Messung", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    BodyMeasurementsEmptyState(onAddMeasurement: {})
}
