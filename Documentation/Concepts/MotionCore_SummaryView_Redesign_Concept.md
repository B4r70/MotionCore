# SummaryView Redesign — Konzeptdokument & Claude Code Anweisung

## Übersicht

Kompletter Redesign des `SummaryView`-Dashboards. Der Screen wird von einer statischen Zahlen-Liste in ein emotionales, gamifiziertes Trainings-Dashboard verwandelt, das beim Öffnen zum Lächeln bringt.

**Strategie:** Hybrid — bestehende Cards neu designen + neue Features hinzufügen. Kein Code wird blind gelöscht; bestehende CalcEngine-Logik wird weiterverwendet und durch neue, spezialisierte CalcEngines ergänzt.

**Animations-Level:** Subtil — CountUp-Animationen beim Erscheinen (Zahlen zählen hoch). Keine Parallax- oder Spring-Physik.

**Sprache:** Deutsch, Localization-Ready Strings werden später ergänzt.

---

## Architektur-Überblick

### Neue CalcEngines (jeweils eigene Datei, pure structs, kein SwiftUI-Import)

| CalcEngine | Datei | Verantwortung |
|---|---|---|
| `XPCalcEngine` | `XPCalcEngine.swift` | XP-Punkte, Level, Rang-Berechnung |
| `StreakCalcEngine` | `StreakCalcEngine.swift` | Streak-Logik (aus SummaryCalcEngine extrahiert), Milestone-Erkennung |
| `TrendCalcEngine` | `TrendCalcEngine.swift` | Woche-vs-Woche Vergleiche, Trendpfeile, Prozentwerte |
| `ActivityGridCalcEngine` | `ActivityGridCalcEngine.swift` | 7-Tage-Strip + Monats-Kalender-Daten |
| `WeeklyGoalCalcEngine` | `WeeklyGoalCalcEngine.swift` | Ring-Fortschritt, Ziel-vs-Ist, "über dem Schnitt"-Logik |

### Bestehende Dateien die MODIFIZIERT werden

| Datei | Änderung |
|---|---|
| `SummaryView.swift` | Komplett neues Layout mit neuen Sektionen |
| `SummaryViewModel.swift` | Neue CalcEngines orchestrieren, neue Properties |
| `SummaryCalcEngine.swift` | Streak-Logik extrahieren nach StreakCalcEngine, Rest bleibt |
| `StreakCard.swift` | Redesign: visuell aufwerten, Milestone-Badges integrieren |
| `SummaryRecordsCard.swift` | Redesign: kompakter, mit "Neu!"-Badge bei frischen Rekorden |
| `SummaryTimeframe.swift` | Bleibt unverändert |
| `TypeBreakdownCard.swift` | Bleibt, wird aber weiter unten platziert |
| `StatisticDonutChart.swift` | Bleibt unverändert |
| `ProgressionSummaryCard.swift` | Bleibt unverändert |

### Neue View-Dateien

| Datei | Beschreibung |
|---|---|
| `SummaryHeroCard.swift` | Begrüßung + XP-Level + Wochenziel-Ring |
| `SummaryWeekStrip.swift` | 7-Tage-Aktivitäts-Strip (kompakt, oben) |
| `SummaryActivityCalendar.swift` | Expandierbarer Monats-Kalender |
| `SummaryXPCard.swift` | XP-Fortschrittsbalken, Level, Rang-Badge |
| `SummaryTrendCard.swift` | Volumen/Kalorien/Dauer mit Trendpfeil vs. Vorwoche |
| `SummaryWeeklyGoalRing.swift` | Animierter Fortschrittsring (Apple Activity Ring Style) |
| `SummaryBestExerciseCard.swift` | "Übung der Woche" mit stärkster Progression |
| `SummaryMuscleHeatmapCard.swift` | Mini-Körpersilhouette der Woche (nutzt bestehende MuscleHeatmapMiniSVGView) |
| `CountUpText.swift` | Wiederverwendbare animierte Zahl-Komponente |

### Neue Types-Datei

| Datei | Inhalt |
|---|---|
| `SummaryDashboardTypes.swift` | `XPLevel` enum, `Rank` enum, `WeeklyGoal` struct, `ActivityDay` struct, `TrendComparison` struct, `StreakMilestone` enum |

---

## Detailliertes Design — Screen-Layout (von oben nach unten)

### Sektion 1: Hero Card (`SummaryHeroCard`)

Die wichtigste Neuerung. Wird als ERSTE Karte angezeigt, noch VOR dem TimeframePicker.

**Inhalt:**
- **Zeile 1:** Tageszeit-Begrüßung + XP-Level-Badge
  - "Guten Morgen!" / "Guten Tag!" / "Guten Abend!" (basierend auf Stunde)
  - Daneben: Rang-Badge (z.B. "🥉 Bronze Warrior — Level 12")
- **Zeile 2:** Motivierender Satz (kontextabhängig, NICHT random)
  - Streak aktiv: "Tag 7 in Folge — du bist on fire!"
  - Kein Training heute, aber Streak lebt: "Dein Streak wartet auf dich!"
  - Nach hartem Workout gestern: "Gönn dir die Erholung — du hast es dir verdient."
  - Montag morgens: "Neue Woche, neue Gains!"
  - Wochenziel erreicht: "Ziel erreicht! Du bist über dem Durchschnitt."
- **Zeile 3:** Kompakter XP-Fortschrittsbalken zum nächsten Level

**Design:** GlassCard, aber mit subtiler blauer Gradient-Kante oben (aus AppTheme Tokens: `#C9E6FF` → `#9BD2FF`). Kein volles Gradient-Background — nur ein 2px Akzent oben.

**CalcEngine-Abhängigkeiten:** `XPCalcEngine`, `StreakCalcEngine`, `WeeklyGoalCalcEngine`

### Sektion 2: 7-Tage-Strip (`SummaryWeekStrip`)

Horizontal, kompakt, direkt unter der Hero Card.

**Inhalt:**
- 7 Kreise für Mo–So der aktuellen Woche
- Jeder Kreis zeigt:
  - Leer (grau) = kein Training
  - Gefüllt (farbig nach Workout-Typ) = trainiert
  - Mehrere Workouts = Ring mit mehreren Farb-Segmenten
  - Heute = leicht pulsierender Rand
- Tap auf den Strip → expandiert zum vollen Monats-Kalender (`SummaryActivityCalendar`)

**Design:** Kein eigenes GlassCard — eingebettet als kompakte Zeile. Die Kreise sind 36pt groß mit 8pt Spacing.

**CalcEngine-Abhängigkeit:** `ActivityGridCalcEngine`

### Sektion 3: Wochenziel-Ring + Trend-Stats (Side-by-Side)

Zwei Elemente nebeneinander in einem HStack:

**Links: Weekly Goal Ring (`SummaryWeeklyGoalRing`)**
- Animierter Ring im Apple Activity Ring Style
- Zeigt z.B. "3/4" Workouts diese Woche
- Darunter: Kontexttext:
  - Unter Schnitt: "Noch 2 bis zu deinem Schnitt"
  - Über Schnitt: "Über deinem ⌀ von 3.5!"
  - Ziel erreicht: "Wochenziel erreicht! 🎯"

**Rechts: Trend-Übersicht (`SummaryTrendCard`)**
- 3 kompakte Zeilen:
  - Volumen: "12.450 kg" + Trendpfeil "↑ 8%" (vs. letzte Woche)
  - Kalorien: "2.340 kcal" + Trendpfeil
  - Dauer: "4:30 Std" + Trendpfeil
- Trendpfeil-Farben: Grün (↑ besser), Rot (↓ schlechter), Grau (→ stabil)

**CalcEngine-Abhängigkeiten:** `WeeklyGoalCalcEngine`, `TrendCalcEngine`

### Sektion 4: TimeframePicker (bestehend)

Unverändert, aber NACH Hero/Strip/Ring platziert (nicht mehr ganz oben).

### Sektion 5: Stat-Grid (bestehend, redesigned)

Die 4 bestehenden `StatisticGridCard`-Kacheln bleiben, bekommen aber:
- **CountUp-Animation:** Zahlen zählen von 0 hoch beim Erscheinen
- **Kompakterer Titel:** Kürzer, keine Icons mehr über den Zahlen — Icon + Zahl in einer Zeile
- Layout bleibt 2x2 Grid

### Sektion 6: Muskel-Heatmap der Woche (`SummaryMuscleHeatmapCard`)

Neu! Zeigt die Mini-Körpersilhouette für den gewählten Zeitraum.

**Inhalt:**
- Header: "Trainierte Muskeln" + Zeitraum-Label
- Mini-SVG-Heatmap (wie bestehende `MuscleHeatmapMiniSVGView`, aber für aggregierte Daten aus allen Kraft-Sessions im Zeitraum)
- Darunter: 2-3 Tags der am meisten trainierten Muskelgruppen

**Sichtbarkeit:** Nur anzeigen wenn `strengthSessions` im gewählten Zeitraum vorhanden.

**CalcEngine-Abhängigkeit:** Bestehender `MuscleHeatmapCalcEngine` (oder vereinfachte Variante in `SummaryCalcEngine`)

### Sektion 7: Beste Übung der Woche (`SummaryBestExerciseCard`)

**Inhalt:**
- Header: "⭐ Übung der Woche"
- Übungsname (z.B. "Kniebeugen")
- Warum: "Stärkste Progression: +2.5 kg bei 3×12"
- Mini-Sparkline der letzten 5 Sessions für diese Übung

**Sichtbarkeit:** Nur anzeigen wenn Progressions-Daten vorhanden.

**CalcEngine-Abhängigkeit:** Bestehender `ProgressionCalcEngine` (Ergebnis in ViewModel zwischenspeichern)

### Sektion 8: Streak-Card (bestehend, redesigned)

Bestehende `StreakCard` aufwerten:
- Streak-Milestones hinzufügen: Bei 7, 14, 30, 60, 100 Tagen ein Badge
- Milestone-Text: "🔥 7-Tage-Streak! Nächstes Ziel: 14 Tage"
- Aktive Streak: Flammen-Icon hat subtile Orange-Glow-Animation (einmalig beim Erscheinen)

**CalcEngine-Abhängigkeit:** `StreakCalcEngine`

### Sektion 9: XP & Rang (`SummaryXPCard`)

Das Gamification-Herzstück.

**XP-Quellen (berechnet in `XPCalcEngine`):**
- Workout abgeschlossen: +100 XP Basis
- Workout-Dauer Bonus: +1 XP pro Minute
- Streak-Bonus: +10 XP × aktuelle Streak-Länge (gedeckelt bei +500)
- Persönlicher Rekord: +250 XP
- Wochenziel erreicht: +200 XP
- Konsistenz-Bonus (4+ Wochen in Folge mit Ziel erreicht): +500 XP

**Level-System:**
- Level 1: 0 XP
- Level 2: 500 XP
- Level 3: 1.200 XP
- Level N: Progressiv steigende Schwellen (Formel: `500 * N * (N+1) / 2` oder ähnlich)
- Max-Level: 50 (als "Legende")

**Rang-System (Titel die sich mit dem Level ändern):**

| Level-Range | Rang | Icon |
|---|---|---|
| 1–5 | Rookie | 🌱 |
| 6–10 | Athlet | 💪 |
| 11–15 | Warrior | ⚔️ |
| 16–20 | Champion | 🏆 |
| 21–30 | Elite | 🔥 |
| 31–40 | Master | 👑 |
| 41–50 | Legende | ⭐ |

**Card-Design:**
- Rang-Badge groß oben (Icon + Rang-Name)
- "Level 12 — 3.450 / 4.200 XP"
- Animierter Fortschrittsbalken (füllt sich beim Erscheinen)
- Letzte XP-Gewinne als kompakte Liste: "+100 XP Bankdrücken", "+250 XP Neuer PR!"

**Wichtig:** XP werden NICHT in SwiftData persistiert. Sie werden bei jedem App-Start aus den vorhandenen Sessions berechnet (CalcEngine-Pattern). Das ist die sauberste Lösung: Single Source of Truth bleiben die Sessions.

### Sektion 10: Typ-Aufschlüsselung (bestehend)

`TypeBreakdownCard` + `StatisticDonutChart` — unverändert, nur weiter unten platziert.

### Sektion 11: Rekorde (bestehend, redesigned)

`SummaryRecordsCard` bleibt, bekommt aber:
- "Neu!"-Badge (kleine Capsule) wenn ein Rekord in den letzten 7 Tagen aufgestellt wurde
- Kompakteres Layout

### Sektion 12: Progressions-Empfehlungen (bestehend)

`ProgressionSummaryCard` — unverändert, ganz unten.

---

## Expandierbarer Monats-Kalender (`SummaryActivityCalendar`)

Wird per Tap auf den 7-Tage-Strip angezeigt (`.sheet` oder `.fullScreenCover` oder inline mit Animation).

**Empfehlung:** Inline expandierbar mit `.matchedGeometryEffect` oder einfachem `if showCalendar` + Animation.

**Inhalt:**
- Standard-Kalender-Grid (7 Spalten für Mo–So)
- Jeder Tag farbcodiert nach Intensität:
  - Kein Training: Transparent/sehr dezent grau
  - Leichtes Training: Hellblau (#C9E6FF)
  - Mittleres Training: Mittelblau (#9BD2FF)
  - Hartes Training: Kräftiges Blau (#3B82F6)
  - Mehrere Workouts: Dunkles Blau mit Zahl-Badge
- Monats-Navigation: ← April 2026 →
- Statistik-Zeile unten: "18 Trainingstage • ⌀ 4.5/Woche"

**CalcEngine-Abhängigkeit:** `ActivityGridCalcEngine`

---

## CountUp-Animation (`CountUpText`)

Wiederverwendbare Komponente für animierte Zahlen.

```
Signatur:
struct CountUpText: View {
    let targetValue: Int          // Zielwert
    var duration: Double = 0.8    // Animations-Dauer in Sekunden
    var font: Font = .system(size: 26, weight: .bold, design: .rounded)
}
```

**Verhalten:**
- Zählt von 0 bis `targetValue` über `duration` Sekunden
- Nutzt `withAnimation(.easeOut)` + Timer oder `TimelineView`
- Startet nur einmal beim ersten Erscheinen (nicht bei jedem Rerender)
- Für Werte > 10.000: Schnellere Animation, startet bei 80% des Werts

**WICHTIG:** Keine `Timer.scheduledTimer` verwenden! Stattdessen `TimelineView` mit `.animation(.easeOut)` oder eine State-basierte Lösung mit `task {}`.

---

## Datei-Reihenfolge für Implementation

Die Reihenfolge ist so gewählt, dass jeder Schritt auf dem vorherigen aufbaut und jederzeit kompilierbar bleibt.

### Phase 1: Fundament (Types + CalcEngines)
1. `SummaryDashboardTypes.swift` — Alle neuen Typen
2. `XPCalcEngine.swift` — XP/Level/Rang-Berechnung
3. `StreakCalcEngine.swift` — Streak-Logik aus SummaryCalcEngine extrahieren
4. `TrendCalcEngine.swift` — Woche-vs-Woche Vergleiche
5. `ActivityGridCalcEngine.swift` — 7-Tage + Kalender-Daten
6. `WeeklyGoalCalcEngine.swift` — Ring-Fortschritt

### Phase 2: Shared Components
7. `CountUpText.swift` — Animierte Zahlen

### Phase 3: Neue Cards (einzeln, ohne SummaryView-Änderung)
8. `SummaryHeroCard.swift`
9. `SummaryWeekStrip.swift`
10. `SummaryWeeklyGoalRing.swift`
11. `SummaryTrendCard.swift`
12. `SummaryMuscleHeatmapCard.swift`
13. `SummaryBestExerciseCard.swift`
14. `SummaryXPCard.swift`
15. `SummaryActivityCalendar.swift`

### Phase 4: Integration
16. `SummaryViewModel.swift` — Erweitern um alle neuen CalcEngines
17. `SummaryCalcEngine.swift` — Streak-Code entfernen (lebt jetzt in StreakCalcEngine)
18. `StreakCard.swift` — Redesign mit Milestones
19. `SummaryRecordsCard.swift` — Redesign mit "Neu!"-Badge
20. `SummaryView.swift` — Neues Layout zusammenbauen

---

## Bestehende Dateien die NICHT verändert werden

- `TimeframePicker.swift`
- `SummaryTimeframe.swift`
- `TypeBreakdownCard.swift`
- `WorkoutTypeRow.swift`
- `StatisticDonutChart.swift`
- `ProgressionSummaryCard.swift`
- `SummaryRecordRow.swift`
- `StatisticGridCard` (in `StatisticCard.swift`)
- `GlassCard.swift`
- `MiniSparkline.swift`
- `EmptyState.swift`
- `MuscleHeatmapMiniSVGView` (in `MuscleHeatmapMiniView.swift`) — wird wiederverwendet
- `MuscleHeatmapTypes.swift`
- `ProgressionTypes.swift`
- `CoreSession.swift`
- `AppTheme.swift`

---

## Wichtige Architektur-Regeln

1. **CalcEngines sind pure structs** — kein SwiftUI-Import, keine Side Effects, kein State
2. **XP werden NICHT persistiert** — bei jedem App-Start aus Sessions berechnet
3. **Wochenziel wird in `AppSettings` gespeichert** (UserDefaults, bereits bestehendes Pattern via `AppSettingsUserDefaults`) — neues Property: `weeklyWorkoutGoal: Int` (Default: 4)
4. **CountUp-Animation startet nur einmal** — Flag via `@State private var hasAnimated = false`
5. **Neue Views nutzen `.glassCard()`** — konsistent mit bestehendem Design
6. **Streak-Logik wird EXTRAHIERT, nicht dupliziert** — `SummaryCalcEngine.currentStreak` und `.longestStreak` werden zu Forwarding-Properties die `StreakCalcEngine` aufrufen
7. **Alle neuen Dateien < 400 Zeilen** — bei Überschreitung sofort splitten
8. **German Code-Kommentare, English Variablen/Methoden-Namen**
9. **`.task {}` statt `.onAppear`** für initiale Datenladung
10. **Kein `Timer.scheduledTimer`** — Date-Anchors oder TimelineView für Animationen

---

## Wochenziel-Konfiguration

Neues Property in `AppSettings` / `AppSettingsUserDefaults`:

```
var weeklyWorkoutGoal: Int  // Default: 4, Range: 1–7
```

Editierbar in den bestehenden `WorkoutSettingsView` (neue Sektion: "Wochenziel").

---

## Motivierende Texte — Logik in XPCalcEngine oder eigene Helper-Funktion

**Input-Signale für Text-Auswahl:**
- Aktuelle Stunde (Tageszeit)
- Streak-Status (aktiv? Wie lang? Gestern trainiert? Heute schon?)
- Wochenziel-Status (erreicht? Wie weit entfernt?)
- Letztes Workout (wann? Wie intensiv?)
- Wochentag (Montag = "Neue Woche!", Sonntag = "Starke Woche!")

**Prioritäts-Reihenfolge (erste Match gewinnt):**
1. Wochenziel gerade eben erreicht → Feier-Text
2. Neuer PR heute/gestern → "Neuer Rekord! Du wirst stärker!"
3. Streak ≥ 7 → "Tag X in Folge — Maschine!"
4. Montag + keine Session diese Woche → "Neue Woche, neue Gains!"
5. Heute noch kein Training + Streak aktiv → "Dein Streak wartet!"
6. Nach Training gestern → "Erholung ist auch Training."
7. Fallback → Tageszeit-basierte Begrüßung

---

## Zusammenfassung der Entscheidungen

| Frage | Entscheidung |
|---|---|
| Hero-Bereich | Begrüßung + Fortschrittsring + Mini-Heatmap |
| Wochenziel | Kombiniert: Ring + "Du bist über deinem Schnitt" |
| Gamification | Voll: Levels, XP, Rang-System |
| Activity-Visualisierung | 7-Tage Strip + expandierbarer Monats-Kalender |
| Kraft-Insights | Volumen + Trendpfeile + Beste Übung der Woche |
| E-Bike auf Dashboard | Nein, Nebensache |
| Animations-Level | Subtil: CountUp beim Erscheinen |
| CalcEngine-Architektur | Eigene CalcEngines pro Feature, SummaryCalcEngine orchestriert |
| Migration | Hybrid: bestehende Cards redesignen + neue Features |
| Sprache | Erstmal Deutsch, Localization-Ready später |
