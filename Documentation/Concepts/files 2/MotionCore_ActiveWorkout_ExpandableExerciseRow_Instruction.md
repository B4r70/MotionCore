# Claude Code Instruction — Ausklappbare Übungs-Rows in `ExercisesOverviewCard`

**Bezugsdokument:** `ActiveWorkout_ExpandableExerciseRow_Concept.md`
**Zieldatei:** `ExercisesOverviewCard.swift` (aktuell 448 Zeilen)
**Sekundäre Datei:** `ActiveWorkoutView.swift` (nur 1 Parameter-Übergabe)
**Datum:** April 2026

---

## ⚠️ Wichtige Regeln für die gesamte Umsetzung

1. **Nach jedem Schritt STOPP** und auf "Go" warten. Nicht selbständig weitermachen.
2. **Build-Check nach jedem Schritt**: Die App muss buildbar bleiben.
3. **Keine Refactorings nebenbei**: Nur das umsetzen, was im jeweiligen Schritt steht.
4. **Bestehende Drag-&-Drop-Logik nicht anfassen** — sie bleibt unverändert.
5. **Bestehende Superset-Linien nicht anfassen** — sie bleiben unverändert.
6. **Code-Stil:** MotionCore Swift Standards (siehe `swift-standards` Skill).
7. **Datei-Größe im Auge behalten**: Wird `ExercisesOverviewCard.swift` über 600 Zeilen → STOPP und Aufteilung besprechen.

---

## Schritt 1 — Parameter `selectedExerciseKey` durchreichen

### Aufgabe
In `ExercisesOverviewCard` einen neuen Parameter `selectedExerciseKey: String?` hinzufügen und in `ActiveWorkoutView` an der Aufrufstelle den vorhandenen `@State private var selectedExerciseKey` übergeben.

### Konkrete Änderungen
- **`ExercisesOverviewCard.swift`**: Neuen Parameter direkt nach `currentExerciseIndex` einfügen:
  ```swift
  let selectedExerciseKey: String?
  ```
- **`ActiveWorkoutView.swift`**: An der Aufrufstelle von `ExercisesOverviewCard(...)` den Parameter `selectedExerciseKey: selectedExerciseKey` ergänzen.

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Kein visuelles Verhalten ändert sich (Parameter wird noch nicht verwendet).

### 🛑 STOPP — Build-Check abwarten und auf "Go" warten

---

## Schritt 2 — `expandedExerciseKey`-State einführen

### Aufgabe
In `ExercisesOverviewCard` einen neuen `@State` für die aktuell aufgeklappte Übung einführen sowie die Reaktivität auf `selectedExerciseKey` und `isSortMode`.

### Konkrete Änderungen
In `ExercisesOverviewCard`:

1. Neuen State direkt unter den vorhandenen `@State`-Properties einfügen:
   ```swift
   @State private var expandedExerciseKey: String? = nil
   ```

2. Im `body` der `ExercisesOverviewCard` (am `VStack` der äußersten Ebene) folgende Modifier ergänzen:
   ```swift
   .onAppear {
       if expandedExerciseKey == nil {
           expandedExerciseKey = selectedExerciseKey
       }
   }
   .onChange(of: selectedExerciseKey) { _, newValue in
       withAnimation(.easeInOut(duration: 0.25)) {
           expandedExerciseKey = newValue
       }
   }
   .onChange(of: isSortMode) { _, newValue in
       if newValue {
           withAnimation(.easeInOut(duration: 0.25)) {
               expandedExerciseKey = nil
           }
       }
   }
   ```

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Kein visuelles Verhalten ändert sich (State wird noch nicht ausgewertet).

### 🛑 STOPP — Build-Check abwarten und auf "Go" warten

---

## Schritt 3 — `ExerciseOverviewRow` um Expand-Properties erweitern

### Aufgabe
Die private Subview `ExerciseOverviewRow` erhält zwei neue Properties (`isExpanded`, `onToggleExpand`) und einen Tap-Handler auf der äußeren Row.

### Konkrete Änderungen

1. In `ExerciseOverviewRow` zwei neue Properties ergänzen:
   ```swift
   let isExpanded: Bool
   let onToggleExpand: () -> Void
   ```

2. An der bestehenden Row-Background-`RoundedRectangle` (außerhalb der `HStack`, am Ende des Body-Aufbaus) eine Tap-Geste anhängen:
   ```swift
   .onTapGesture {
       guard !isSortMode else { return }
       onToggleExpand()
   }
   ```

3. Im Aufruf von `ExerciseOverviewRow` in `ExercisesOverviewCard` die neuen Parameter übergeben — sowohl in der Hintergrund-Row als auch in der Drag-Floating-Row (falls vorhanden):
   ```swift
   isExpanded: expandedExerciseKey == sets.first?.groupKey,
   onToggleExpand: {
       guard let key = sets.first?.groupKey else { return }
       withAnimation(.easeInOut(duration: 0.25)) {
           expandedExerciseKey = (expandedExerciseKey == key) ? nil : key
       }
   }
   ```

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Tap auf eine Row hat noch keinen sichtbaren Effekt (nur State ändert sich).

### 🛑 STOPP — Build-Check abwarten und auf "Go" warten

---

## Schritt 4 — Chevron-Indikator in `topLine` einbauen

### Aufgabe
Rechts neben dem `0/3`-Counter (bzw. dem `checkmark.circle.fill`-Icon) einen Chevron einfügen, der den Aufklapp-Status visualisiert.

### Konkrete Änderungen
In `ExerciseOverviewRow` die Subview `topLine` erweitern. Direkt nach dem `HStack` mit Crown/Counter einen weiteren Block:
```swift
Image(systemName: "chevron.down")
    .font(.caption)
    .foregroundStyle(.secondary)
    .rotationEffect(.degrees(isExpanded ? 180 : 0))
    .animation(.easeInOut(duration: 0.2), value: isExpanded)
    .opacity(isSortMode ? 0 : 1)
    .padding(.leading, 4)
```

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Beim Tap auf eine Row rotiert der Chevron sichtbar.
- Im Sortiermodus ist der Chevron unsichtbar.

### 🛑 STOPP — Build-Check abwarten und auf "Go" warten

---

## Schritt 5 — `ExerciseOverviewExpandedDetail`-Subview implementieren

### Aufgabe
Eine neue private Subview erstellen, die die Liste der Sätze rendert. Diese Subview wird in `ExerciseOverviewRow` unterhalb der `dotsLine` bedingt eingeblendet.

### Konkrete Änderungen

1. In `ExercisesOverviewCard.swift` (am Ende der Datei, vor dem letzten `}` der Datei oder vor `// MARK: - Safe Array Access`) folgende neue Subview anlegen:

   ```swift
   // MARK: - Exercise Overview Expanded Detail

   private struct ExerciseOverviewExpandedDetail: View {
       let sets: [ExerciseSet]

       var body: some View {
           VStack(spacing: 0) {
               Divider()
                   .background(Color.primary.opacity(0.05))
                   .padding(.bottom, 8)

               if sets.isEmpty {
                   Text("Keine Sätze konfiguriert")
                       .font(.caption)
                       .foregroundStyle(.secondary)
                       .frame(maxWidth: .infinity, alignment: .center)
                       .padding(.vertical, 8)
               } else {
                   VStack(spacing: 6) {
                       ForEach(sets, id: \.persistentModelID) { set in
                           setDetailRow(set: set)
                       }
                   }
               }
           }
       }

       private func setDetailRow(set: ExerciseSet) -> some View {
           HStack {
               Text("Satz \(set.setNumber)")
                   .font(.caption)
                   .foregroundStyle(.secondary)

               Spacer()

               Text(formatSetValue(set))
                   .font(.caption)
                   .foregroundStyle(set.isCompleted ? .primary : .secondary)
                   .opacity(set.isCompleted ? 1.0 : 0.5)

               Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                   .font(.caption)
                   .foregroundStyle(set.isCompleted ? Color.green : Color.secondary.opacity(0.5))
                   .padding(.leading, 4)
           }
       }

       private func formatSetValue(_ set: ExerciseSet) -> String {
           let weightStr: String
           if set.weight == set.weight.rounded() {
               weightStr = String(format: "%.0f", set.weight)
           } else {
               weightStr = String(format: "%.1f", set.weight)
           }
           return "\(weightStr) kg × \(set.reps) Wdh."
       }
   }
   ```

2. In `ExerciseOverviewRow` innerhalb der `VStack(spacing: 8) { topLine; dotsLine }` als drittes Element bedingt einbauen:
   ```swift
   if isExpanded {
       ExerciseOverviewExpandedDetail(sets: sets)
           .transition(.opacity.combined(with: .move(edge: .top)))
   }
   ```

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Tap auf eine Row klappt die Detail-Sektion mit den Satz-Werten auf.
- Tap auf eine andere Row schließt die alte und öffnet die neue (Accordion-Verhalten).
- Beim Öffnen der `ActiveWorkoutView` ist die aktuell aktive Übung automatisch aufgeklappt.

### 🛑 STOPP — Build-Check **+ visueller Test im Simulator** abwarten und auf "Go" warten

---

## Schritt 6 — Play-Icon für Auswahl als aktive Übung einbauen

### Aufgabe
Ein kleines Play-Icon rechts in der `topLine` einfügen, das **nur bei nicht-aktiven Übungen** sichtbar ist und beim Tap die Übung als aktive Übung setzt (`onSelectExercise`).

### Konkrete Änderungen

1. In `ExerciseOverviewRow` muss `onSelectExercise` als neue Property verfügbar gemacht werden:
   ```swift
   let onSelectAsActive: () -> Void
   ```

2. In der `topLine`, **vor** dem `chevron.down`-Image, ein Play-Icon einbauen — aber nur wenn `!isCurrentExercise && !isSortMode`:
   ```swift
   if !isCurrentExercise && !isSortMode {
       Button {
           onSelectAsActive()
       } label: {
           Image(systemName: "play.circle.fill")
               .font(.title3)
               .foregroundStyle(.blue)
       }
       .buttonStyle(.plain)
       .padding(.leading, 4)
   }
   ```

3. Im Aufruf von `ExerciseOverviewRow` in `ExercisesOverviewCard` (sowohl in der Hintergrund-Row als auch in der Drag-Floating-Row) `onSelectAsActive` mit dem bestehenden `onSelectExercise`-Callback verbinden:
   ```swift
   onSelectAsActive: {
       guard let key = sets.first?.groupKey else { return }
       onSelectExercise(key)
   }
   ```

### Akzeptanzkriterium
- App buildet ohne Fehler.
- Bei nicht-aktiven Übungen ist das Play-Icon sichtbar.
- Tap auf das Play-Icon macht die Übung zur aktiven Übung (oben in der View sichtbar).
- Tap auf das Play-Icon löst **nicht** das Aufklappen der Row aus (`buttonStyle(.plain)` muss reichen — falls doch propagiert, `simultaneousGesture` oder explizites Stop nötig).
- Bei der aktiven Übung ist das Play-Icon ausgeblendet.

### 🛑 STOPP — Build-Check **+ funktionaler Test** abwarten und auf "Go" warten

---

## Schritt 7 — Edge-Cases prüfen und Feinschliff

### Aufgabe
Manuelle Prüfung aller Edge-Cases laut Konzept §9. Falls Anpassungen nötig sind, diese gezielt umsetzen.

### Manuelle Test-Checkliste
- [ ] Sortiermodus aktivieren während eine Row offen ist → Row klappt zu, Sortiermodus startet sauber
- [ ] Im Sortiermodus auf eine Row tippen → kein Aufklappen
- [ ] Sortiermodus verlassen → Rows bleiben zugeklappt, manuell wieder aufklappbar
- [ ] Eine andere Übung über das Play-Icon zur aktiven machen → automatisches Umklappen funktioniert
- [ ] Übung mit nur 1 Satz aufklappen → Detail zeigt korrekt
- [ ] Alle Sätze einer Übung abschließen, dann aufklappen → alle Sätze ✓
- [ ] Übung löschen während sie offen ist → keine Crashes, keine optischen Glitches
- [ ] Superset-Übungen aufklappen → blaue Verbindungslinie links bleibt korrekt sichtbar
- [ ] Während aktiver Live-Activity bleibt das Verhalten konsistent

### Datei-Größen-Check
```bash
wc -l /pfad/zu/ExercisesOverviewCard.swift
```
Falls > 600 Zeilen → STOPP und Aufteilung in eigene Datei besprechen.

### Akzeptanzkriterium
- Alle Punkte der Test-Checkliste grün.
- Datei `ExercisesOverviewCard.swift` unter 600 Zeilen.
- Keine `print`-Statements oder Debug-Code zurückgelassen.
- App buildet sauber, keine Compile-Warnungen aus den geänderten Dateien.

### 🛑 STOPP — Final-Review mit Barto

---

## Anhang — Format-Referenzen

### Bestehender Stil aus `StrengthDetailView`
```swift
// Satz-Detail-Zeile:
HStack {
    Text("Satz \(set.setNumber)")
        .font(.caption)
        .foregroundStyle(set.setKind == .warmup ? .orange : .secondary)
    // ...
}
```
→ Wir bleiben bewusst minimaler, ohne Warmup-Farb-Marker (siehe Konzept §4.3).

### Bestehender Stil aus `ExercisesOverviewCard.ExerciseOverviewRow`
- Background: `RoundedRectangle(cornerRadius: 12)` mit dynamischer Farbe
- Padding: `12` rundherum
- Spacing: `8` zwischen TopLine und DotsLine
- Animation: `.easeInOut(duration: 0.15)` für `isPressed`

→ Diese Werte konsistent halten.

---

## Erwartete Endgröße

- `ExercisesOverviewCard.swift`: 448 Zeilen → ca. 530 Zeilen (unter 600-Hard-Warning ✅)
- `ActiveWorkoutView.swift`: +1 Zeile (Parameter-Übergabe)

Falls nach Schritt 7 die Datei doch näher an 600 Zeilen rückt, separater Refactoring-Step zur Auslagerung von `ExerciseOverviewExpandedDetail` in eine eigene Datei `ExerciseOverviewExpandedDetail.swift` empfohlen.
