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
