//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StrengthOneRMChart.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : 1RM-Progressionschart je Übung (Epley-Formel)                   /
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
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("kg (est.)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                            .font(.subheadline)
                            .foregroundStyle(selectedExercise.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
            }

            let oneRMData = selectedExercise.isEmpty ? [] : calcEngine.estimatedOneRM(for: selectedExercise)

            if oneRMData.isEmpty {
                Text(selectedExercise.isEmpty ? "Bitte Übung wählen" : "Keine Daten für diese Übung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .foregroundStyle(Color.orange)

                    PointMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .symbol(.circle)
                    .symbolSize(45)
                    .foregroundStyle(Color.orange)

                    AreaMark(
                        x: .value("Datum", point.trendDate),
                        y: .value("1RM", point.trendValue)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
        .glassCard()
    }
}
