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
    let supersetExerciseNames: [String]?
    let supersetCurrentIndex: Int
    let supersetCurrentRound: Int
    let supersetTotalRounds: Int
        // 2b. Optionale Callbacks (Default: nil für bestehende Call-Sites)
    var onOpenQuickConfig: (() -> Void)? = nil
    var isEngineSuggestion: Bool = false
    var isReadinessReduced: Bool = false
        // 2c. Historische Referenz aus letzter Session (nil = keine Anzeige)
    var lastSessionReference: LastSessionReferenceCalcEngine.Reference? = nil
        // 2d. Countdown-Manager für zeitbasierte Sätze (nil = Weight-Satz)
    @ObservedObject var countdown: ExerciseCountdownManager
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
        if set.isTimeBased {
            timeBasedContent
        } else {
            weightBasedContent
        }
    }

    // MARK: - Geteilter Header

    /// Kopfzeile mit Thumbnail, Übungsname, Satznummer, Badges und Aktions-Icons.
    /// Wird von beiden Zweigen (Weight + Time) verwendet.
    private var cardHeader: some View {
        HStack(spacing: Space.s4) {
            // Übungs-Thumbnail (64×64, §4.4)
            ExerciseVideoView.forSet(
                set,
                size: 64
            )
            .fixedSize(
                horizontal: true,
                vertical: true
            )

            VStack(alignment: .leading, spacing: Space.s1) {
                if set.setKind != .work {
                    Text(set.setKind.description)
                        .font(AppFont.eyebrow)
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(set.setKind.color)
                }

                Text(set.exerciseName)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: Space.s2) {
                    Text("Satz \(set.setNumber) von \(setsForCurrentExercise)")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textSecondary)

                    // B1: Vorschlag-Badge (sichtbar solange isEngineSuggestion == true)
                    if isEngineSuggestion {
                        Badge(text: "Vorschlag", style: .soft, color: Theme.textSecondary)
                    }

                    // B2: Readiness-Badge (sichtbar wenn Gewicht wegen Tagesform reduziert)
                    if isReadinessReduced {
                        ReadinessReducedBadge()
                    }
                }
            }

            Spacer()
            // Quick-Config aufrufen (Icon) — nur wenn Closure gesetzt
            if let onOpenQuickConfig {
                Button(action: onOpenQuickConfig) {
                    Image(systemName: "gearshape")
                        .font(AppFont.body)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Theme.surfaceSunken, in: Circle())
                }
                .buttonStyle(.plain)
            }
            // Übungsanleitung aufrufen (Icon)
            Button {
                showInstructionsSheet = true
            } label: {
                Image(systemName: "figure.run.square.stack")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .background(Theme.surfaceSunken, in: Circle())
            }
            .opacity(hasInstructions ? 1.0 : 0.35)
            .disabled(!hasInstructions)
            .accessibilityLabel("Übungsanleitung anzeigen")
        }
    }

    /// Superset-Rotations-Tracker — wird von beiden Zweigen angezeigt wenn aktiv.
    @ViewBuilder
    private var supersetTracker: some View {
        if let exerciseNames = supersetExerciseNames {
            VStack(alignment: .leading, spacing: Space.s2) {
                // Kopfzeile: Icon + Runden-Info
                HStack(spacing: Space.s1) {
                    Image(systemName: "bolt.fill")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.success)
                    Text("Superset · Runde \(supersetCurrentRound)/\(supersetTotalRounds)")
                        .font(AppFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.success)
                    Spacer()
                }

                // Übungs-Dots: aktiv (Punkt), abgeschlossen (Haken), ausstehend (leerer Kreis)
                HStack(spacing: Space.s2) {
                    ForEach(Array(exerciseNames.enumerated()), id: \.offset) { idx, name in
                        HStack(spacing: Space.s1) {
                            // Dot-Indikator
                            ZStack {
                                if idx == supersetCurrentIndex {
                                    Circle()
                                        .fill(Theme.success)
                                        .frame(width: 8, height: 8)
                                } else if idx < supersetCurrentIndex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Theme.success)
                                } else {
                                    Circle()
                                        .stroke(Theme.success.opacity(0.5), lineWidth: 1.5)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .frame(width: 10)

                            // Übungsname (kurz abschneiden)
                            Text(name)
                                .font(AppFont.caption)
                                .foregroundStyle(idx == supersetCurrentIndex ? Theme.textPrimary : Theme.textSecondary)
                                .lineLimit(1)
                        }

                        // Trennpfeil zwischen Übungen
                        if idx < exerciseNames.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, Space.s3)
            .padding(.vertical, Space.s2)
            .background(Theme.success.opacity(0.09), in: RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    /// Sheet-Modifier wird von beiden Zweigen über den jeweiligen .card() angehängt.
    private func withInstructionsSheet<V: View>(_ view: V) -> some View {
        view
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

    // MARK: - Weight-Zweig (unverändert gegenüber dem Original)

    private var weightBasedContent: some View {
        withInstructionsSheet(
            VStack(spacing: Space.s5) {
                cardHeader

                supersetTracker

                Rectangle()
                    .fill(Theme.lineSoft)
                    .frame(height: 1)

                HStack(spacing: Space.s6) {
                    VStack(spacing: Space.s1) {
                        Text(set.weight > 0 ? String(format: "%.2f", set.weight) : "0.00")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(set.weight > 0 ? Theme.textPrimary : Theme.textSecondary)

                        Text(set.weight > 0 ? "kg" : "Körpergewicht")
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(Theme.line)
                        .frame(width: 1, height: 50)

                    VStack(spacing: Space.s1) {
                        Text("\(set.reps)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)

                        Text("Wdh.")
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Dezente Referenz-Zeile: Werte aus letzter Session (nur wenn >= 2 Saetze abwichen)
                if let ref = lastSessionReference {
                    Text("Letztes Mal: \(ref.reps) Wdh. × \(formattedLastWeight(ref))")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textTertiary)
                }

                // Aktionen: Anpassen (sekundär) + Satz abschließen (primär, voll Akzent)
                HStack(spacing: Space.s3) {
                    Button {
                        selectedSetForEdit = set
                    } label: {
                        Label("Anpassen", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.mcSecondary)

                    Button {
                        onComplete(set)
                    } label: {
                        Label("Satz abschließen", systemImage: "checkmark")
                    }
                    .buttonStyle(.mcPrimary)
                }
            }
            .card()
        )
    }

    // MARK: - Time-Zweig

    /// Eingebetteter Time-Inhalt — ausgelagert nach ActiveTimeSetContent (Zeilenlimit).
    private var timeBasedContent: some View {
        withInstructionsSheet(
            VStack(spacing: Space.s5) {
                cardHeader

                supersetTracker

                Rectangle()
                    .fill(Theme.lineSoft)
                    .frame(height: 1)

                ActiveTimeSetContent(
                    set: set,
                    countdown: countdown,
                    onComplete: onComplete
                )
            }
            .card()
        )
    }

    // Nur anzeigen, wenn Übungsanleitungen vorhanden sind
    private var hasInstructions: Bool {
        guard let exercise else { return false }
        let instructions = (exercise.instructions ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let description = exercise.exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return !instructions.isEmpty || !description.isEmpty
    }

    /// Formatiert das Gewicht der historischen Referenz.
    /// Bei Koerpergewichts-Uebungen (weight == 0): "Koerpergewicht".
    /// Bei unilateralen Uebungen: "2× X,X kg" (halbes Gewicht pro Seite).
    private func formattedLastWeight(_ ref: LastSessionReferenceCalcEngine.Reference) -> String {
        guard ref.weight > 0 else { return "Körpergewicht" }
        let isUnilateral = set.isUnilateralSnapshot || (exercise?.isUnilateral ?? false)
        if isUnilateral {
            let perSide = ref.weight / 2
            return "2× \(formatWeight(perSide)) kg"
        }
        return "\(formatWeight(ref.weight)) kg"
    }

    /// Gewicht als lokalisierte Zeichenkette (keine fuehrenden Nullen, max. 1 Nachkommastelle).
    private func formatWeight(_ w: Double) -> String {
        // Ganzzahliges Gewicht ohne Nachkommastelle anzeigen (z.B. "80" statt "80.0")
        if w.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", w)
        }
        return String(format: "%.1f", w)
    }
}

