//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen / Komponenten                                      /
// Datei . . . . : StudioEquipmentEditSheet.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Sheet zum Anlegen und Bearbeiten eines Studio-Geraets            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct StudioEquipmentEditSheet: View {

    // MARK: - Props

    let studio: Studio
    let existing: StudioEquipment?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Lokaler State (Cancel-Safe Kopien)

    @State private var name: String
    @State private var equipmentType: StudioEquipmentType
    @State private var startWeight: Double
    @State private var increment: Double
    @State private var minWeight: Double
    @State private var hasMaxWeight: Bool
    @State private var maxWeightValue: Double
    @State private var intermediateIncrements: [Double]
    @State private var notes: String
    @State private var validationError: String? = nil

    // MARK: - Init

    init(studio: Studio, existing: StudioEquipment?) {
        self.studio = studio
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _equipmentType = State(initialValue: existing?.equipmentType ?? .machine)
        _startWeight = State(initialValue: existing?.startWeight ?? 0.0)
        _increment = State(initialValue: existing?.increment ?? 2.5)
        _minWeight = State(initialValue: existing?.minWeight ?? 0.0)
        _hasMaxWeight = State(initialValue: existing?.maxWeight != nil)
        _maxWeightValue = State(initialValue: existing?.maxWeight ?? 0.0)
        _intermediateIncrements = State(initialValue: existing?.intermediateIncrements ?? [])
        _notes = State(initialValue: existing?.notes ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basisSection
                gewichtSection
                zwischengewichteSection
                notizSection
            }
            .navigationTitle(existing == nil ? "Gerät hinzufügen" : "Gerät bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(existing == nil ? "Hinzufügen" : "Speichern") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(
                "Eingabe prüfen",
                isPresented: Binding(
                    get: { validationError != nil },
                    set: { if !$0 { validationError = nil } }
                ),
                presenting: validationError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
        }
    }

    // MARK: - Section: Basis

    private var basisSection: some View {
        Section("Basis") {
            // Gerätename
            HStack {
                Text("Name")
                Spacer()
                TextField("z.B. Kabelzug", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            // Gerätetyp-Picker
            Picker("Typ", selection: $equipmentType) {
                ForEach(StudioEquipmentType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.iconName).tag(type)
                }
            }
        }
    }

    // MARK: - Section: Gewicht

    private var gewichtSection: some View {
        Section("Gewicht") {

            // Startgewicht
            HStack {
                Text("Startgewicht")
                Spacer()
                DecimalTextField(value: $startWeight, placeholder: "0", decimalPlaces: 2)
                    .frame(width: 70)
                Text("kg").foregroundStyle(.secondary)
            }

            // Sprung (Increment)
            HStack {
                Text("Sprung")
                Spacer()
                DecimalTextField(value: $increment, placeholder: "2.5", decimalPlaces: 2)
                    .frame(width: 70)
                Text("kg").foregroundStyle(.secondary)
            }

            // Minimalgewicht
            HStack {
                Text("Minimalgewicht")
                Spacer()
                DecimalTextField(value: $minWeight, placeholder: "0", decimalPlaces: 2)
                    .frame(width: 70)
                Text("kg").foregroundStyle(.secondary)
            }

            // Max-Gewicht Toggle
            Toggle("Max-Gewicht festlegen", isOn: $hasMaxWeight)

            // Max-Gewicht Eingabe — nur wenn Toggle aktiv
            if hasMaxWeight {
                HStack {
                    Text("Max-Gewicht")
                    Spacer()
                    DecimalTextField(value: $maxWeightValue, placeholder: "0", decimalPlaces: 2)
                        .frame(width: 70)
                    Text("kg").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Section: Zwischengewichte

    private var zwischengewichteSection: some View {
        Section("Zwischengewichte") {
            ForEach(intermediateIncrements.indices, id: \.self) { idx in
                HStack {
                    DecimalTextField(value: $intermediateIncrements[idx], placeholder: "0.625", decimalPlaces: 3)
                    Text("kg").foregroundStyle(.secondary)
                }
            }
            .onDelete { indices in
                intermediateIncrements.remove(atOffsets: indices)
            }

            // Button zum Hinzufügen eines neuen Zwischengewichts
            Button("Zwischengewicht hinzufügen") {
                intermediateIncrements.append(0.625)
            }
        }
    }

    // MARK: - Section: Notiz

    private var notizSection: some View {
        Section("Notiz") {
            TextEditor(text: $notes)
                .frame(minHeight: 60)
        }
    }

    // MARK: - Speichern

    private func save() {
        // Validierung: Name nicht leer
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationError = "Name darf nicht leer sein."
            return
        }

        // Validierung: Increment > 0
        guard increment > 0 else {
            validationError = "Sprung muss größer als 0 sein."
            return
        }

        // Validierung: Startgewicht >= 0
        guard startWeight >= 0 else {
            validationError = "Startgewicht darf nicht negativ sein."
            return
        }

        // Validierung: MaxWeight > StartWeight (wenn gesetzt)
        if hasMaxWeight && maxWeightValue <= startWeight {
            validationError = "Max-Gewicht muss größer als Startgewicht sein."
            return
        }

        if let eq = existing {
            // Bestehendes Gerät aktualisieren
            eq.name = trimmedName
            eq.equipmentType = equipmentType
            eq.startWeight = startWeight
            eq.increment = increment
            eq.minWeight = minWeight
            eq.maxWeight = hasMaxWeight ? maxWeightValue : nil
            eq.intermediateIncrements = intermediateIncrements
            eq.notes = notes
        } else {
            // Neues Gerät anlegen
            let eq = StudioEquipment(
                name: trimmedName,
                equipmentType: equipmentType,
                startWeight: startWeight,
                increment: increment,
                intermediateIncrements: intermediateIncrements
            )
            eq.minWeight = minWeight
            eq.maxWeight = hasMaxWeight ? maxWeightValue : nil
            eq.notes = notes
            eq.studio = studio
            modelContext.insert(eq)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Neu hinzufügen") {
    let container = PreviewData.sharedContainer
    let studio = Studio(name: "Mein Studio", isPrimary: true)
    return StudioEquipmentEditSheet(studio: studio, existing: nil)
        .modelContainer(container)
}
