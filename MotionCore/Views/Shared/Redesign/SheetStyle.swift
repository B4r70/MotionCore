//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : SheetStyle.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.06.2026                                                       /
// Beschreibung  : Calm-2026 Bottom-Sheet-Stil (Grabber, Radius xl, Detents)        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Bottom-Sheet-Stil (DESIGN.md §9)

extension View {
    /// Calm-Sheet: sichtbarer Grabber, Radius `xl` oben, definierbare Detents.
    /// Auf den Sheet-Inhalt (innerhalb von `.sheet { … }`) anwenden.
    func calmSheet(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Radius.xl)
            .presentationDetents(detents)
    }
}

// MARK: - Preview

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            Theme.surfaceApp.ignoresSafeArea()
                .sheet(isPresented: $show) {
                    VStack(spacing: Space.s4) {
                        Text("Calm Sheet")
                            .font(AppFont.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Grabber · Radius xl · Detents")
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.surfaceCard)
                    .calmSheet([.medium, .large])
                }
        }
    }
    return Demo()
}
