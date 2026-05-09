# Claude Code Instruction: Körpermaße-Feature

**Bezug:** `01_Konzept_Koerpermasse.md` · **Vorgehen:** 6 Phasen mit STOPP-Gates · **Sprache UI:** Deutsch · **Sprache Code/Kommentare:** Deutsche Kommentare, englische Bezeichner

---

## Globale Regeln (gelten in allen Phasen)

- **Datei-Header** wie in MotionCore üblich (`#  MotionCore` ASCII-Box mit Abschnitt, Datei, Autor, Erstellt am, Beschreibung)
- **Datei-Größe:** Ziel 400 LoC, Warnung 600, Hard-Stop 800 → splitten
- **CalcEngines:** pure Structs, `Hashable` wo sinnvoll, **keine** SwiftUI-Imports, **keine** Side-Effects
- **SwiftData-Models:** alle Properties mit Default-Werten oder `Optional` → CloudKit-kompatibel
- **CloudKit-UUID-Trap:** neue UUID-Properties müssen in `SupabaseFullBackupService.deduplicateAllSyncUUIDs` ergänzt werden, sobald die Migration einmal gelaufen ist
- **Supabase-DTOs:** `Encodable`, vollständiges `CodingKeys`-Enum (snake_case manuell, **niemals** auf `convertToSnakeCase` verlassen)
- **Glassmorphism-Stil:** `.glassCard()`-Modifier wie im Rest der App, Theme-Tokens (`MCColor.*`) verwenden
- **STOPP-Gate:** Nach jeder Phase Build erfolgreich + visuelle Verifikation durch Barto + explizites „Go" für die nächste Phase. **Keine** Phase startet ohne Bestätigung.
- **`project_knowledge_search`** ist die autoritative Quelle für vorhandene Swift-Files. Niemals via `ls` oder Bash auf Existenz prüfen.
- **`ExerciseRating`-System** und **`PlanUpdateCalcEngine`** dürfen **nicht** angefasst werden.

---

## Phase 1 — Datenmodell, Settings & Skelett-Navigation

**Ziel:** Datenfundament, Settings-Defaults und navigierbare (leere) `BodyMeasurementsView`.

### Schritte

1. **Enum-Datei `BodyMeasurementOptions.swift`** anlegen unter `MotionCore/Models/Enums/`
   - `enum BodyMeasurementSideMode: String, CaseIterable, Identifiable` mit `.singleSide`, `.bothSides`
   - `var label: String` für UI-Anzeige („Nur ein Wert" / „Rechts + Links getrennt")

2. **SwiftData-Model `BodyMeasurement.swift`** anlegen unter `MotionCore/Models/Core/`
   - `@Model final class BodyMeasurement` gemäß Konzept §3.1
   - Alle Properties mit Default-Werten (UUID, Date, String) oder `Optional` (alle Doubles)
   - `var measurementUUID: UUID = UUID()`
   - Computed Properties:
     - `var armCircumferenceAverage: Double?` — Mittelwert oder einzelner Wert oder nil
     - `var thighCircumferenceAverage: Double?` — analog
   - `init(date: Date = Date())` ohne weitere Argumente

3. **`AppSettings.swift` erweitern**
   - Zwei neue `@Published`-Properties mit `didSet` → `UserDefaults`:
     - `bodyMeasurementArmMode: BodyMeasurementSideMode` (Key: `body.armMode`, Default `.singleSide`)
     - `bodyMeasurementThighMode: BodyMeasurementSideMode` (Key: `body.thighMode`, Default `.singleSide`)
   - In `init()` aus `UserDefaults` laden mit Fallback auf `.singleSide`

4. **`BodyMeasurementSettingsView.swift`** anlegen unter `MotionCore/Views/Settings/View/`
   - `Form` mit zwei `Picker`-Sektionen für Arm und Oberschenkel
   - `@EnvironmentObject var appSettings: AppSettings`
   - `.navigationTitle("Körpermaße")`
   - Footer-Text pro Section, der erklärt, dass der Default pro Messung umschaltbar ist

5. **`MainSettingsView.swift` erweitern**
   - Neuer `NavigationLink` in der „Allgemeine Einstellungen"-Section: „Körpermaße" mit SF-Symbol `ruler` → `BodyMeasurementSettingsView()`
   - Position: nach „Studio einrichten", vor „Displayeinstellungen"

6. **Skelett `BodyMeasurementsView.swift`** anlegen unter `MotionCore/Views/Body/BodyMeasurements/`
   - `ZStack` mit `AnimatedBackground`
   - Platzhalter-Text „Körpermaße" zentral, später ersetzt
   - `.navigationTitle("Körpermaße")`, `.navigationBarTitleDisplayMode(.inline)`
   - `@Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]`

7. **`BodyMeasurementsCard.swift`** anlegen (Skelett) unter `MotionCore/Views/Body/BodyMeasurements/`
   - Einfache `glassCard`-Card mit Header „Körpermaße", Sub-Header „Tippe, um zu öffnen", Chevron rechts
   - Eingabe: `let onTap: () -> Void`
   - Tap-Geste → `onTap()`

8. **`BodyView.swift` erweitern**
   - `@State private var navigateToBodyMeasurements = false` (oder `NavigationLink` direkt)
   - `BodyMeasurementsCard` einbinden zwischen `compositeSection` und `BodyTabSwitch`
   - `NavigationLink(destination: BodyMeasurementsView())` korrekt verkabeln

9. **SwiftData-Schema-Migration:** `BodyMeasurement` zur ModelContainer-Schema-Liste hinzufügen, falls explizit dort gelistet (sonst SwiftData-Auto-Migration nutzen, Test im Build).

### Akzeptanzkriterien Phase 1

- ✅ App buildet und startet ohne Crash
- ✅ Settings → „Körpermaße" zeigt zwei Picker, Auswahl persistiert über App-Neustart
- ✅ BodyView zeigt neue Card oberhalb des Tab-Switches
- ✅ Tap auf Card öffnet leere `BodyMeasurementsView` mit Titel „Körpermaße"
- ✅ Manuelles Anlegen einer `BodyMeasurement`-Instanz im DEBUG-Block funktioniert (optional: Debug-Button für Testdaten)

### 🛑 STOPP-GATE PHASE 1

Vor Phase 2:
- [ ] Build erfolgreich
- [ ] Manuelle Verifikation (Settings, Navigation, leere View)
- [ ] Explizites „Go" von Barto

---

## Phase 2 — Karussell-Sheet zur Erfassung

**Ziel:** Vollständige Eingabe-UI funktionsfähig, Werte landen in SwiftData.

### Schritte

1. **`BodyMeasurementEntrySheet.swift`** anlegen
   - `struct BodyMeasurementEntrySheet: View`
   - Eingabe: `let editingMeasurement: BodyMeasurement?` (nil = neue Messung, sonst Bearbeitung)
   - Lokaler `@State` für alle 9 Werte (8 Felder + Datum) — Doubles als optional
   - Lokaler `@State var armBothSides: Bool` und `var thighBothSides: Bool`, Initialwert aus `appSettings`
   - Wenn `editingMeasurement != nil`: lokale States aus dem Model-Objekt befüllen, `armBothSides = (left != nil && right != nil)`
   - `TabView` mit `.tabViewStyle(.page(indexDisplayMode: .always))`, **7 Slides**
   - Header oben: Datums-Picker (kompakt, `.compact`-Style) + Sheet-Title („Neue Messung" oder „Messung bearbeiten")
   - Footer: „Speichern"-Button (immer aktiv), „Abbrechen"-Button
   - Speichern-Logik (siehe Schritt 4)

2. **`BodyMeasurementEntrySlide.swift`** anlegen — generische Slide-Komponente
   - Eingabe:
     - `title: String`
     - `unit: String` („cm" oder „kg")
     - `iconSystemName: String` (SF Symbol für Body-Region-Hint)
     - `value: Binding<Double?>` (für Single-Mode)
     - Optional: `secondValue: Binding<Double?>?` und `bothSides: Binding<Bool>?` (für Arm/Oberschenkel-Slide)
     - `step: Double = 0.1`
   - Layout:
     - Top: SF-Symbol groß (ca. 80pt) mit `.foregroundStyle(.tint)`
     - Mitte: TextField mit `decimalPad`-Tastatur, Font `.system(size: 64, weight: .light, design: .rounded)`, Unit als Suffix
     - Stepper-Buttons rechts/links neben TextField (zwei `Button` mit `Image(systemName: "minus.circle.fill")` und `plus.circle.fill`)
     - Wenn `bothSides == true`: zwei Felder nebeneinander mit Beschriftungen „Links" / „Rechts"
     - Toggle „Beide Seiten messen" oberhalb der Felder (nur sichtbar wenn `bothSides`-Binding existiert)
     - Skip-Button unten: „Heute überspringen" → setzt Wert(e) auf nil und triggert Programmatic-Swipe (siehe Schritt 3)

3. **Programmatic-Swipe** in `BodyMeasurementEntrySheet`
   - `@State private var currentSlide: Int = 0`
   - `TabView(selection: $currentSlide)` mit Tags 0…6
   - Skip-Button auf Slide setzt `currentSlide += 1` mit `.withAnimation`

4. **Speichern-Logik**
   - Bei `editingMeasurement == nil`:
     - Neue `BodyMeasurement`-Instanz erzeugen, alle Felder befüllen
     - `modelContext.insert(measurement)`
   - Bei `editingMeasurement != nil`:
     - Properties direkt auf dem existierenden Objekt updaten
     - `measurement.needsSupabaseResync = true`
   - Side-Mode-Logik beim Speichern:
     - `armBothSides == false`: nur `armCircumferenceRight` setzen, `armCircumferenceLeft = nil`
     - `armBothSides == true`: beide setzen
     - Analog für Thigh
   - `try? modelContext.save()`
   - Sheet dismiss

5. **Edit-Modus-Erkennung** in `BodyMeasurementsView`
   - Beim Öffnen des Sheets: prüfen, ob für `Date()` (heute) bereits eine Messung existiert
   - `let todayMeasurement = measurements.first { Calendar.current.isDateInToday($0.date) }`
   - Sheet wird mit `editingMeasurement: todayMeasurement` geöffnet

6. **Floating Action Button** in `BodyMeasurementsView`
   - `.floatingActionButton(icon: .system("plus"), color: .primary)` (gleicher Modifier wie auf Workouts-Tab)
   - Tap → `showingEntrySheet = true`
   - `.sheet(isPresented: $showingEntrySheet) { BodyMeasurementEntrySheet(editingMeasurement: todayMeasurement) }`

### Akzeptanzkriterien Phase 2

- ✅ FAB öffnet Karussell-Sheet
- ✅ Alle 7 Slides swipebar, jeweils mit korrektem Icon und Unit
- ✅ Werte tippbar via decimalPad, Stepper-Buttons funktionieren
- ✅ Skip-Button überspringt Slide
- ✅ Bei `singleSide`-Settings zeigt Arm/Thigh-Slide ein Feld, mit Toggle umschaltbar auf zwei
- ✅ Speichern persistiert in SwiftData (verifizierbar via Debug-Print oder erneutes Öffnen)
- ✅ Zweites Öffnen am selben Tag öffnet die existierende Messung im Edit-Modus

### 🛑 STOPP-GATE PHASE 2

- [ ] Build erfolgreich
- [ ] Mindestens 2 manuelle Test-Messungen erfasst (eine `singleSide`, eine `bothSides`)
- [ ] Explizites „Go"

---

## Phase 3 — Statistik-View MVP: Karussell der Einzel-Werte

**Ziel:** Visuelle Auswertung der Daten, MVP mit Karussell-Cards (kein Radar, keine Ratios — die kommen in Phase 4).

### Schritte

1. **`BodyMeasurementTrendCalcEngine.swift`** anlegen unter `MotionCore/Services/Calculation/`
   - `struct BodyMeasurementTrendCalcEngine`
   - Methode: `func trend(for measurements: [BodyMeasurement], keyPath: KeyPath<BodyMeasurement, Double?>, comparisonDays: Int = 30) -> BodyMeasurementTrend`
   - Logik:
     - Aktueller Wert = jüngster nicht-nil-Wert für `keyPath`
     - Vergleichswert = nächstgelegener nicht-nil-Wert vor `comparisonDays` Tagen (Toleranz ±5 Tage)
     - Delta absolut + prozentual
     - Direction: `.up`, `.down`, `.stable` (Schwellwert ±0,3 cm bzw. ±0,3 kg), `.unknown` wenn beide oder einer fehlt
   - Methode: `func sparklineData(for measurements: [BodyMeasurement], keyPath: KeyPath<BodyMeasurement, Double?>) -> [(Date, Double)]` — gefiltert auf nicht-nil

2. **`BodyMeasurementsValueCarousel.swift`** anlegen
   - `struct BodyMeasurementsValueCarousel: View`
   - Eingabe: `let measurements: [BodyMeasurement]`
   - Horizontales Karussell: `TabView` mit `.page(indexDisplayMode: .never)` oder `ScrollView(.horizontal)` mit Snap-Verhalten
   - Eine Hero-Card pro Maß-Typ (Reihenfolge: Gewicht, Brust, Taille, Bauch, Hüfte, Arm-Average, Oberschenkel-Average)
   - Card-Layout pro Maß:
     - Header: Maß-Name (`.headline`)
     - Aktueller Wert groß zentral (Font ca. 56pt, rounded)
     - Unit-Label klein
     - Delta-Pille oben rechts: `+1.2 cm · 30T` mit Farb-Coding (grün positiv, rot negativ, grau stable)
     - Sparkline am unteren Drittel (Charts-Framework, nur `LineMark` ohne Achsen, Höhe ~50pt)
     - Footer: „Letzte Messung: <Datum>"
   - Höhe Karussell: ca. 280pt
   - `.glassCard()`

3. **`BodyMeasurementsView` erweitern**
   - Empty-State-Branch: Wenn `measurements.isEmpty` → `BodyMeasurementsEmptyState`-View (siehe Schritt 4)
   - Sonst: `ScrollView` mit `BodyMeasurementsValueCarousel(measurements: measurements)`

4. **`BodyMeasurementsEmptyState.swift`** anlegen
   - SF-Symbol „figure" oder „ruler" zentral, groß
   - Headline „Körpermaße tracken"
   - Erklärtext (siehe Konzept §6.5)
   - Großer CTA-Button „+ Erste Messung" → öffnet Entry-Sheet

5. **`BodyMeasurementsCard` (Teaser) ausbauen**
   - 3 Mini-Sparklines in horizontaler Reihe: Brust / Taille / Gewicht
   - Pro Mini-Sparkline: Label oben (`.caption`), kleines Chart (Höhe 30pt), aktueller Wert + Delta-Pille
   - Wenn `measurements.isEmpty`: einfacher Sub-Header „Noch keine Messung — tippe auf +"
   - Wenn `measurements.isNotEmpty`: Sub-Header „Letzte Messung vor X Tagen"

### Akzeptanzkriterien Phase 3

- ✅ Karussell zeigt 7 Cards, swipebar
- ✅ Werte korrekt aus Messdaten gelesen
- ✅ Delta-Pillen zeigen sinnvolle Werte mit Farb-Coding
- ✅ Sparklines rendern (auch mit nur 1–2 Datenpunkten — dann nur Punkt/kurze Linie)
- ✅ Empty-State-Screen erscheint, wenn keine Messung existiert
- ✅ Teaser-Card auf BodyView zeigt 3 Mini-Sparklines

### 🛑 STOPP-GATE PHASE 3

- [ ] Build erfolgreich
- [ ] Mit mindestens 5 Testmessungen über verschiedene Tage manuell verifiziert
- [ ] Empty-State manuell getestet (alle Messungen löschen)
- [ ] Explizites „Go"

---

## Phase 4 — Radar-Chart und Verhältnis-Cards

**Ziel:** Vollständiges Statistik-Layout mit Radar oben, Karussell mittig, Verhältnis-Cards unten.

### Schritte

1. **`BodyMeasurementRadarCalcEngine.swift`** anlegen unter `MotionCore/Services/Calculation/`
   - `struct BodyMeasurementRadarCalcEngine`
   - Methode: `func computeRadar(measurements: [BodyMeasurement], timeframe: SummaryTimeframe) -> BodyMeasurementRadarData`
   - 6 Achsen: Brust, Taille, Bauch, Hüfte, Arm-Average, Oberschenkel-Average
   - Aktueller Wert = jüngste Messung im Timeframe
   - Vergleichswert = älteste Messung im Timeframe (oder nil, wenn nur eine Messung)
   - Normalisierung: pro Achse `value / allTimeMax` clamped auf [0, 1]
   - `allTimeMax` aus *allen* Messungen (nicht nur Timeframe), damit Wachstum nach außen geht

2. **`BodyMeasurementsRadarCard.swift`** anlegen
   - Custom SwiftUI-Drawing mit `Canvas` oder `Path`-basiertes 6-Achsen-Radar
   - Achsen-Labels außen
   - Aktuelles Polygon: gefüllt mit Theme-Blau bei 30% Opacity, Linie 70% Opacity
   - Vergleichs-Polygon: gefüllt mit Sekundärfarbe bei 15% Opacity, Linie 50% Opacity
   - Timeframe-Picker oberhalb (Segmented): 7T / 30T / 90T / 1J — Wiederverwendung von `SummaryTimeframe`
   - Bei zu wenig Daten: Hint „Mehr Daten für Vergleich nötig", nur aktuelles Polygon

3. **`BodyMeasurementRatioCalcEngine.swift`** anlegen unter `MotionCore/Services/Calculation/`
   - Methode: `func computeRatios(measurements: [BodyMeasurement]) -> BodyMeasurementRatios`
   - Drei Ratios berechnen mit Trend (current vs. vor 30 Tagen):
     - WHR = `waist / hip`
     - Brust-Taille = `chest / waist`
     - Arm-Brust = `armAverage / chest`
   - Jedes Ratio als optionaler `BodyMeasurementTrend` zurück (nil wenn Daten fehlen)

4. **`BodyMeasurementsRatioCard.swift`** anlegen
   - Eingabe: `let title: String, value: Double, delta: Double?, sparklineData: [(Date, Double)], description: String`
   - Vertical-Stack:
     - Header mit Titel + Delta-Pille
     - Großer Wert (Font ca. 36pt) zentral
     - Description-Text klein darunter
     - Mini-Sparkline am unteren Rand
   - `.glassCard()`

5. **`BodyMeasurementsView` finalisieren**
   - Reihenfolge in `ScrollView`:
     1. `BodyMeasurementsRadarCard`
     2. `BodyMeasurementsValueCarousel`
     3. Drei `BodyMeasurementsRatioCard` als VStack (oder LazyVGrid 2-spaltig auf größeren Geräten)

6. **Conditional Rendering**
   - Radar-Card nur anzeigen, wenn `measurements.count >= 1`
   - Ratio-Cards einzeln ausblenden, wenn nötige Werte fehlen

### Akzeptanzkriterien Phase 4

- ✅ Radar zeichnet korrekt mit 6 Achsen
- ✅ Vergleichs-Polygon halbtransparent über aktuellem
- ✅ Timeframe-Picker funktioniert, Polygone aktualisieren
- ✅ Drei Ratio-Cards mit korrekten Werten und Sparklines
- ✅ Cards mit fehlenden Daten werden ausgeblendet, kein Crash

### 🛑 STOPP-GATE PHASE 4

- [ ] Build erfolgreich
- [ ] Mit Testdaten über mehrere Wochen verifiziert
- [ ] Layout auf iPhone-Größe geprüft (kein Overflow, kein Spacing-Bug)
- [ ] Explizites „Go"

---

## Phase 5 — Supabase-Backup-Integration

**Ziel:** Körpermaße-Daten landen im Full-Backup auf Supabase.

### Schritte

1. **Supabase-Tabelle anlegen**
   - SQL gemäß Konzept §9.1 ausführen
   - Über `Supabase:execute_sql` MCP-Tool, Schema-Prefix `motioncore.`
   - Tabelle muss in „Exposed schemas" der Project-API-Settings erscheinen (sollte schon der Fall sein für `motioncore`)

2. **`SupabaseBodyMeasurementDTO.swift`** anlegen unter `MotionCore/Services/Database/Remote/Body/`
   - `struct SupabaseBodyMeasurementDTO: Encodable`
   - Felder gemäß Konzept §3.1, alle Doubles als `Double?`
   - Vollständiges `CodingKeys`-Enum mit snake_case (CodingKeys-Trap!)
   - `id`, `date`, `notes`, alle Maße, keine `created_at`/`updated_at` (Server-default)

3. **`SupabaseFullBackupService.swift` erweitern**
   - In `BackupStats`: neues Feld `var bodyMeasurements: Int = 0`
   - Neue private Methode `uploadAllBodyMeasurements(context: ModelContext) async throws -> Int`:
     - Fetch aller `BodyMeasurement`-Instanzen
     - Für jede: DTO erzeugen, `client.upsert(endpoint: "body_measurements", body: dto, schema: "motioncore")`
     - Einzel-Upserts (kein Batch wegen Optional-Feldern → PGRST102)
     - `progress`-Update pro Iteration
     - `syncedToSupabase = true`, `needsSupabaseResync = false` setzen
   - Aufruf in `runFullBackup` nach Schritt 7 (Outdoor-Sessions), vor Schritt 8 (Templates)
   - Eintrag in finalem `BackupStats`-Initializer und Print-Output

4. **`deduplicateAllSyncUUIDs` erweitern**
   - Block für `BodyMeasurement.measurementUUID` analog zu anderen Models hinzufügen
   - Bei Duplikat: `measurementUUID = UUID()`, `syncedToSupabase = false`

5. **`SupabaseFullBackupSection`-View** (Settings) prüfen
   - Falls Stats-Anzeige existiert: `bodyMeasurements`-Count mit aufnehmen

### Akzeptanzkriterien Phase 5

- ✅ Tabelle `motioncore.body_measurements` existiert in Supabase
- ✅ Manueller Full-Backup läuft fehlerfrei durch
- ✅ Daten in Supabase verifizierbar (über MCP-Tool oder Studio)
- ✅ Wiederholter Backup wirft keine Fehler (Idempotenz)
- ✅ `BackupStats` zeigt korrekte Anzahl

### 🛑 STOPP-GATE PHASE 5

- [ ] SQL-Tabelle erstellt
- [ ] Build erfolgreich
- [ ] Daten in Supabase sichtbar nach Test-Backup
- [ ] Explizites „Go"

---

## Phase 6 — Polish & Edge-Cases (optional, nach Bedarf)

**Ziel:** Feinschliff, kann auch übersprungen oder iterativ erweitert werden.

### Mögliche Schritte

1. **Animationen**
   - Spring-Animation beim Sheet-Open
   - Smooth-Transition zwischen Slides
   - Polygon-Morph beim Timeframe-Wechsel im Radar

2. **Haptic Feedback**
   - `UIImpactFeedbackGenerator(.light)` bei Stepper-Tap
   - `UINotificationFeedbackGenerator(.success)` bei Speichern

3. **Voice-Over / Accessibility**
   - `.accessibilityLabel` für alle interaktiven Elemente
   - Großer Text-Modus testen

4. **Detail-Sheet pro Maß**
   - Tap auf Karussell-Card öffnet Detail-Sheet mit voller History (Liste aller Messungen)
   - Edit/Delete einer historischen Messung

5. **Notes-Feld im Sheet**
   - Optionale Slide nach Slide 7: „Notizen zu dieser Messung"

6. **Iconography**
   - Custom-Body-SVG-Icons statt SF-Symbols für besseren visuellen Hinweis pro Maß

### 🛑 Phase 6 ist optional, jeder einzelne Schritt kann unabhängig durchgeführt werden.

---

## Workflow-Zusammenfassung

```
Phase 1 ─→ Build ─→ STOPP ─→ Go ─→ Phase 2 ─→ Build ─→ STOPP ─→ Go ─→ Phase 3 ─→ ...
```

**Agenten-Zuordnung (Vorschlag):**
- `motioncore-planner` (opus): Konzept-Diskussion abgeschlossen, dieses Dokument
- `motioncore-developer` (sonnet): Implementierung pro Phase
- `motioncore-quality-gate` (sonnet): Code-Review nach jeder Phase
- `motioncore-fitness-expert` (sonnet): nicht relevant für dieses Feature

**Verifikations-Reihenfolge pro Phase:**
1. Code-Review durch `motioncore-quality-gate`
2. Build via Xcode auf Mac Mini M4
3. Manuelle UI-Verifikation durch Barto
4. Erst nach „Go": nächste Phase

---

## Offene Punkte / Spätere Erweiterungen

Aus dem Konzept §10 zur Erinnerung:
- Anatomie-Heatmap (Wachstum) — separates Mini-Projekt nach Abschluss von Phase 5
- HealthKit-Integration für `bodyMass` und `waistCircumference`
- Local Notifications für Mess-Erinnerungen
- Ziel-Korridore pro Maß
- `BodyMeasurementCorrelationCalcEngine` (Korrelation Maß × Trainingsvolumen)

Diese werden bewusst nicht in dieser Instruction abgehandelt, um den Scope klein zu halten.
