//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthOneRMChart.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : 1RM-Progressionschart je Übung (Epley-Formel)                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import Charts

struct StrengthOneRMChart: View {
    let exerciseNames: [String]
    let calcEngine: StrengthStatisticCalcEngine

    @State private var selectedExercise: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("1RM-Progression")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("kg (est.)")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding([.horizontal, .top])

            if !exerciseNames.isEmpty {
                Menu {
                    ForEach(exerciseNames, id: \.self) { name in
                        Button(name) {
                            selectedExercise = name
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedExercise.isEmpty ? "Übung wählen" : selectedExercise)
                            .font(AppFont.body)
                            .foregroundStyle(selectedExercise.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
            }

            let oneRMData = selectedExercise.isEmpty ? [] : calcEngine.estimatedOneRM(for: selectedExercise)

            if oneRMData.isEmpty {
                Text(selectedExercise.isEmpty ? "Bitte Übung wählen" : "Keine Daten für diese Übung")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .multilineTextAlignment(.center)
            } else {
                Chart(oneRMData) { point in
                    LineMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 2.5))
                    .foregroundStyle(Theme.accent)

                    PointMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .symbol(.circle)
                    .symbolSize(45)
                    .foregroundStyle(Theme.accent)

                    AreaMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.accent.opacity(0.15))
                }
                .frame(minHeight: 220)
                .padding()
            }
        }
        .onAppear {
            if selectedExercise.isEmpty, let first = exerciseNames.first {
                selectedExercise = first
            }
        }
        .onChange(of: exerciseNames) { _, newNames in
            if selectedExercise.isEmpty, let first = newNames.first {
                selectedExercise = first
            }
        }
        .card()
    }
}
