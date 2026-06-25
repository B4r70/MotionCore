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
                        .font(AppFont.body)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        // Aktiver Tab: weißer Text auf Akzentfläche (deliberate raw .white per spec)
                        .foregroundStyle(selectedTab == tab ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Theme.accent)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.surfaceSunken, in: Capsule())
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
