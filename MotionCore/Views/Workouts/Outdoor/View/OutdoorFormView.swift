//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basisdarstellung                                                 /
// Datei . . . . : OutdoorFormView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Erfassungs-/Bearbeitungs-View für E-Bike-Touren                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct OutdoorFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    let mode: FormMode

    /// SwiftData-Model – direkt bearbeitbar via @Bindable
    @Bindable var session: OutdoorSession

    // MARK: - Lokaler UI-State

    // Wheel-Picker für Dauer
    @State private var showDurationWheel = false

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    // Focus für Keyboard-Navigation
    @FocusState private var focusedField: OutdoorFocusedField?

    // Reihenfolge der Felder für Keyboard-Navigation
    private let fieldOrder: [OutdoorFocusedField] = [
        .routeName,
        .startStreet, .startPostalCode, .startCity,
        .endStreet, .endPostalCode, .endCity,
        .distance, .elevationGain,
        .averageSpeed, .maxSpeed,
        .calories, .heartRate, .maxHeartRate,
        .bodyWeight, .temperature
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: GlassCard 1: Route & Adresse
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Route")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        OutdoorRouteNameSection(
                            routeName: $session.routeName,
                            date: $session.date,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorAddressSection(
                            startStreet: $session.startStreet,
                            startPostalCode: $session.startPostalCode,
                            startCity: $session.startCity,
                            endStreet: $session.endStreet,
                            endPostalCode: $session.endPostalCode,
                            endCity: $session.endCity,
                            focusedField: $focusedField
                        )
                    }
                    .glassCard()
                    .padding(.horizontal)

                    // MARK: GlassCard 2: Leistungsdaten
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Leistungsdaten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        OutdoorDurationSection(
                            duration: $session.duration,
                            showWheel: $showDurationWheel
                        )

                        Divider()

                        OutdoorDistanceSection(
                            distance: $session.distance,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorElevationSection(
                            elevationGain: $session.elevationGain,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorSpeedSection(
                            averageSpeed: $session.averageSpeed,
                            maxSpeed: $session.maxSpeed,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorCaloriesSection(
                            calories: $session.calories,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorHeartRateSection(
                            heartRate: $session.heartRate,
                            maxHeartRate: $session.maxHeartRate,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorBodyWeightSection(
                            bodyWeight: $session.bodyWeight,
                            focusedField: $focusedField
                        )
                    }
                    .glassCard()
                    .padding(.horizontal)

                    // MARK: GlassCard 3: Bewertung
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bewertung")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        OutdoorWeatherSection(
                            weatherCondition: $session.weatherCondition,
                            temperature: $session.temperature,
                            focusedField: $focusedField
                        )

                        Divider()

                        OutdoorRPESection(perceivedExertion: $session.perceivedExertion)

                        Divider()

                        OutdoorEnergySection(energyLevelBefore: $session.energyLevelBefore)

                        Divider()

                        OutdoorIntensitySection(intensity: $session.intensity)
                    }
                    .glassCard()
                    .padding(.horizontal)

                    // MARK: GlassCard 4: Notizen
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notizen")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        TextEditor(text: $session.notes)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                    }
                    .glassCard()
                    .padding(.horizontal)
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mode == .add ? "E-Bike Tour" : "Tour bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Speichern
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismissKeyboard()
                    saveSession()
                } label: {
                    IconType(icon: .system("checkmark"), color: .blue, size: 16)
                        .glassButton(size: 36, accentColor: .blue)
                }
            }

            // Löschen im Edit-Modus
            if mode == .edit {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        dismissKeyboard()
                        showDeleteAlert = true
                    } label: {
                        IconType(icon: .system("trash"), color: .red, size: 16)
                            .glassButton(size: 36, accentColor: .red)
                    }
                }
            }
        }
        // Keyboard-Toolbar mit Navigation (eigene Implementierung für OutdoorFocusedField)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                // Vorheriges / Nächstes Feld
                HStack(spacing: 0) {
                    Button {
                        navigateToPreviousField()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(canNavigatePrevious ? .primary : .secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(!canNavigatePrevious)

                    Button {
                        navigateToNextField()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.body.weight(.medium))
                            .foregroundStyle(canNavigateNext ? .primary : .secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(!canNavigateNext)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                Spacer()

                // Fertig-Button
                Button {
                    dismissKeyboard()
                    focusedField = nil
                } label: {
                    Text("Fertig")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
        .alert("Tour löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("Diese Tour wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Keyboard-Navigation

    private var canNavigatePrevious: Bool {
        guard let current = focusedField,
              let index = fieldOrder.firstIndex(of: current) else { return false }
        return index > 0
    }

    private var canNavigateNext: Bool {
        guard let current = focusedField,
              let index = fieldOrder.firstIndex(of: current) else { return false }
        return index < fieldOrder.count - 1
    }

    private func navigateToPreviousField() {
        guard let current = focusedField,
              let index = fieldOrder.firstIndex(of: current),
              index > 0 else { return }
        focusedField = fieldOrder[index - 1]
    }

    private func navigateToNextField() {
        guard let current = focusedField,
              let index = fieldOrder.firstIndex(of: current),
              index < fieldOrder.count - 1 else { return }
        focusedField = fieldOrder[index + 1]
    }

    // MARK: - Speichern

    private func saveSession() {
        // Startadresse aus strukturierten Feldern zusammenbauen
        session.startLocation = buildLocationString(
            street: session.startStreet,
            postalCode: session.startPostalCode,
            city: session.startCity
        )

        // Zieladresse aus strukturierten Feldern zusammenbauen
        session.endLocation = buildLocationString(
            street: session.endStreet,
            postalCode: session.endPostalCode,
            city: session.endCity
        )

        // Aktivität auf E-Bike setzen
        session.outdoorActivity = .eBike

        // Session als abgeschlossen markieren
        session.isCompleted = true
        session.isLiveSession = false

        // SwiftData: insert bei neuer Session
        if mode == .add {
            context.insert(session)
        }
        try? context.save()

        // Supabase Upload (analog FormView)
        if mode == .add {
            Task {
                let success = await SupabaseSessionService.shared.upload(session)
                if success {
                    await MainActor.run {
                        session.syncedToSupabase = true
                        try? context.save()
                    }
                }
            }
        } else if mode == .edit, session.syncedToSupabase {
            // Bestehende Session: für Resync markieren
            session.needsSupabaseResync = true
            try? context.save()
        }

        dismiss()
    }

    // MARK: - Löschen

    private func deleteSession() {
        context.delete(session)
        try? context.save()
        dismiss()
    }

    // MARK: - Hilfsfunktionen

    // Baut einen lesbaren Ortsstring aus Straße, PLZ und Stadt
    private func buildLocationString(street: String, postalCode: String, city: String) -> String {
        let postalAndCity = "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)
        return [street, postalAndCity]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    let session = OutdoorSession(outdoorActivity: .eBike)

    return NavigationStack {
        OutdoorFormView(mode: .add, session: session)
            .modelContainer(PreviewData.sharedContainer)
            .environmentObject(AppSettings.shared)
    }
}
