//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyTabSwitch.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Tab-Umschalter für die drei Body-Segmente                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyTab

enum BodyTab: String, CaseIterable, Identifiable {
    case recovery = "Erholung"
    case form     = "Tagesform"
    case trend    = "Trend"

    var id: String { rawValue }
}

// MARK: - BodyTabSwitch

struct BodyTabSwitch: View {

    @Binding var selectedTab: BodyTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BodyTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        BodyTabSwitch(selectedTab: .constant(.recovery))
        BodyTabSwitch(selectedTab: .constant(.form))
        BodyTabSwitch(selectedTab: .constant(.trend))
    }
    .padding()
}
