//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyMeasurementEntrySheet.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Karussell-Sheet zur Erfassung und Bearbeitung von Körpermaßen    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct BodyMeasurementEntrySheet: View {

    // MARK: - Props

    let editingMeasurement: BodyMeasurement?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Lokaler State

    @State private var date: Date
    @State private var bodyWeight: Double?
    @State private var chestCircumference: Double?
    @State private var waistCircumference: Double?
    @State private var abdomenCircumference: Double?
    @State private var hipCircumference: Double?
    @State private var armRight: Double?
    @State private var armLeft: Double?
    @State private var thighRight: Double?
    @State private var thighLeft: Double?
    @State private var armBothSides: Bool
    @State private var thighBothSides: Bool
    @State private var currentSlide: Int = 0

    // MARK: - Init

    init(editingMeasurement: BodyMeasurement?) {
        self.editingMeasurement = editingMeasurement
        if let m = editingMeasurement {
            _date = State(initialValue: m.date)
            _bodyWeight = State(initialValue: m.bodyWeight)
            _chestCircumference = State(initialValue: m.chestCircumference)
            _waistCircumference = State(initialValue: m.waistCircumference)
            _abdomenCircumference = State(initialValue: m.abdomenCircumference)
            _hipCircumference = State(initialValue: m.hipCircumference)
            _armRight = State(initialValue: m.armCircumferenceRight)
            _armLeft = State(initialValue: m.armCircumferenceLeft)
            _thighRight = State(initialValue: m.thighCircumferenceRight)
            _thighLeft = State(initialValue: m.thighCircumferenceLeft)
            _armBothSides = State(initialValue: m.armCircumferenceLeft != nil)
            _thighBothSides = State(initialValue: m.thighCircumferenceLeft != nil)
        } else {
            _date = State(initialValue: Date())
            _bodyWeight = State(initialValue: nil)
            _chestCircumference = State(initialValue: nil)
            _waistCircumference = State(initialValue: nil)
            _abdomenCircumference = State(initialValue: nil)
            _hipCircumference = State(initialValue: nil)
            _armRight = State(initialValue: nil)
            _armLeft = State(initialValue: nil)
            _thighRight = State(initialValue: nil)
            _thighLeft = State(initialValue: nil)
            _armBothSides = State(initialValue: AppSettings.shared.bodyMeasurementArmMode == .bothSides)
            _thighBothSides = State(initialValue: AppSettings.shared.bodyMeasurementThighMode == .bothSides)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Datumspicker unterhalb der NavigationBar
                HStack {
                    DatePicker(
                        "Datum",
                        selection: $date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "de_DE"))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Karussell
                TabView(selection: $currentSlide) {
                    BodyMeasurementEntrySlide(
                        title: "Körpergewicht",
                        unit: "kg",
                        iconSystemName: "scalemass",
                        value: $bodyWeight,
                        onSkip: advanceSlide
                    )
                    .tag(0)

                    BodyMeasurementEntrySlide(
                        title: "Brustumfang",
                        unit: "cm",
                        iconSystemName: "figure.arms.open",
                        value: $chestCircumference,
                        onSkip: advanceSlide
                    )
                    .tag(1)

                    BodyMeasurementEntrySlide(
                        title: "Taillenumfang",
                        unit: "cm",
                        iconSystemName: "figure.stand",
                        value: $waistCircumference,
                        onSkip: advanceSlide
                    )
                    .tag(2)

                    BodyMeasurementEntrySlide(
                        title: "Bauchumfang",
                        unit: "cm",
                        iconSystemName: "figure.stand",
                        value: $abdomenCircumference,
                        onSkip: advanceSlide
                    )
                    .tag(3)

                    BodyMeasurementEntrySlide(
                        title: "Hüftumfang",
                        unit: "cm",
                        iconSystemName: "figure.walk",
                        value: $hipCircumference,
                        onSkip: advanceSlide
                    )
                    .tag(4)

                    BodyMeasurementEntrySlide(
                        title: "Armumfang",
                        unit: "cm",
                        iconSystemName: "figure.strengthtraining.traditional",
                        value: $armRight,
                        secondValue: $armLeft,
                        bothSidesLabels: ("Links", "Rechts"),
                        bothSides: $armBothSides,
                        onSkip: advanceSlide
                    )
                    .tag(5)

                    BodyMeasurementEntrySlide(
                        title: "Oberschenkelumfang",
                        unit: "cm",
                        iconSystemName: "figure.run",
                        value: $thighRight,
                        secondValue: $thighLeft,
                        bothSidesLabels: ("Links", "Rechts"),
                        bothSides: $thighBothSides,
                        onSkip: advanceSlide
                    )
                    .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationTitle(editingMeasurement == nil ? "Neue Messung" : "Messung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .calmSheet([.medium, .large])
    }

    // MARK: - Aktionen

    private func advanceSlide() {
        withAnimation {
            if currentSlide < 6 { currentSlide += 1 }
        }
    }

    private func save() {
        if let m = editingMeasurement {
            // Edit-Modus: direkt auf @Model schreiben (SwiftData tracked automatisch)
            m.date = date
            m.bodyWeight = bodyWeight
            m.chestCircumference = chestCircumference
            m.waistCircumference = waistCircumference
            m.abdomenCircumference = abdomenCircumference
            m.hipCircumference = hipCircumference
            applyArmSideMode(to: m)
            applyThighSideMode(to: m)
            m.needsSupabaseResync = true
        } else {
            // Neu-Modus: Objekt anlegen und einfügen
            let m = BodyMeasurement(date: date)
            m.bodyWeight = bodyWeight
            m.chestCircumference = chestCircumference
            m.waistCircumference = waistCircumference
            m.abdomenCircumference = abdomenCircumference
            m.hipCircumference = hipCircumference
            applyArmSideMode(to: m)
            applyThighSideMode(to: m)
            modelContext.insert(m)
        }
        try? modelContext.save()
        dismiss()
    }

    private func applyArmSideMode(to m: BodyMeasurement) {
        if armBothSides {
            m.armCircumferenceRight = armRight
            m.armCircumferenceLeft = armLeft
        } else {
            m.armCircumferenceRight = armRight
            m.armCircumferenceLeft = nil
        }
    }

    private func applyThighSideMode(to m: BodyMeasurement) {
        if thighBothSides {
            m.thighCircumferenceRight = thighRight
            m.thighCircumferenceLeft = thighLeft
        } else {
            m.thighCircumferenceRight = thighRight
            m.thighCircumferenceLeft = nil
        }
    }
}

// MARK: - Preview

#Preview("Neu") {
    BodyMeasurementEntrySheet(editingMeasurement: nil)
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
