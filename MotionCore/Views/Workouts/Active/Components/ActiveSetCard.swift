//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveSetCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Aktives Workout (Status View)                                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ActiveSetCard: View {
        // 1. Environment
    @EnvironmentObject private var appSettings: AppSettings
        // 2. Input
    let set: ExerciseSet
    let setsForCurrentExercise: Int
        // 3. Bindings
    @Binding var selectedSetForEdit: ExerciseSet?
        // 4. Actions
    let onComplete: (ExerciseSet) -> Void
        // 5. Local UI State
    @State private var showInstructionsSheet = false
    @State private var isEditingInstructions = false

    private var exercise: Exercise? {
        get {
            set.exercise
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                // Anzeige des Übungs-Darstellung sofern vorhanden
                ExerciseVideoView.forSet(
                    set,
                    size: 80
                )
                .fixedSize(
                    horizontal: true,
                    vertical: true
                )

                VStack(alignment: .leading, spacing: 4) {
                    if set.setKind != .work {
                        Text(set.setKind.description.uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(set.setKind.color)
                    }

                    Text(set.exerciseName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Satz \(set.setNumber) von \(setsForCurrentExercise)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                // Übungsanleitung aufrufen (Icon)
                Button {
                    showInstructionsSheet = true
                } label: {
                    Image(systemName: "figure.run.square.stack")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                        )
                }
                .opacity(hasInstructions ? 1.0 : 0.35)
                .disabled(!hasInstructions)
                .accessibilityLabel("Übungsanleitung anzeigen")
            }
            .glassDivider()

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(set.weight > 0 ? String(format: "%.2f", set.weight) : "0.00")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(set.weight > 0 ? .primary : .secondary)

                    Text(set.weight > 0 ? "kg" : "Körpergewicht")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 1, height: 50)

                VStack(spacing: 4) {
                    Text("\(set.reps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Wdh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                selectedSetForEdit = set
            } label: {
                Label("Anpassen", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            .glassDivider()

            Button {
                onComplete(set)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Satz abschließen")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
        // Edit-Mode Reset beim Schließen
        .onChange(of: showInstructionsSheet) { _, isShown in
            if !isShown { isEditingInstructions = false }
        }
        .sheet(isPresented: $showInstructionsSheet) {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                    .ignoresSafeArea()

                ScrollView {
                    if let exercise {
                        ExerciseInstructionsCard(
                            exercise: exercise,
                            isEditing: $isEditingInstructions,
                            showsHeader: true,
                            wrapContentInGlassCard: true,
                            initiallyExpanded: true
                        )
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            Text("Übungsdetails nicht verfügbar")
                                .font(.headline)

                            Text("Die Verknüpfung zur Übung fehlt.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 240)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // Nur anzeigen, wenn Übungsanleitungen vorhanden sind
    private var hasInstructions: Bool {
        guard let exercise else { return false }
        let instructions = (exercise.instructions ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let description = exercise.exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return !instructions.isEmpty || !description.isEmpty
    }
}
