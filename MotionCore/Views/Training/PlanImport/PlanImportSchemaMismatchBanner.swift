// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / PlanImport                                            /
// Datei . . . . : PlanImportSchemaMismatchBanner.swift                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Banner für übersprungene Imports (inkompatible schema_version)  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Schema-Mismatch Banner

struct PlanImportSchemaMismatchBanner: View {

    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(Color.orange)

            // Texte
            VStack(alignment: .leading, spacing: 2) {
                Text("Trainingsplan-Import übersprungen — bitte App aktualisieren.")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Web nutzt ein neueres Plan-Format als diese App-Version.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // X-Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Preview

#Preview("Schema Mismatch Banner") {
    VStack {
        PlanImportSchemaMismatchBanner(
            onDismiss: { print("Banner geschlossen") }
        )
        .padding()
    }
}
