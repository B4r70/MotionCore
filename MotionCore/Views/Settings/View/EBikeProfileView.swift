//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : EBikeProfileView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : E-Bike-Profil in den Einstellungen (kein SwiftData, AppSettings) /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct EBikeProfileView: View {
    @EnvironmentObject private var appSettings: AppSettings

    // Lokaler State fuer optionale DatePicker
    @State private var showPurchaseDatePicker = false
    @State private var showLastMaintenancePicker = false

    // MARK: - Double-zu-String Binding Helpers

    /// Binding fuer Gewicht (kg) mit Komma/Punkt-Normalisierung
    private var weightBinding: Binding<String> {
        Binding(
            get: {
                appSettings.eBikeWeight > 0
                    ? String(format: "%.1f", appSettings.eBikeWeight)
                    : ""
            },
            set: { raw in
                let normalized = raw.replacingOccurrences(of: ",", with: ".")
                appSettings.eBikeWeight = Double(normalized) ?? 0
            }
        )
    }

    /// Binding fuer Kilometerstand mit Komma/Punkt-Normalisierung
    private var kilometersBinding: Binding<String> {
        Binding(
            get: {
                appSettings.eBikeKilometers > 0
                    ? String(format: "%.1f", appSettings.eBikeKilometers)
                    : ""
            },
            set: { raw in
                let normalized = raw.replacingOccurrences(of: ",", with: ".")
                appSettings.eBikeKilometers = Double(normalized) ?? 0
            }
        )
    }

    /// Binding fuer Wartungsintervall mit Komma/Punkt-Normalisierung
    private var maintenanceIntervalBinding: Binding<String> {
        Binding(
            get: {
                appSettings.eBikeMaintenanceIntervalKm > 0
                    ? String(format: "%.0f", appSettings.eBikeMaintenanceIntervalKm)
                    : ""
            },
            set: { raw in
                let normalized = raw.replacingOccurrences(of: ",", with: ".")
                appSettings.eBikeMaintenanceIntervalKm = Double(normalized) ?? 1000
            }
        )
    }

    // MARK: - Berechnete Werte

    /// Berechnet das Alter des Fahrrads als lesbaren String
    private var bikeAgeText: String? {
        guard let purchaseDate = appSettings.eBikePurchaseDate else { return nil }
        let components = Calendar.current.dateComponents([.year, .month], from: purchaseDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years > 0 && months > 0 {
            return "\(years) Jahr\(years == 1 ? "" : "e"), \(months) Monat\(months == 1 ? "" : "e")"
        } else if years > 0 {
            return "\(years) Jahr\(years == 1 ? "" : "e")"
        } else {
            return "\(months) Monat\(months == 1 ? "" : "e")"
        }
    }

    /// Prueft ob Wartung faellig ist
    private var isMaintenanceDue: Bool {
        guard let lastDate = appSettings.eBikeLastMaintenanceDate,
              appSettings.eBikeMaintenanceIntervalKm > 0 else { return false }
        // Vereinfachte Berechnung: Annahme 200 km/Monat seit letzter Wartung
        let months = Calendar.current.dateComponents([.month], from: lastDate, to: Date()).month ?? 0
        let estimatedKmSinceMaintenance = Double(months) * 200
        return estimatedKmSinceMaintenance >= appSettings.eBikeMaintenanceIntervalKm
    }

    // MARK: - Body

    var body: some View {
        List {
            stammdatenSection
            zustandSection
            notizenSection
        }
        .navigationTitle("E-Bike Profil")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Section: Stammdaten

    private var stammdatenSection: some View {
        Section("Stammdaten") {
            // Name des Fahrrads
            HStack {
                Text("Name")
                Spacer()
                TextField("z.B. Canyon Pathlite:ON", text: $appSettings.eBikeName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            // Fahrradtyp als Picker
            Picker("Fahrradtyp", selection: $appSettings.eBikeType) {
                ForEach(BikeType.allCases) { type in
                    Label(type.description, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)

            // Rahmengroesse als Stepper
            Stepper(
                "Rahmengröße: \(appSettings.eBikeFrameSize) cm",
                value: $appSettings.eBikeFrameSize,
                in: 0...80
            )

            // Gewicht als TextField mit kg-Einheit
            HStack {
                Text("Gewicht")
                Spacer()
                TextField("0,0", text: weightBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text("kg").foregroundStyle(.secondary)
            }

            // Akkukapazitaet als TextField mit Wh-Einheit
            HStack {
                Text("Akkukapazität")
                Spacer()
                TextField("0", value: $appSettings.eBikeBatteryCapacity, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text("Wh").foregroundStyle(.secondary)
            }

            // Reifengroesse als Picker
            Picker("Reifengröße", selection: $appSettings.eBikeTireSize) {
                ForEach(TireSize.allCases) { size in
                    Text(size.description).tag(size)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)
        }
    }

    // MARK: - Section: Zustand & Wartung

    private var zustandSection: some View {
        Section("Zustand & Wartung") {
            // Zustand-Picker mit farbiger Tint-Anpassung
            Picker("Zustand", selection: $appSettings.eBikeCondition) {
                ForEach(BikeCondition.allCases) { condition in
                    Text(condition.description).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .tint(appSettings.eBikeCondition.color)

            // Kilometerstand
            HStack {
                Text("Kilometerstand")
                Spacer()
                TextField("0", text: kilometersBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("km").foregroundStyle(.secondary)
            }

            // Kaufdatum – Toggle aktiviert optionalen DatePicker
            purchaseDateRow

            // Berechnetes Alter (nur wenn Kaufdatum gesetzt)
            if let ageText = bikeAgeText {
                HStack {
                    Text("Alter")
                    Spacer()
                    Text(ageText)
                        .foregroundStyle(.secondary)
                }
            }

            // Wartungsintervall
            HStack {
                Text("Wartungsintervall")
                Spacer()
                TextField("1000", text: maintenanceIntervalBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("km").foregroundStyle(.secondary)
            }

            // Letzte Wartung – Toggle aktiviert optionalen DatePicker
            lastMaintenanceRow

            // Wartungshinweis-Banner wenn Wartung faellig
            if isMaintenanceDue {
                maintenanceBanner
            }
        }
    }

    // MARK: - Kaufdatum Row

    private var purchaseDateRow: some View {
        Group {
            HStack {
                Text("Kaufdatum")
                Spacer()
                if appSettings.eBikePurchaseDate != nil {
                    Button("Entfernen") {
                        appSettings.eBikePurchaseDate = nil
                        showPurchaseDatePicker = false
                    }
                    .foregroundStyle(.red)
                    .font(.callout)
                } else {
                    Button("Setzen") {
                        appSettings.eBikePurchaseDate = Date()
                        showPurchaseDatePicker = true
                    }
                    .foregroundStyle(.blue)
                    .font(.callout)
                }
            }

            if showPurchaseDatePicker, let binding = Binding($appSettings.eBikePurchaseDate) {
                DatePicker(
                    "Kaufdatum wählen",
                    selection: binding,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .transition(.opacity)
            } else if let purchaseDate = appSettings.eBikePurchaseDate {
                HStack {
                    Text("").hidden()
                    Spacer()
                    Button(purchaseDate.formatted(date: .long, time: .omitted)) {
                        showPurchaseDatePicker.toggle()
                    }
                    .foregroundStyle(.secondary)
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - Letzte Wartung Row

    private var lastMaintenanceRow: some View {
        Group {
            HStack {
                Text("Letzte Wartung")
                Spacer()
                if appSettings.eBikeLastMaintenanceDate != nil {
                    Button("Entfernen") {
                        appSettings.eBikeLastMaintenanceDate = nil
                        showLastMaintenancePicker = false
                    }
                    .foregroundStyle(.red)
                    .font(.callout)
                } else {
                    Button("Setzen") {
                        appSettings.eBikeLastMaintenanceDate = Date()
                        showLastMaintenancePicker = true
                    }
                    .foregroundStyle(.blue)
                    .font(.callout)
                }
            }

            if showLastMaintenancePicker, let binding = Binding($appSettings.eBikeLastMaintenanceDate) {
                DatePicker(
                    "Datum wählen",
                    selection: binding,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .transition(.opacity)
            } else if let lastDate = appSettings.eBikeLastMaintenanceDate {
                HStack {
                    Text("").hidden()
                    Spacer()
                    Button(lastDate.formatted(date: .long, time: .omitted)) {
                        showLastMaintenancePicker.toggle()
                    }
                    .foregroundStyle(.secondary)
                    .font(.callout)
                }
            }
        }
    }

    // MARK: - Wartungshinweis-Banner

    private var maintenanceBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Wartung empfohlen")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Text("Das Wartungsintervall wurde überschritten.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Section: Notizen

    private var notizenSection: some View {
        Section("Notizen") {
            TextEditor(text: $appSettings.eBikeNotes)
                .frame(minHeight: 80)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EBikeProfileView()
    }
    .environmentObject(AppSettings.shared)
}
