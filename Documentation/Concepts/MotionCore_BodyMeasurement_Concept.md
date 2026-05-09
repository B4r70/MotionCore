# Konzept: Körpermaße-Tracking in MotionCore

**Status:** Entwurf · **Erstellt:** 2026-05-09 · **Zielort:** BodyView-Tab

---

## 1. Ziel & Motivation

MotionCore soll die Erfassung und visuelle Auswertung von Körpermaßen ermöglichen. Bisher wird ausschließlich Körpergewicht in Sessions erfasst — ohne strukturierten Trend, ohne weitere Umfänge. Mit diesem Feature schließt MotionCore die Lücke zwischen *Trainingsoutput* (Sätze, Volumen, Heatmap) und *Körperveränderung* (Wachstum, Symmetrie, Verhältnisse).

Konsistente Maße zeigen, wo das Training tatsächlich Wirkung entfaltet — der primäre Use-Case ist Hypertrophie-Tracking.

---

## 2. Verortung in der App

**Entscheidung:** Eigene Card auf der `BodyView`-Hauptseite (nicht als 4. Segment im `BodyTabSwitch`), Tap führt per Push-Navigation zur dedizierten `BodyMeasurementsView`.

**Begründung:**
- Drei `BodyTabSwitch`-Segmente (Erholung / Tagesform / Trend) sind ergonomisch eine sinnvolle Obergrenze.
- Die drei bestehenden Segmente sind alle *abgeleitete CalcEngine-Outputs*, Körpermaße sind dagegen *User-Input*. Semantisch eine andere Kategorie.
- Statistik und Settings sind nicht der richtige Ort: Statistik dreht sich um Sessions, Settings um Konfiguration. Body ist der Ort, an dem es um den physischen Körper geht.

**Layout-Position:**

```
BodyView (ScrollView)
├── compositeSection
├── BodyMeasurementsCard       ← NEU (Teaser mit 3 Mini-Sparklines)
├── BodyTabSwitch
├── tabContentSection
├── avoidSection
└── emptySection
```

---

## 3. Datenmodell

### 3.1 SwiftData-Model `BodyMeasurement`

Ein Datensatz pro Mess-Zeitpunkt — alle Werte, die an *einem* Tag erfasst werden, leben in einer Zeile. Alle Werte sind `Double?` (Optional), damit Teilmessungen möglich sind.

**Felder:**

| Property | Typ | Bemerkung |
|---|---|---|
| `measurementUUID` | `UUID` (Default `UUID()`) | Stabile ID für Supabase-Sync |
| `date` | `Date` (Default `Date()`) | Mess-Zeitpunkt (Datum + Uhrzeit) |
| `notes` | `String` (Default `""`) | Optionaler Kommentar |
| `bodyWeight` | `Double?` | Körpergewicht in kg |
| `chestCircumference` | `Double?` | Brustumfang in cm |
| `waistCircumference` | `Double?` | Taillenumfang in cm (schmalste Stelle) |
| `abdomenCircumference` | `Double?` | Bauchumfang in cm (Nabelhöhe) |
| `hipCircumference` | `Double?` | Hüftumfang in cm |
| `armCircumferenceLeft` | `Double?` | Linker Arm in cm |
| `armCircumferenceRight` | `Double?` | Rechter Arm in cm |
| `thighCircumferenceLeft` | `Double?` | Linker Oberschenkel in cm |
| `thighCircumferenceRight` | `Double?` | Rechter Oberschenkel in cm |
| `syncedToSupabase` | `Bool` (Default `false`) | Sync-Flag |
| `needsSupabaseResync` | `Bool` (Default `false`) | Resync-Flag bei lokalen Änderungen |

**Konventionen:**
- Im `.singleSide`-Modus wird der Wert in `*Right` geschrieben, `*Left` bleibt `nil`.
- Computed Property `armCircumferenceAverage: Double?` liefert Mittelwert beider Seiten oder den einen vorhandenen Wert.
- Computed Property `thighCircumferenceAverage: Double?` analog.
- Alle Properties haben Defaults bzw. sind Optional → CloudKit-kompatibel.
- **Achtung CloudKit-UUID-Trap:** `measurementUUID` muss bei Migration im `SupabaseFullBackupService.deduplicateAllSyncUUIDs` ergänzt werden.

### 3.2 Einheit

Speicherung **immer in cm bzw. kg als `Double`**, eine Nachkommastelle in der UI. Kein Imperial-Support im MVP.

### 3.3 Eine Messung pro Tag

Granularität: ein `BodyMeasurement`-Eintrag pro Kalendertag. Wenn am selben Tag der Sheet erneut geöffnet wird, lädt er den existierenden Eintrag zum **Bearbeiten**. Klar erkennbar im Sheet-Header: „Du bearbeitest die Messung von heute".

Tag-Vergleich erfolgt via `Calendar.current.isDateInToday()` bzw. `Calendar.current.isDate(_:inSameDayAs:)`.

---

## 4. Settings-Defaults

Zwei neue Properties in `AppSettings` (Pattern: `@Published` + `didSet` → `UserDefaults.standard.set`):

| Property | Typ | Default | UserDefaults-Key |
|---|---|---|---|
| `bodyMeasurementArmMode` | `BodyMeasurementSideMode` | `.singleSide` | `body.armMode` |
| `bodyMeasurementThighMode` | `BodyMeasurementSideMode` | `.singleSide` | `body.thighMode` |

**Enum** (neue Datei `BodyMeasurementOptions.swift`):

```swift
enum BodyMeasurementSideMode: String, CaseIterable {
    case singleSide   // "Nur ein Wert"
    case bothSides    // "Rechts + Links getrennt"
}
```

**Settings-UI:** Neue Sektion in `MainSettingsView` namens „Körpermaße" mit eigenem `NavigationLink` auf `BodyMeasurementSettingsView`. Dort zwei `Picker` für die beiden Modi. Sektion sitzt unter „Allgemeine Einstellungen", oberhalb von „Daten-Management".

**Override pro Slide:** Der Default ist nicht hart. Jede Slide für Arm/Oberschenkel hat einen Toggle „Beide Seiten messen", mit dem für *diese* Messung umgeschaltet werden kann. Der Toggle-Initialwert kommt aus den Settings.

---

## 5. Erfassungs-UI: Karussell-Sheet

Das Sheet ist vollbild (`.fullScreenCover` oder `.sheet` mit `.large` Detent), präsentiert **eine Slide pro Wert**, horizontal swipebar mit `TabView` + `.page`-Style.

### 5.1 Slide-Struktur

Jede Slide enthält:

- **Header oben:** Datums-Picker (Default `Date()`), klein im rechten Bereich („Heute ▾")
- **Anatomie-Hint (zentral oben):** Kleines SVG/SF-Symbol, das den gemessenen Bereich highlightet
- **Großes TextField (Mitte):** `decimalPad`-Tastatur, Font ca. 64pt, eine Nachkommastelle, prominenter Cursor
- **Stepper-Buttons rechts/links:** ±0,1 cm bzw. ±0,1 kg Feinjustierung
- **Skip-Button unten:** „Heute überspringen" → Wert bleibt `nil`, Swipe weiter zur nächsten Slide
- **Page-Indicator unten:** „3 von 7"

### 5.2 Slide-Reihenfolge

1. Körpergewicht (kg)
2. Brustumfang (cm)
3. Taillenumfang (cm)
4. Bauchumfang (cm)
5. Hüftumfang (cm)
6. Armumfang (cm) — Side-Mode-Logik
7. Oberschenkelumfang (cm) — Side-Mode-Logik

### 5.3 Side-Mode-Logik auf Slide 6 und 7

- Settings-Default greift: `singleSide` zeigt **ein** Eingabefeld (befüllt `*Right`), `bothSides` zeigt zwei Felder nebeneinander (befüllt `*Left` und `*Right`).
- Ein Toggle „Beide Seiten messen" oberhalb der Felder schaltet für *diese* Messung um.
- Bei Wechsel von `bothSides` auf `singleSide` mitten in der Eingabe: bereits eingegebene Werte werden gemerged in `*Right`, `*Left` wird auf `nil` gesetzt.

### 5.4 Speichern

- **Footer-Button** „Speichern" auf jeder Slide aktiv (man muss nicht zur letzten Slide swipen)
- Speichern persistiert in SwiftData via `modelContext.insert()` bzw. — falls Edit-Modus — Update an existierender Instanz
- Anschließend: Sheet dismiss
- Supabase-Upload erfolgt **nicht sofort** automatisch — beim nächsten manuellen Full-Backup
- Optional Phase 5+: Live-Upsert nach Speichern (analog `SupabaseSessionService`)

---

## 6. Statistik-View `BodyMeasurementsView`

Aufbau (top-down, in `ScrollView` mit `glassCard`-Stil):

### 6.1 Hero-Sektion: 6-Achsen-Radar mit Vergleichsperiode

- 6 Achsen: Brust / Taille / Bauch / Hüfte / Arm-Average / Oberschenkel-Average
- Aktuelles Polygon (volle Deckung, Theme-Blau)
- Vergleichs-Polygon (halbtransparent, Theme-Sekundär) — Default: Wert vor 30 Tagen
- Timeframe-Picker oberhalb: 7 / 30 / 90 / 365 Tage
- Achsen-Normalisierung: All-Time-Max pro Achse als Skalen-Maximum (so wachsen die Werte über die Zeit nach außen)
- Bei nur einer Messung: Vergleichs-Polygon wird ausgeblendet, Hint „Mehr Daten für Vergleich nötig"

### 6.2 Mid-Sektion: Karussell der Einzel-Werte

Horizontal swipebares Karussell (`TabView` mit `.page`-Style oder `ScrollView(.horizontal)` mit Snap), eine Hero-Card pro Maß-Typ.

**Pro Card:**
- Großer aktueller Wert in der Mitte (Font ca. 56pt)
- Sparkline am unteren Rand (kompakt, Charts-Framework, nur Linie ohne Achsen)
- Delta-Pille oben rechts: `+1.2 cm · 30T` (grün positiv, rot negativ)
- Mess-Datum als kleiner Footer
- Karten-Reihenfolge: Gewicht / Brust / Taille / Bauch / Hüfte / Arm-Average / Oberschenkel-Average

### 6.3 Bottom-Sektion: Verhältnis-Cards

Drei kompakte Cards (vertikal gestackt oder als 1×3-Grid), jede mit:

- Verhältnis-Wert als zentrale Zahl
- Beschriftung darunter
- Mini-Sparkline der historischen Entwicklung des Verhältnisses

**Berechnungen:**
1. **Taille-Hüfte-Verhältnis (WHR)** = `waist / hip` — Gesundheits-Marker
2. **Brust-Taille-Verhältnis** = `chest / waist` — Proportions-/V-Taper-Ersatz
3. **Arm-zu-Brust-Verhältnis** = `armAvg / chest` — Symmetrie-Indikator

Cards werden ausgeblendet, wenn beide nötigen Werte in der jüngsten Messung fehlen.

### 6.4 Floating Action Button

`FloatingActionButton(icon: .system("plus"))` rechts unten → öffnet Karussell-Sheet zur Erfassung. Gleicher Stil wie auf der Workouts-Tab.

### 6.5 Empty-State (vor erster Messung)

Wenn `BodyMeasurement`-Count == 0:

- Großer Onboarding-Screen
- Anatomie-Icon zentral
- Headline: „Körpermaße tracken"
- Erklärtext: „Konsistente Maße zeigen dir, wo dein Training wirkt. Erfasse alle 1–2 Wochen Brust, Taille, Arme & Co. — MotionCore zeigt dir die Entwicklung."
- Großer CTA-Button: „+ Erste Messung"

Nach erster Messung wechselt die View auf das normale Statistik-Layout (Radar + Karussell + Ratios).

---

## 7. BodyMeasurementsCard auf BodyView (Teaser)

Kompakte Card auf der BodyView, oberhalb des `BodyTabSwitch`:

- **Header:** „Körpermaße" + Chevron rechts
- **Sub-Header:** „Letzte Messung vor X Tagen" (oder „Noch keine Messung" im Empty-State)
- **3 Mini-Sparklines** in einer Reihe: Brust / Taille / Körpergewicht
  - Pro Sparkline: Label (kleines `caption`), aktueller Wert + Delta-Pille, Linie
- **Tap-Bereich:** Gesamte Card → `NavigationLink` zur `BodyMeasurementsView`

Welche drei Werte angezeigt werden, ist für den MVP **fest** auf Brust / Taille / Gewicht. Konfigurierbarkeit kommt frühestens nach Phase 6.

---

## 8. CalcEngines

Drei neue, reine Struct-CalcEngines (Pattern: keine SwiftUI-Imports, keine Side-Effects, alle Logik testbar):

### 8.1 `BodyMeasurementTrendCalcEngine`

**Eingabe:** `[BodyMeasurement]` (sortiert), `Date` (Vergleichsdatum), `WritableKeyPath`/`KeyPath` auf den gewünschten Wert

**Ausgabe:**
```swift
struct BodyMeasurementTrend {
    let currentValue: Double?
    let previousValue: Double?
    let absoluteDelta: Double?      // currentValue - previousValue
    let percentageDelta: Double?    // delta / previous * 100
    let direction: TrendDirection   // .up, .down, .stable, .unknown
}
```

Wird verwendet von Karussell-Cards, Verhältnis-Cards, Teaser-Card.

### 8.2 `BodyMeasurementRadarCalcEngine`

**Eingabe:** `[BodyMeasurement]`, `SummaryTimeframe` (Wiederverwendung des bestehenden Enums)

**Ausgabe:**
```swift
struct BodyMeasurementRadarData {
    let axes: [RadarAxis]            // 6 Achsen
    let currentPolygon: [Double]     // 6 Werte (0...1 normalisiert)
    let previousPolygon: [Double]?   // 6 Werte (0...1 normalisiert), nil bei zu wenig Daten
    let allTimeMax: [Double]         // Roh-Maxima zur Skalierung
}
```

### 8.3 `BodyMeasurementRatioCalcEngine`

**Eingabe:** `[BodyMeasurement]`

**Ausgabe:**
```swift
struct BodyMeasurementRatios {
    let waistToHip: BodyMeasurementTrend?     // current ratio + previous ratio + delta
    let chestToWaist: BodyMeasurementTrend?
    let armToChest: BodyMeasurementTrend?
}
```

---

## 9. Supabase-Backup

### 9.1 Tabelle `motioncore.body_measurements`

```sql
CREATE TABLE motioncore.body_measurements (
    id UUID PRIMARY KEY,
    date TIMESTAMPTZ NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    body_weight DOUBLE PRECISION,
    chest_circumference DOUBLE PRECISION,
    waist_circumference DOUBLE PRECISION,
    abdomen_circumference DOUBLE PRECISION,
    hip_circumference DOUBLE PRECISION,
    arm_circumference_left DOUBLE PRECISION,
    arm_circumference_right DOUBLE PRECISION,
    thigh_circumference_left DOUBLE PRECISION,
    thigh_circumference_right DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_body_measurements_date ON motioncore.body_measurements(date DESC);
```

### 9.2 DTO `SupabaseBodyMeasurementDTO`

`Encodable`-Struct mit vollständigem `CodingKeys`-Enum (snake_case). **Keine** Auto-Snake-Case-Konvertierung — Swift ignoriert die bei vorhandenem `CodingKeys`-Enum.

### 9.3 Integration in `SupabaseFullBackupService`

- Neue Methode `uploadAllBodyMeasurements(context:) async throws -> Int`
- Aufruf nach Schritt 7 (Outdoor-Sessions), vor Schritt 8 (Templates) — keine FK-Abhängigkeiten
- **Einzel-Upserts** (kein Batch), wegen Optional-Felder und PGRST102-Trap (nil-Optionals → fehlende Keys → PostgREST-Error bei gemischten Batches)
- Neuer Eintrag in `BackupStats`: `bodyMeasurements: Int = 0`
- Neuer Schritt in `progress`: `step: "Körpermaße"`
- `deduplicateAllSyncUUIDs` um `BodyMeasurement.measurementUUID` erweitern

---

## 10. Out of Scope (für späteres Phasing)

Bewusst **nicht** im MVP:

- Anatomie-Heatmap (Wachstum) → Phase 4 (mit `Muscles_Heatmap.svg`-Wiederverwendung und neuem `BodyMeasurementGrowthCalcEngine`)
- HealthKit-Integration für Gewicht/Taille
- Local Notifications/Erinnerungen
- Ziel-Korridore pro Maß
- Korrelations-Engine (Maß-Wachstum × Trainingsvolumen)
- Foto-Tagebuch (von Barto explizit verworfen)
- Konfigurierbare 3 Werte in der Teaser-Card
- Imperial-Einheiten (cm/inch-Toggle)

---

## 11. Datei-Plan

Neue Dateien:

```
MotionCore/Models/Core/BodyMeasurement.swift
MotionCore/Models/Enums/BodyMeasurementOptions.swift
MotionCore/Services/Calculation/BodyMeasurementTrendCalcEngine.swift
MotionCore/Services/Calculation/BodyMeasurementRadarCalcEngine.swift
MotionCore/Services/Calculation/BodyMeasurementRatioCalcEngine.swift
MotionCore/Services/Database/Remote/Body/SupabaseBodyMeasurementDTO.swift
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsCard.swift              (Teaser)
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsView.swift              (Vollansicht)
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsRadarCard.swift
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsValueCarousel.swift
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsRatioCard.swift
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementsEmptyState.swift
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementEntrySheet.swift          (Karussell)
MotionCore/Views/Body/BodyMeasurements/BodyMeasurementEntrySlide.swift          (Slide-Komponente)
MotionCore/Views/Settings/View/BodyMeasurementSettingsView.swift
```

Erweiterte Dateien:

```
MotionCore/Models/Core/AppSettings.swift                                       (zwei neue Properties)
MotionCore/Views/Body/BodyView.swift                                           (BodyMeasurementsCard einbinden)
MotionCore/Views/Settings/View/MainSettingsView.swift                          (neuer NavigationLink)
MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift    (Upload-Methode + dedup)
```

Geschätzter Code-Umfang: ~1500 LoC verteilt auf ~14 neue Dateien (alle deutlich unter 400-LoC-Ziel).

---

## 12. Build- und Test-Reihenfolge

Siehe separates Instruction-Dokument.
