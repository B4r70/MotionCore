//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : SetEditSheet.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.01.2026                                                       /
// Beschreibung  : Edit-Sheet für die Anpassung des Trainings innerhalb der View    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

// MARK: - Set Edit Sheet

struct SetEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var set: ExerciseSet
    @Bindable var session: StrengthSession

    @State private var weight: Double
    @State private var reps: Int
    @State private var setCount: Int

    init(set: ExerciseSet, session: StrengthSession) {
        self.set = set
        self.session = session
        _weight = State(initialValue: set.weight)
        _reps = State(initialValue: set.reps)

        // Satz-Anzahl für diese Übung berechnen
        let sameSets = session.exerciseSets.filter { $0.exerciseName == set.exerciseName }
        _setCount = State(initialValue: sameSets.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                VStack(spacing: 24) {
                    // Übungs-Info
                    HStack {
                        ExerciseGifView(assetName: set.exerciseGifAssetName, size: 60)

                        VStack(alignment: .leading) {
                            Text(set.exerciseName)
                                .font(.headline)
                            Text("Satz \(set.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .glassCard()

                    // Gewicht
                    VStack(spacing: 12) {
                        Text("Gewicht (kg)")
                            .font(.headline)

                        HStack {
                            Button {
                                if weight >= 0.25 { weight -= 0.25 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }

                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .frame(width: 250)

                            Button {
                                weight += 0.25
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .glassCard()

                    // Wiederholungen
                    VStack(spacing: 12) {
                        Text("Wiederholungen")
                            .font(.headline)

                        HStack {
                            Button {
                                if reps > 1 { reps -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }

                            Text("\(reps)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .frame(width: 250)

                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .glassCard()

                    // Satz-Anzahl
                    VStack(spacing: 12) {
                        Text("Anzahl Sätze")
                            .font(.headline)

                        HStack {
                            Button {
                                if setCount > 1 {
                                    setCount -= 1
                                    handleSetCountChange()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(setCount > 1 ? .blue : .gray)
                            }
                            .disabled(setCount <= 1)

                            Text("\(setCount)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .frame(width: 250)

                            Button {
                                setCount += 1
                                handleSetCountChange()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.blue)
                            }
                        }

                        Text("für \(set.exerciseName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .glassCard()

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Satz anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        set.weight = weight
                        set.reps = reps
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Set Management

    // Reagiert auf Änderung der Satz-Anzahl
    private func handleSetCountChange() {
        let currentCount = session.exerciseSets.filter { $0.exerciseName == set.exerciseName }.count
        let difference = setCount - currentCount

        if difference > 0 {
            // Sätze hinzufügen
            for _ in 0..<difference {
                addSet()
            }
        } else if difference < 0 {
            // Sätze entfernen
            for _ in 0..<abs(difference) {
                removeLastSet()
            }
        }

        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Fügt einen zusätzlichen Satz hinzu
    private func addSet() {
        // Finde alle Sätze der gleichen Übung
        let sameSets = session.exerciseSets.filter { $0.exerciseName == set.exerciseName }

        // Nächste Satznummer berechnen
        let nextSetNumber = (sameSets.map { $0.setNumber }.max() ?? 0) + 1

        // Neuen Satz erstellen mit gleichen Werten wie das Original
        let newSet = ExerciseSet(
            exerciseName: set.exerciseName,
            exerciseNameSnapshot: set.exerciseNameSnapshot,
            exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
            exerciseGifAssetName: set.exerciseGifAssetName,
            setNumber: nextSetNumber,
            weight: set.weight,
            weightPerSide: set.weightPerSide,
            reps: set.reps,
            duration: set.duration,
            distance: set.distance,
            restSeconds: set.restSeconds,
            setKind: .work,  // Zusatzsätze sind immer Arbeitssätze
            isCompleted: false,
            rpe: 0,
            notes: "",
            targetRepsMin: set.targetRepsMin,
            targetRepsMax: set.targetRepsMax,
            targetRIR: set.targetRIR,
            groupId: set.groupId
        )

        // Exercise-Referenz übernehmen
        newSet.exercise = set.exercise

        // Zur Session hinzufügen
        session.exerciseSets.append(newSet)

        // Speichern
        try? context.save()
    }

    // Entfernt den letzten Satz einer Übung
    private func removeLastSet() {
        // Finde alle Sätze dieser Übung
        let sameSets = session.exerciseSets.filter { $0.exerciseName == set.exerciseName }

        // Mindestens 1 Satz muss bleiben
        guard sameSets.count > 1 else { return }

        // Finde den letzten nicht-abgeschlossenen Satz
        if let lastIncompleteSet = sameSets.filter({ !$0.isCompleted }).last {
            session.exerciseSets.removeAll { $0.id == lastIncompleteSet.id }
            context.delete(lastIncompleteSet)
        }
        // Falls alle abgeschlossen, entferne einfach den letzten
        else if let lastSet = sameSets.last {
            session.exerciseSets.removeAll { $0.id == lastSet.id }
            context.delete(lastSet)
        }

        // Speichern
        try? context.save()
    }
}
