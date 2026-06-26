//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : StrengthEditView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Detailansicht für abgeschlossene Krafttraining-Sessions          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Edit Sheet

struct StrengthEditView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: StrengthSession

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.surfaceApp.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Grunddaten
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Grunddaten")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.textPrimary)
                            
                            // Datum
                            DatePicker(
                                "Datum",
                                selection: $session.date,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .environment(\.locale, Locale(identifier: "de_DE"))
                            
                            // Dauer
                            HStack {
                                Text("Dauer (Minuten)")
                                Spacer()
                                TextField("0", value: $session.duration, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                            
                            // Kalorien
                            HStack {
                                Text("Kalorien")
                                Spacer()
                                TextField("0", value: $session.calories, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                            
                            // Herzfrequenz
                            HStack {
                                Text("Ø Herzfrequenz (bpm)")
                                Spacer()
                                TextField("0", value: $session.heartRate, format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }

                            // Intensität
                            HStack {
                                Text("Belastung")
                                Spacer()
                                Picker("", selection: $session.intensity) {
                                    ForEach(Intensity.allCases, id: \.self) { intensity in
                                        Text(intensity.description).tag(intensity)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .card()
                        
                        // Notizen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notizen")
                                .font(.title3.bold())
                                .foregroundStyle(Theme.textPrimary)

                            TextField("Notizen zum Training...", text: $session.notes, axis: .vertical)
                                .lineLimit(3...6)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.md))
                        }
                        .card()
                    }
                    .padding()
                }
            }
            .navigationTitle("Training bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if session.syncedToSupabase {
                            session.needsSupabaseResync = true
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }
}
