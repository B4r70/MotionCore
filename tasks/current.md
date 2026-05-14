# BodyMeasurement-Feature — Phase 6 / Schritt 4: Detail-History & Edit/Delete

**Status:** Bereit zur Implementierung · **Komplexität:** Small-Medium · **Scope:** Phase 6, Schritt 4

---

## Schritte

### 1. `BodyMeasurementHistorySheet.swift` anlegen
**Pfad:** `MotionCore/Views/Body/BodyMeasurements/BodyMeasurementHistorySheet.swift`
- Props: `title: String`, `unit: String`, `keyPath: KeyPath<BodyMeasurement, Double?>`, `measurements: [BodyMeasurement]`
- Filtert auf Einträge mit non-nil-Wert, absteigend nach Datum
- `NavigationStack` mit Titel = `title`
- `List` mit Datum + Wert (1 Nachkommastelle + unit)
- `.swipeActions(edge: .trailing)`: Delete-Button → `modelContext.delete(measurement)` + `try? modelContext.save()`
- Tap auf Zeile → öffnet `BodyMeasurementEntrySheet(editingMeasurement:)` per `.sheet(item:)` (CLAUDE.md Sheet-Pattern)
- `@Environment(\.modelContext)`, `@EnvironmentObject private var appSettings: AppSettings`
- Leerer Zustand: Hinweistext „Noch keine Messungen für diesen Maß-Typ"

### 2. `BodyMeasurementsValueCarousel.swift` anpassen
- Neues internes `struct MeasurementDetailContext: Identifiable` mit `let id = UUID()`, `title`, `unit`, `keyPath`
- `@State private var detailContext: MeasurementDetailContext?` in `BodyMeasurementsValueCarousel`
- In der ForEach-Schleife: `.onTapGesture { detailContext = MeasurementDetailContext(title: type.title, unit: type.unit, keyPath: type.keyPath) }` auf `BodyMeasurementHeroCard`
- `.sheet(item: $detailContext)` auf dem `TabView` → öffnet `BodyMeasurementHistorySheet`
- Sheet braucht `.environmentObject(AppSettings.shared)` (für BodyMeasurementEntrySheet)

---

## Akzeptanzkriterien
- [ ] Build erfolgreich
- [ ] Tap auf Karussell-Card öffnet History-Sheet mit korrektem Titel
- [ ] Nur Einträge mit Wert für diesen Maß-Typ sichtbar
- [ ] Swipe-to-Delete löscht Messung persistent
- [ ] Tap auf Zeile öffnet Edit-Sheet, Änderungen werden gespeichert
- [ ] Sheet-Pattern: `.sheet(item:)` für beide Sheets (kein `.sheet(isPresented:)`)

---

## Fortschritt

**09.05.2026**

Abgeschlossene Schritte: 1, 2

Geänderte Dateien:
- `MotionCore/Views/Body/BodyMeasurements/BodyMeasurementHistorySheet.swift` (neu angelegt)
- `MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsValueCarousel.swift` (MeasurementDetailContext + State + onTapGesture + sheet(item:) hinzugefügt)

---

## Review-Finding L1-012 — SupabaseClient graceful degradation

**14.05.2026**

Abgeschlossene Schritte: alle (L1-012 vollständig)

Geänderte Dateien:
- `MotionCore/Models/Types/ErrorTypes.swift` — `notConfigured` case + `errorDescription` zu `SupabaseError` hinzugefügt (Zeile 22, 37)
- `MotionCore/Services/Database/Remote/Core/SupabaseClient.swift` — `baseURL`/`anonKey` auf `Optional` geändert, `fatalError` durch `print`-Warnung ersetzt, `makeRequest` ist jetzt `throws`, alle public-Methoden (get/post x2/rpc/upsert x2/patchWhere/deleteWhere) werfen `SupabaseError.notConfigured` wenn Konfiguration fehlt

---

## Review-Finding L1-002 — HealthMetricCalcEngine CalcEngine-Reinheit

**14.05.2026**

Abgeschlossene Schritte: alle (L1-002 vollständig)

Geänderte Dateien:
- `MotionCore/Services/Calculation/HealthMetricCalcEngine.swift` — `class : ObservableObject` → `struct`, `import Combine`/`import SwiftUI` entfernt, Init nimmt jetzt konkrete Werte statt `AppSettings`, `calculateTodayCalorieBalance` nimmt `consumed/basal/active: Int?` statt `HealthKitManager`, `CalorieBalance.statusColor` aus der struct entfernt (war SwiftUI-Abhängigkeit)
- `MotionCore/Views/Statistics/Health/Components/HealthMetricCalorieHeroCard.swift` — `CalorieBalance` SwiftUI-Extension mit `statusColor: Color` hinzugefügt (vor dem Preview-Block)
- `MotionCore/Views/Statistics/Health/View/HealthMetricView.swift` — Engine-Init und `calculateTodayCalorieBalance`-Aufruf auf neue Signatur umgestellt; View extrahiert konkrete Werte aus `AppSettings` und `HealthKitManager`
