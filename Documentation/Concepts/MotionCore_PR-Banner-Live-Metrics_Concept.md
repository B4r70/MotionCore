# Konzept: PR-Banner Fix + Live-Metriken Redesign

**Version:** 1.0  
**Datum:** 2026-09-27  
**Quelle:** Notion „MotionCore: Ideas/Features/Bugs" — Punkt 5 + 7

---

## Punkt 5 — PR-Banner überlagert Header (Bug-Fix)

### Problem

Das PR-Banner (`PRBannerView`) erscheint als ZStack-Overlay in `ActiveWorkoutView` (Z. 146–157) direkt über dem `ActiveWorkoutStatus`-Header. Der Background ist nur `Theme.warning.opacity(0.10)` — keine deckende Fläche → Header-Chips scheinen durch, Text kaum lesbar.

### Entscheidung

**Variante B: Banner aus dem ZStack-Overlay raus, in den VStack zwischen `ActiveWorkoutStatus` und `ScrollView` schieben.** Kein Overlap möglich, sauberste Lösung.

Zusätzlich: Auto-Dismiss von 3s auf **5 Sekunden** erhöhen.

### Betroffene Dateien

| Datei | Änderung |
|---|---|
| `ActiveWorkoutView.swift` | Banner-Platzierung von ZStack-Overlay → VStack-Einschub |
| `PRBannerView.swift` | Standard-Card-Pattern anwenden (deckende Fläche + Schatten) |

### Phase 1: PRBannerView — Card-Pattern anwenden

**Datei:** `PRBannerView.swift`

Den `.background()`/`.overlay()`-Block (Z. 42–50) ersetzen durch das Standard-Card-Pattern aus `Card.swift`. Das Banner soll visuell wie eine reguläre Card aussehen, aber mit Warning-Akzent.

**Vorher (Z. 42–50):**
```swift
.background(
    Theme.warning.opacity(0.10),
    in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
)
.overlay(
    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        .stroke(Theme.warning.opacity(0.35), lineWidth: 1)
)
```

**Nachher:**
```swift
.background(Theme.surfaceCard)
.clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        .stroke(Theme.warning.opacity(0.35), lineWidth: 1)
)
.shadow(color: scheme == .dark ? .clear : Color(hex: "#16202B").opacity(0.04),
        radius: 2, y: 1)
```

Dafür braucht `PRBannerView` eine `@Environment(\.colorScheme)` Property für den Schatten (identisch zum Pattern in `CardStyle`).

Optional: Einen subtilen Warning-Tint obendrauf legen, damit das Banner sich farblich abhebt — z.B. ein separater Layer `Theme.warning.opacity(0.06)` über der `surfaceCard`-Fläche, innerhalb des `clipShape`. Ob das visuell besser ist als pure `surfaceCard`, im Preview testen und entscheiden.

### Phase 2: ActiveWorkoutView — Banner in VStack verschieben

**Datei:** `ActiveWorkoutView.swift`

Das Banner aus dem ZStack-Overlay (Z. 146–157) entfernen und stattdessen im bestehenden VStack (Z. 127–144) zwischen `ActiveWorkoutStatus` und `ScrollView` einfügen.

**Vorher (vereinfacht):**
```swift
ZStack {
    AnimatedBackground()

    VStack(spacing: 0) {
        ActiveWorkoutStatus(...)
        ScrollView { scrollContent }
    }

    // PR-Banner Overlay  ← ENTFERNEN
    if prBannerExercise != nil {
        VStack {
            PRBannerView(...)
            Spacer()
        }
        .zIndex(100)
    }
}
```

**Nachher:**
```swift
ZStack {
    AnimatedBackground()

    VStack(spacing: 0) {
        ActiveWorkoutStatus(...)

        // PR-Banner inline (kein Overlay mehr)
        if let exercise = prBannerExercise {
            PRBannerView(exerciseName: exercise, oneRM: prBannerOneRM)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7),
                           value: prBannerExercise)
        }

        ScrollView { scrollContent }
    }
}
```

Die `.transition()` und `.animation()` bleiben am Banner — das sorgt dafür, dass es sanft von oben einschiebt und den ScrollView nach unten drückt.

### Phase 3: Auto-Dismiss auf 5 Sekunden

**Datei:** `ActiveWorkoutView.swift`

In der `.onReceive(setManager.prDetected)` Closure (Z. 263–271) den Timer von 3 auf 5 Sekunden ändern:

```swift
.onReceive(setManager.prDetected) { set, name, oneRM in
    prSetIDs.insert(set.persistentModelID)
    prBannerExercise = name
    prBannerOneRM = oneRM
    Task {
        try? await Task.sleep(for: .seconds(5))  // war: 3
        withAnimation(.easeOut) { prBannerExercise = nil }
    }
}
```

### STOPP-Gate nach Phase 3

Preview-Screenshot des PR-Banners (mit und ohne Warning-Tint) vorzeigen. Erst nach Freigabe weiter.

---

## Punkt 7 — Kalorien/BPM-Anzeige Redesign

### Problem

Die Live-Health-Daten (Herzfrequenz, Kalorien, Watch-Status) werden aktuell als schlichte Pills in einer separaten `liveChipsRow` unter dem Fortschrittsbalken angezeigt. Funktional korrekt, aber visuell nicht auf Augenhöhe mit dem Rest des Designs.

### Entscheidung

**Variante C: In Metrik-Zeile integriert — 4-Spalten-Layout (Timer, Volumen, Puls, Kcal).** Die Pills-Zeile entfällt, HR und Kalorien werden direkt in die `metricRow` integriert. Der Watch-Status-Badge bleibt erhalten und wird in die neue Zeile eingebaut.

Puls-Zonen sind für die Zukunft vorgemerkt, aber **nicht Teil dieser Umsetzung**.

### Betroffene Dateien

| Datei | Änderung |
|---|---|
| `ActiveWorkoutStatus.swift` | `metricRow` von 3 auf 4 Spalten erweitern, `liveChipsRow` entfernen, Watch-Badge integrieren |

### Design-Konzept

Die `metricRow` wird erweitert:

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  ⏱ 24:18    │  4.3 t      │  ♥ 138      │  🔥 214     │
│  Push Day A │  VOLUMEN    │  BPM        │  KCAL       │
└─────────────┴─────────────┴─────────────┴─────────────┘
                                          ⌚ LIVE ──────┘
```

**Regeln:**

1. Timer (links, `.leading`) und Sätze (rechts, `.trailing`) sind fix — immer sichtbar.
2. Volumen erscheint dynamisch bei `sessionVolume > 0` (bestehendes Verhalten).
3. HR und Kalorien erscheinen dynamisch wenn `> 0` (gleiche Logik wie bisher bei den Pills).
4. Watch-Badge wird **unter der Kalorien-Spalte** oder **rechts neben der letzten Metrik** als kleines Label positioniert — kein eigener Slot im Grid, sondern als Overlay/Suffix an der rechten Spalte.
5. Layout passt sich an: Wenn kein HR/Kcal da ist → 3-Spalten-Layout wie bisher (Timer, Volumen, Sätze). Kommt HR dazu → 4 Spalten. Kommt auch Kcal → 5 (oder HR+Kcal in einer Doppelspalte).

### Phase 1: metricRow erweitern

**Datei:** `ActiveWorkoutStatus.swift`

Die bestehende `metricRow` hat 3 Spalten (Timer, Volumen, Sätze) mit `.frame(maxWidth: .infinity)`. Erweiterung um HR und Kcal als zusätzliche Spalten, die dynamisch ein-/ausblenden.

**Spalten-Reihenfolge:** Timer · Volumen · Sätze · HR · Kcal

Die HR- und Kcal-Spalten folgen dem gleichen Pattern wie Volumen:

```swift
// Puls (rechts neben Sätze) — nur wenn > 0
if currentHR > 0 {
    VStack(spacing: Space.s1) {
        HStack(spacing: Space.s1) {
            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.danger)
            Text("\(Int(currentHR))")
                .font(metricFont)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        eyebrow("BPM")
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .transition(.scale.combined(with: .opacity))
}

// Kalorien (ganz rechts) — nur wenn > 0
if activeCalories > 0 {
    VStack(spacing: Space.s1) {
        HStack(spacing: Space.s1) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.warning)
            Text("\(Int(activeCalories))")
                .font(metricFont)
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        eyebrow("KCAL")
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .transition(.scale.combined(with: .opacity))
}
```

**Spaltenbreiten:** Wenn alle 5 Spalten sichtbar sind, wird es eng. Zwei Optionen:

- **Option A (empfohlen):** Bei aktiver Watch (HR + Kcal sichtbar) die Sätze-Spalte in die Timer-Spalte als zweite Zeile verschieben → Layout wird: `Timer+Sätze | Volumen | HR | Kcal`. Das hält die Spalten breit genug.
- **Option B:** Alle 5 nebeneinander, `metricFont`-Größe bleibt, Spalten quetschen sich. Auf schmalen Geräten (iPhone SE) problematisch.

**STOPP-Gate:** Welche Option (A oder B)? → Muss im Preview getestet werden. Beide implementieren, per `Bool` switchen, Preview-Screenshots vergleichen.

### Phase 2: Watch-Badge integrieren

Der Watch-Status-Badge (`LIVE`/`Watch`/`Disconnected`) wird als kleines Label **unter die letzte sichtbare Metrik-Spalte** gehängt (also unter Kcal oder HR, je nachdem was am weitesten rechts steht).

```swift
// Innerhalb der Kcal-Spalte (oder als letzte VStack-Zeile der rechten Spalte):
if watchConnectionState != .hidden {
    HStack(spacing: Space.s1) {
        Image(systemName: "applewatch")
            .font(.system(size: 10))
        Text(watchStatusText)
            .font(AppFont.eyebrow)
            .textCase(.uppercase)
            .tracking(0.6)
    }
    .foregroundStyle(watchStatusColor)
}
```

Dabei die Watch-Farben-Logik aus dem bestehenden `watchLivePill` übernehmen (`.activeTracking` → `Theme.success`, `.connected` → `Theme.accent`, `.disconnected` → `Theme.textTertiary`).

### Phase 3: liveChipsRow entfernen

Wenn die Metriken in die `metricRow` integriert sind:

1. `showLiveChips` Property entfernen
2. `liveChipsRow` View entfernen
3. `metricPill()` Helper entfernen
4. `watchLivePill` View entfernen
5. `watchPill()` Helper entfernen
6. Im `body` die Zeile `if showLiveChips { liveChipsRow }` entfernen

### Phase 4: Animation

Die `.animation()` für das Volumen-Einblenden (Z. 108) erweitern, damit auch HR/Kcal-Spalten sanft ein-/ausblenden:

```swift
.animation(reduceMotion ? nil : .easeInOut(duration: 0.24),
           value: currentHR > 0)
.animation(reduceMotion ? nil : .easeInOut(duration: 0.24),
           value: activeCalories > 0)
```

### STOPP-Gate nach Phase 2

Preview-Screenshots des 4-/5-Spalten-Layouts (mit und ohne HR/Kcal) vorzeigen. Spaltenbreiten-Entscheidung (Option A vs B) festlegen. Erst nach Freigabe die alte `liveChipsRow` entfernen (Phase 3+4).

---

## Zusammenfassung Reihenfolge

| # | Phase | Datei(en) | Beschreibung |
|---|---|---|---|
| 1 | P5-1 | `PRBannerView.swift` | Card-Pattern (deckende Fläche + Schatten) |
| 2 | P5-2 | `ActiveWorkoutView.swift` | Banner von ZStack-Overlay → VStack-Einschub |
| 3 | P5-3 | `ActiveWorkoutView.swift` | Auto-Dismiss 3s → 5s |
| 4 | **STOPP** | — | Preview-Screenshot PR-Banner → Freigabe |
| 5 | P7-1 | `ActiveWorkoutStatus.swift` | metricRow: HR + Kcal als Spalten |
| 6 | P7-2 | `ActiveWorkoutStatus.swift` | Watch-Badge in Metrik-Zeile |
| 7 | **STOPP** | — | Preview-Screenshot Layout → Spaltenbreiten-Entscheidung |
| 8 | P7-3 | `ActiveWorkoutStatus.swift` | liveChipsRow + Pills-Helper entfernen |
| 9 | P7-4 | `ActiveWorkoutStatus.swift` | Animationen |

## Nicht in Scope

- Puls-Zonen-Anzeige (Notion offen lassen, eigenes Konzept bei Bedarf)
- Punkt 9 (Strecke in km als Pace-Einheit) — zurückgestellt
