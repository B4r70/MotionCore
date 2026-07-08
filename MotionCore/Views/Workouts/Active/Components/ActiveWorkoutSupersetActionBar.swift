//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / Components                                     /
// Datei . . . . : ActiveWorkoutSupersetActionBar.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.05.2026                                                       /
// Beschreibung  : Floating Action Bar für die Superset-Erstellung im aktiven       /
//                 Workout. Wird über der bottomActionBar eingeblendet.             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Floating Action Bar die im Superset-Selection-Modus über der bottomActionBar
/// angezeigt wird. Alle Zustands-Logik liegt im Aufrufer (ActiveWorkoutView).
struct ActiveWorkoutSupersetActionBar: View {
    let selectedCount: Int
    let canCreate: Bool
    let hasGap: Bool
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedCount) Übung\(selectedCount == 1 ? "" : "en") ausgewählt")
                    .font(AppFont.body.bold())
                    .foregroundStyle(Theme.textPrimary)

                if hasGap {
                    Text("Nur aufeinanderfolgende Übungen")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.warning)
                } else if selectedCount < 2 {
                    Text("Mindestens 2 für ein Superset")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text("Superset erstellen")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            // "Abbrechen" — Ghost-Stil (kein maxWidth: .infinity, passt in HStack)
            Button {
                onCancel()
            } label: {
                Text("Abbrechen")
            }
            .buttonStyle(.mcGhost)

            // "Superset" — kompakte Kapsel; .mcPrimary nicht nutzbar (maxWidth: .infinity bricht HStack-Layout)
            Button {
                onCreate()
            } label: {
                Text("Superset")
                    .font(AppFont.body.bold())
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        canCreate ? Theme.accent : Theme.accent.opacity(0.3),
                        in: Capsule()
                    )
            }
            .disabled(!canCreate)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.lineSoft, lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}
