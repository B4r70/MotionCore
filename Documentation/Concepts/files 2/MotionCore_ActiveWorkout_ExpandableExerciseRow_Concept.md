# MotionCore — Ausklappbare Übungs-Rows in `ExercisesOverviewCard`

**Status:** Konzept zur Umsetzung
**Datum:** April 2026
**Betroffene View:** `ActiveWorkoutView` → `ExercisesOverviewCard`
**Datei-Schwerpunkt:** `ExercisesOverviewCard.swift` (aktuell 448 Zeilen)

---

## 1. Ziel

In der `ExercisesOverviewCard` der `ActiveWorkoutView` soll jede Übungs-Row während der laufenden Session per Tap aufklappbar sein. Aufgeklappt zeigt sie pro Satz die geplanten und tatsächlichen Werte (Gewicht × Wiederholungen). Es ist immer **maximal eine Row gleichzeitig aufgeklappt** (Accordion-Verhalten).

Dadurch kann der Nutzer während des Trainings ohne Wechsel auf einen Detail-Screen sehen, **was er bisher in der aktuellen Session bei einer Übung tatsächlich erfasst hat** und **was noch ansteht**.

---

## 2. Scope

### In Scope
- Aufklappbarer Detail-Bereich pro Übungs-Row
- Accordion-Verhalten (nur eine Row gleichzeitig offen)
- Auto-Expand der aktuell aktiven Übung
- Auto-Collapse aller Rows im Sortiermodus
- Chevron-Indikator zum Anzeigen des Aufklappstatus
- Verhalten bei Auswahl-Wechsel (`selectedExerciseKey`)

### Out of Scope
- Keine Anzeige von Sätzen aus früheren Sessions (nur aktuelle Session)
- Keine zusätzliche Volumen-Summenzeile (kommt bereits durch das `0/3`-Feedback)
- Keine RPE/RIR-Anzeige im Detail (nicht relevant während des Trainings)
- Keine Bearbeitungsmöglichkeit der Sätze aus dem Aufklapp-Bereich (Bearbeitung läuft weiterhin oben über `ActiveSetCard`)

---

## 3. UX-Verhalten

### 3.1 Auf-/Zuklappen
- **Tap auf eine Row** → diese Row klappt auf, eine ggf. vorher offene Row klappt zu
- **Tap auf eine bereits offene Row** → diese Row klappt zu
- Die Row bleibt **klickbar als Ganzes**; das Tap-Ziel umfasst die gesamte Row-Fläche

### 3.2 Verhalten bei der aktuell aktiven Übung
- Beim Erscheinen der View ist die `isCurrentExercise`-Row **standardmäßig automatisch aufgeklappt**
- Wenn sich `selectedExerciseKey` (extern in `ActiveWorkoutView`) ändert:
  - Die alte aktive Row klappt automatisch zu
  - Die neue aktive Row klappt automatisch auf
- Der Nutzer kann diese aktive Row jederzeit manuell zuklappen und eine andere aufklappen — beim nächsten Wechsel der aktiven Übung wird das Verhalten dann wieder automatisch angewandt

### 3.3 Verhalten im Sortiermodus
- Beim Aktivieren des Sortiermodus klappen **alle Rows automatisch zu**
- Während des Sortiermodus ist Aufklappen **deaktiviert** (Tap = kein Effekt auf Expand-State)
- Drag & Drop bleibt einziger Interaktions-Modus

### 3.4 Animation
- `.transition(.opacity.combined(with: .move(edge: .top)))` für den Detail-Bereich
- `withAnimation(.easeInOut(duration: 0.25))` beim Wechsel des Expand-States
- Chevron rotiert um 180° (von `chevron.down` → `chevron.up`)

---

## 4. UI-Aufbau

### 4.1 Aktuelle Row-Struktur (Bestand)
```
┌─────────────────────────────────────────┐
│ [Index]. Übungsname        [PR] 0/3 │
│  ● ● ●                                  │
└─────────────────────────────────────────┘
```

### 4.2 Geplante Struktur (Neu)

**Eingeklappt:**
```
┌─────────────────────────────────────────┐
│ [Index]. Übungsname    [PR] 0/3  ⌄    │
│  ● ● ●                                  │
└─────────────────────────────────────────┘
```

**Aufgeklappt:**
```
┌─────────────────────────────────────────┐
│ [Index]. Übungsname    [PR] 1/3  ⌃    │
│  ● ● ●                                  │
│ ─────────────────────────────────────── │
│ Satz 1   36.0 kg × 10 Wdh.       ✓    │
│ Satz 2   36.0 kg × 10 Wdh.       –    │
│ Satz 3   36.0 kg × 10 Wdh.       –    │
└─────────────────────────────────────────┘
```

### 4.3 Detail-Sektion: Inhalt pro Satz

Jeder Satz wird als HStack gerendert:

| Element | Anzeige |
|---|---|
| **Satz-Label** | `"Satz N"` (links, `Color.secondary`) |
| **Wert** | `"<weight> kg × <reps> Wdh."` (rechts, formatiert) |
| **Status** | Trailing: ✓ (grün) wenn `isCompleted`, sonst `–` (`Color.secondary`) |

- **Abgeschlossene Sätze** zeigen den **tatsächlich erfassten** `weight` × `reps`
- **Offene Sätze** zeigen das **geplante Gewicht/Wdh.** mit reduzierter Opacity (`.opacity(0.5)`)
- **Warmup-Sätze** werden **nicht visuell hervorgehoben** im Detail (bewusst minimal — die `dotsLine` mit dem orangenen Ring zeigt das bereits oben)

### 4.4 Styling

- Detail-Sektion sitzt **innerhalb derselben Background-`RoundedRectangle`** der Row, kein eigener `glassCard()`
- Trennlinie: `Divider().background(Color.primary.opacity(0.05))` zwischen Dots-Line und Satz-Liste
- Pro-Satz-Hintergrund: kein eigener Hintergrund (nur die Row-Card als Container)
- Padding: `.padding(.horizontal, 12)`, `.padding(.bottom, 12)` für die Detail-Sektion

### 4.5 Chevron-Indikator

- `Image(systemName: "chevron.down")`
- Position: rechts neben dem `0/3`-Counter (bzw. `checkmark.circle.fill`)
- `.font(.caption)`, `.foregroundStyle(.secondary)`
- Rotation: `.rotationEffect(.degrees(isExpanded ? 180 : 0))` mit `.animation(.easeInOut(duration: 0.2), value: isExpanded)`
- Im Sortiermodus ausgeblendet (`.opacity(isSortMode ? 0 : 1)`)

---

## 5. Daten-Anforderungen

### 5.1 Bereits vorhanden (kein neues Datenmodell nötig)
- `groupedSets: [[ExerciseSet]]` — wird bereits an `ExercisesOverviewCard` übergeben
- Pro `ExerciseSet`: `setNumber`, `weight`, `reps`, `isCompleted`, `setKind`

### 5.2 Datenfluss
Die Detail-Sektion nutzt **ausschließlich das bereits existierende `sets`-Array** der jeweiligen Row. Es werden **keine zusätzlichen `@Query`s, `CalcEngine`s oder Services** benötigt.

---

## 6. State-Verwaltung

### 6.1 Neuer State in `ExercisesOverviewCard`
```swift
@State private var expandedExerciseKey: String? = nil
```
- `nil` = keine Row aufgeklappt
- `String` = `groupKey` der aktuell aufgeklappten Übung

### 6.2 Neuer Parameter in `ExercisesOverviewCard`
```swift
let selectedExerciseKey: String?
```
- Wird von `ActiveWorkoutView` durchgereicht (existiert dort bereits als `@State private var selectedExerciseKey: String?`)
- Steuert das Auto-Expand-Verhalten

### 6.3 Reaktive Updates
- `.onAppear` → falls `expandedExerciseKey == nil`: setze auf `selectedExerciseKey`
- `.onChange(of: selectedExerciseKey)` → setze `expandedExerciseKey = newValue`
- `.onChange(of: isSortMode)` → falls `isSortMode == true`: setze `expandedExerciseKey = nil`

### 6.4 Erweiterung von `ExerciseOverviewRow`
Neue Properties:
```swift
let isExpanded: Bool
let isSortMode: Bool  // bereits vorhanden
let onToggleExpand: () -> Void
```

---

## 7. Architektur

### 7.1 Datei-Aufteilung
- Neue Subview `ExerciseOverviewExpandedDetail` als **`private struct` innerhalb `ExercisesOverviewCard.swift`**
- Datei wächst dadurch von 448 auf voraussichtlich ca. 530 Zeilen → **unter dem 600-Zeilen-Hard-Warning**
- Sollte das Wachstum nach Implementierung über 600 Zeilen führen, wird `ExerciseOverviewExpandedDetail` in eine eigene Datei `ExerciseOverviewExpandedDetail.swift` ausgelagert (mit `internal` Sichtbarkeit)

### 7.2 Verantwortlichkeiten
| Komponente | Verantwortung |
|---|---|
| `ActiveWorkoutView` | Hält `selectedExerciseKey`, gibt ihn an `ExercisesOverviewCard` weiter |
| `ExercisesOverviewCard` | Hält `expandedExerciseKey`-State, orchestriert Accordion-Logik |
| `ExerciseOverviewRow` | Rendert Header (TopLine + DotsLine) und enthält die Detail-Sektion bedingt |
| `ExerciseOverviewExpandedDetail` | Rendert die Liste der Sätze mit Werten und Status |

### 7.3 Bestehende Aktionen bleiben unverändert
- `onSelectExercise(groupKey)` bleibt für Auswahl als aktive Übung
- `onDeleteExercise(groupKey)` bleibt unverändert
- `onReorderExercise(from:to:)` bleibt unverändert
- Drag-&-Drop-Logik bleibt unverändert

**Wichtig:** Tap-Verhalten der Row wird so verschoben, dass der primäre Tap das **Aufklappen** auslöst (nicht das Auswählen als aktive Übung). Die Auswahl als aktive Übung erfolgt über einen anderen Trigger — siehe Punkt 8.

---

## 8. Tap-Routing

### 8.1 Aktuelles Verhalten (vor Umsetzung)
- Tap auf Row → `onSelectExercise(groupKey)` (Übung wird aktive Übung)
- Long-Press oder `onDeleteExercise` → über bestehenden Mechanismus

### 8.2 Neues Verhalten

| Geste | Effekt |
|---|---|
| **Tap auf Row** | Klappt die Row auf bzw. zu (Accordion-Verhalten) |
| **Tap auf "Play"-Icon** rechts (neu, klein) | `onSelectExercise(groupKey)` — setzt aktive Übung |
| **Long-Press** | unverändert (Sortiermodus-Trigger, falls bereits implementiert) |

### 8.3 Play-Icon
- Neues kleines Icon `Image(systemName: "play.circle.fill")`
- Position: rechts in der `topLine`, links neben dem Chevron
- `.font(.title3)`, `.foregroundStyle(.blue)`
- Wird **nur eingeblendet, wenn die Übung NICHT die aktuell aktive ist**
- Tap-Target: separates Tap-Handling, sodass nicht versehentlich der Row-Tap (Aufklappen) ausgelöst wird

**Hinweis:** Wenn die Row die aktuell aktive Übung ist, ist das Play-Icon ausgeblendet — die blaue Hintergrund-Hervorhebung signalisiert ohnehin schon den Status.

---

## 9. Edge Cases

| Fall | Verhalten |
|---|---|
| Keine Sätze in `sets` | Detail-Sektion zeigt `EmptyState` mit Text "Keine Sätze konfiguriert" |
| Alle Sätze completed | Detail wird trotzdem angezeigt — alle Werte sichtbar, alle mit ✓ |
| Sortiermodus aktiv mit offener Row | Row wird mit Animation eingeklappt (`expandedExerciseKey = nil`) |
| `selectedExerciseKey` wird auf `nil` gesetzt | `expandedExerciseKey` bleibt unverändert (kein Auto-Collapse) |
| Übung wird aus der Session gelöscht während sie offen ist | `expandedExerciseKey` zeigt auf nicht mehr existierenden Key — die Row verschwindet automatisch durch das `ForEach` |
| Superset-Verbindung sichtbar | Vertikale blaue Linie links der Row bleibt unberührt — Detail-Sektion respektiert das vorhandene Padding |

---

## 10. Akzeptanzkriterien

1. ✅ Tap auf eine Row klappt sie auf, alle anderen klappen zu
2. ✅ Tap auf eine bereits offene Row klappt sie zu
3. ✅ Beim Öffnen der `ActiveWorkoutView` ist die aktuell aktive Übung automatisch aufgeklappt
4. ✅ Wechselt `selectedExerciseKey`, wechselt auch die aufgeklappte Row entsprechend
5. ✅ Im Sortiermodus sind alle Rows zugeklappt und Tap auf Row hat keinen Aufklapp-Effekt
6. ✅ Chevron-Icon ist sichtbar im Normalmodus und rotiert beim Aufklappen
7. ✅ Detail-Sektion zeigt pro Satz: Satznummer, Gewicht × Wdh., Status-Marker
8. ✅ Abgeschlossene Sätze zeigen tatsächliche Werte mit grünem Häkchen
9. ✅ Offene Sätze zeigen geplante Werte mit reduzierter Opacity und `–`-Marker
10. ✅ Animation beim Auf-/Zuklappen ist flüssig (250ms ease-in-out)
11. ✅ Play-Icon erscheint rechts in nicht-aktiven Rows und ermöglicht Auswahl als aktive Übung
12. ✅ App bleibt während der gesamten Implementierung an jedem STOPP-Gate buildbar
13. ✅ Datei `ExercisesOverviewCard.swift` bleibt unter 600 Zeilen

---

## 11. Phasen-Übersicht

| Phase | Inhalt | Build-Check |
|---|---|---|
| **Phase 1** | `selectedExerciseKey` als Parameter durch `ActiveWorkoutView` → `ExercisesOverviewCard` durchreichen | STOPP — Build-Check |
| **Phase 2** | `expandedExerciseKey`-State + `onChange`-Handler + `isSortMode`-Reset hinzufügen | STOPP — Build-Check |
| **Phase 3** | `ExerciseOverviewRow` um `isExpanded` + `onToggleExpand`-Properties erweitern, Tap-Geste umstellen | STOPP — Build-Check |
| **Phase 4** | Chevron-Indikator in `topLine` einbauen (rechts neben Counter), Rotation animieren | STOPP — Build-Check |
| **Phase 5** | `ExerciseOverviewExpandedDetail`-Subview implementieren, in `ExerciseOverviewRow` bedingt einblenden | STOPP — Build-Check + visueller Test |
| **Phase 6** | Play-Icon in `topLine` einbauen, Tap-Routing für Auswahl als aktive Übung | STOPP — Build-Check + funktionaler Test |
| **Phase 7** | Edge-Cases prüfen (Sortiermodus, leere Sets, Übungswechsel), Animation feinjustieren | STOPP — Final-Check |

Jede Phase wird in der Claude-Code-Instruction als nummerierter Schritt mit STOPP-Gate ausgeführt. Keine Phase startet ohne explizites "Go".
