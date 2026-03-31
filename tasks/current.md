# DecimalTextField — Dezimal-Eingabe ohne Nullen-Auffüllung

**Complexity:** Medium

## Summary

Behebung des UX-Problems bei Dezimal-Eingaben in OutdoorFormSections und anderen FormViews. Aktuell füllt `String(format:)` im `Binding(get:)` nach jeder Ziffer Nullen auf (z.B. "1" wird zu "1.00"), was die Eingabe über das Numpad sehr mühsam macht. Lösung: Eine wiederverwendbare `DecimalTextField`-Komponente mit lokalem String-Puffer, die während der Eingabe den rohen Text anzeigt und erst beim Verlassen des Feldes formatiert.

## Scope

**Enthalten:**
- Neue wiederverwendbare Komponente `DecimalTextField` in `Components/Forms/`
- Adoption in `OutdoorFormSectionsMetrics.swift` (5 Felder: Distanz, Elevation, avgSpeed, maxSpeed, bodyWeight)
- Adoption in `OutdoorFormSections.swift` (1 Feld: Temperatur — Vereinfachung des bestehenden @State-Workarounds)
- Adoption in `FormViewSection.swift` (2 Felder: DistanceInputRow, BodyWeightInputRow)
- Adoption in `EBikeProfileView.swift` (3 Bindings: weight, kilometers, maintenanceInterval)

**Explizit ausgeschlossen:**
- Keine Änderung an Int-basierten Feldern (Kalorien, Herzfrequenz, Dauer)
- Keine Änderung an der Datenstruktur/Model-Ebene

## Affected Files

### Neue Datei
- `MotionCore/Components/Forms/DecimalTextField.swift` — Wiederverwendbare Komponente mit lokalem @State String-Puffer und Focus-gesteuerter Formatierung

### Geänderte Dateien
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSectionsMetrics.swift` — 5 Dezimalfelder ersetzen
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSections.swift` — Temperatur-Feld vereinfachen
- `MotionCore/Components/Forms/FormViewSection.swift` — DistanceInputRow + BodyWeightInputRow ersetzen
- `MotionCore/Views/Settings/View/EBikeProfileView.swift` — 3 computed Binding-Properties ersetzen

## Risks

- **Focus-Tracking:** `@FocusState` kann bei schnellem Feldwechsel Zwischenzustände haben — Formatierung auch auf `onSubmit` als Safety-Net
- **Komma/Punkt-Lokalisierung:** iOS decimalPad zeigt je nach Locale Komma oder Punkt — beide normalisieren
- **Breite Adoption:** 4 betroffene Dateien — bei nicht-identischer Signatur Build-Fehler

## Implementation Steps

- [x] **1. DecimalTextField erstellen** (`MotionCore/Components/Forms/DecimalTextField.swift`)
  - Signatur: `value: Binding<Double>`, `placeholder: String = "0"`, `decimalPlaces: Int = 1`
  - Interner `@State private var text: String` und `@FocusState private var isFocused: Bool`
  - `onAppear`: Wert formatiert in `text` schreiben (nur wenn value > 0)
  - `onChange(of: isFocused)`: Bei Focus-Verlust — Komma zu Punkt normalisieren, parsen, value aktualisieren, text formatieren
  - Während der Eingabe: rohen String in `text` speichern, value parallel aktualisieren
  - `.keyboardType(.decimalPad)`, `.multilineTextAlignment(.trailing)`

- [x] **2. OutdoorFormSectionsMetrics.swift migrieren**
  - `OutdoorDistanceSection`: DecimalTextField, decimalPlaces: 2
  - `OutdoorElevationSection`: DecimalTextField, decimalPlaces: 0
  - `OutdoorSpeedSection` (2 Felder): DecimalTextField, decimalPlaces: 1
  - `OutdoorBodyWeightSection`: DecimalTextField, decimalPlaces: 1
  - `.focused(focusedField, equals: .xxx)` als äußerer Modifier beibehalten

- [x] **3. OutdoorFormSections.swift migrieren**
  - `OutdoorWeatherSection`: `@State temperatureText` + onAppear entfernen, durch DecimalTextField ersetzen
  - Double?-Binding via Wrapper-Binding (nil → 0.0)

- [x] **4. FormViewSection.swift migrieren**
  - `DistanceInputRow`: Binding(get:set:) durch DecimalTextField ersetzen (decimalPlaces: 2)
  - `BodyWeightInputRow`: `TextField(value:format:)` durch DecimalTextField ersetzen (decimalPlaces: 1)

- [x] **5. EBikeProfileView.swift migrieren**
  - `weightBinding`, `kilometersBinding`, `maintenanceIntervalBinding` computed Properties entfernen
  - Durch direkte DecimalTextField-Aufrufe ersetzen

## Manual Verification

- [ ] Xcode Build (`Cmd+B`) — gesamtes Projekt kompiliert fehlerfrei
- [ ] OutdoorFormView Preview: Dezimalfelder zeigen Placeholder bei 0
- [ ] Simulator: Distanz-Feld antippen, "42" tippen → "42" (NICHT "42.00"), Feld verlassen → "42.00"
- [ ] Simulator: Speed-Feld antippen, "25" tippen, nächstes Feld → "25.0"
- [ ] Simulator: Feld leeren, nichts eingeben, Feld verlassen → leer oder Placeholder
- [ ] Simulator: Komma tippen (deutsches Keyboard) → korrekt als Dezimaltrennzeichen akzeptiert
- [ ] Keyboard-Navigation (Pfeile oben/unten) in OutdoorFormView funktioniert weiterhin
- [ ] EBikeProfileView: Gewicht eingeben — kein Nullen-Auffüllen
- [ ] Cardio FormView: Distanz eingeben — kein Nullen-Auffüllen
- [ ] Session speichern — korrekte Werte in SwiftData

---

## Fortschritt

**Datum:** 2026-03-31

**Abgeschlossene Schritte:** 1–5 (alle Implementierungsschritte)

**Geänderte / neue Dateien:**
- `MotionCore/Components/Forms/DecimalTextField.swift` — NEU erstellt
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSectionsMetrics.swift` — 5 Felder migriert
- `MotionCore/Views/Workouts/Outdoor/Components/OutdoorFormSections.swift` — Temperatur-Feld migriert, @State temperatureText + onAppear entfernt
- `MotionCore/Components/Forms/FormViewSection.swift` — DistanceInputRow + BodyWeightInputRow migriert
- `MotionCore/Views/Settings/View/EBikeProfileView.swift` — 3 computed Binding-Properties entfernt, DecimalTextField direkt eingesetzt

**Hinweis:** `DecimalTextField.swift` ist eine neue Datei — muss in Xcode manuell zum Target hinzugefügt werden (File Inspector → Target Membership), sofern Xcode 16 die Datei nicht automatisch erkennt.

**Offene Punkte:** Manual Verification (Xcode Build + Simulator-Tests) — durch Quality Gate zu prüfen.
