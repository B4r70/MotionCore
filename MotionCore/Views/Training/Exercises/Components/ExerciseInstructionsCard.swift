//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Components                                                 /
// Datei . . . . : ExerciseInstructionsCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.01.2026                                                       /
// Beschreibung  : Wiederverwendbare Card zur Anzeige/Bearbeitung von Anleitungen   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExerciseInstructionsCard: View {
    @Bindable var exercise: Exercise
    @Binding var isEditing: Bool

    // Presentation / Embedding
    let showsHeader: Bool
    let wrapContentInGlassCard: Bool

    @State private var isExpanded: Bool
    @State private var editedInstructions: String = ""

    init(
        exercise: Exercise,
        isEditing: Binding<Bool>,
        showsHeader: Bool = true,
        wrapContentInGlassCard: Bool = true,
        initiallyExpanded: Bool = false
    ) {
        self.exercise = exercise
        self._isEditing = isEditing
        self.showsHeader = showsHeader
        self.wrapContentInGlassCard = wrapContentInGlassCard

        // If embedded (no header), content should be visible by default.
        self._isExpanded = State(initialValue: showsHeader ? initiallyExpanded : true)
    }

    // Parsed Instructions (nummeriert)
    private var instructionSteps: [String] {
        let raw: String

        if isEditing {
            raw = editedInstructions
        } else {
            raw = exercise.instructions ?? ""
        }

        return raw
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var canEdit: Bool {
        !exercise.isSystemExercise
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                header
            }

            if isExpanded {
                if showsHeader {
                    GlassDivider()
                }

                instructionsContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            editedInstructions = exercise.instructions ?? ""
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                exercise.instructions = editedInstructions.isEmpty ? nil : editedInstructions
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.blue)

                Text("Anleitung")
                    .font(.headline)

                Spacer()

                if exercise.isSystemExercise {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !instructionSteps.isEmpty {
                    Text("\(instructionSteps.count) Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var instructionsContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 16) {
                // Beschreibung (read-only)
                if !exercise.exerciseDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Beschreibung", systemImage: "text.alignleft")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text(exercise.exerciseDescription)
                            .font(.body)
                    }
                }

                // Instructions: Edit vs View
                if isEditing && canEdit {
                    editModeView
                } else {
                    viewModeView
                }

                // Source Label
                sourceLabel
            }
            .scrollViewContentPadding()
        }
        .modifier(InstructionsContainerStyle(enabled: wrapContentInGlassCard))
    }

    // MARK: - View Mode (Read-Only)

    @ViewBuilder
    private var viewModeView: some View {
        if !instructionSteps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Ausführung", systemImage: "figure.walk")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if canEdit && !isEditing {
                        Button {
                            withAnimation {
                                isEditing = true
                            }
                        } label: {
                            Text("Bearbeiten")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(Array(instructionSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle().fill(Color.blue.gradient)
                            )

                        Text(step)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } else if canEdit {
            Button {
                withAnimation {
                    isEditing = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Anleitung hinzufügen")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Edit Mode (nur für eigene Übungen)

    @ViewBuilder
    private var editModeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ausführung bearbeiten", systemImage: "figure.walk")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Trenne einzelne Schritte mit einer Leerzeile (Enter + Enter)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                TextEditor(text: $editedInstructions)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )

                if !instructionSteps.isEmpty {
                    HStack {
                        Image(systemName: "eye")
                            .font(.caption2)
                        Text("Vorschau: \(instructionSteps.count) Steps")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Source Label

    @ViewBuilder
    private var sourceLabel: some View {
        if exercise.isSystemExercise {
            HStack {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                Text("Quelle: ExerciseDB (nicht editierbar)")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Container Styling Toggle

private struct InstructionsContainerStyle: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        Group {
            if enabled { content.glassCard() } else { content }
        }
    }
}

// MARK: - Compact Variant (für Listen / Previews)

struct ExerciseInstructionsPreview: View {
    let exercise: Exercise

    private var previewText: String {
        if let instructions = exercise.instructions, !instructions.isEmpty {
            let first = instructions.components(separatedBy: "\n\n").first ?? ""
            let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 100 {
                return String(trimmed.prefix(100)) + "..."
            }
            return trimmed
        }
        return exercise.exerciseDescription
    }

    var body: some View {
        if !previewText.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.blue)
                    .imageScale(.medium)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Anleitung")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(previewText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if exercise.isSystemExercise {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ExerciseInstructionsCard(
                exercise: Exercise(
                    name: "Bankdrücken",
                    exerciseDescription: "Klassische Brustübung für Masse und Kraft.",
                    instructions: "Flach auf Bank legen.\n\nStange zur Brust senken.\n\nExplosiv hochdrücken."
                ),
                isEditing: .constant(false),
                showsHeader: true,
                wrapContentInGlassCard: true,
                initiallyExpanded: true
            )

            ExerciseInstructionsCard(
                exercise: Exercise(
                    name: "Ab Crunch Machine",
                    exerciseDescription: "",
                    isSystemExercise: true,
                    instructions: "Select a light resistance and sit down.\n\nGrab the top handles.\n\nCrunch your upper torso."
                ),
                isEditing: .constant(false),
                showsHeader: true,
                wrapContentInGlassCard: true,
                initiallyExpanded: true
            )

            // Embedded-like preview: no header, no extra card wrapper
            ExerciseInstructionsCard(
                exercise: Exercise(
                    name: "Plank",
                    exerciseDescription: "Rumpf stabil halten, nicht ins Hohlkreuz fallen.",
                    instructions: "Unterarme aufstützen.\n\nRumpf anspannen.\n\nAtmung ruhig halten."
                ),
                isEditing: .constant(false),
                showsHeader: false,
                wrapContentInGlassCard: false
            )
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}
