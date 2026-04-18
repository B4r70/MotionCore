# Trainingshistorie im MuscleDetailSheet

**Complexity:** Medium

## Summary

Ergänzung einer gruppierten Trainingshistorie im Muskel-Detail-Sheet der Heatmap. Wenn der Nutzer eine Muskelregion antippt, sieht er neben den bestehenden Statistiken eine chronologisch sortierte Liste aller Sessions, in denen der Muskel trainiert wurde — mit Übungsname, Set-Anzahl, Wiederholungen, Maximalgewicht und Gesamt-Volumen pro Übung.

## Scope

- Enthalten: Neue Typen, CalcEngine-Methode, Sheet-Erweiterung, Datenfluss-Anpassung
- Ausgeschlossen: Änderungen am Datenmodell (StrengthSession/ExerciseSet), neue Dateien, ViewModel-Caching der History

## Affected Files

- `MotionCore/Models/Types/MuscleHeatmapTypes.swift` — neue Typen `MuscleTrainingHistorySession` und `MuscleTrainingHistoryExercise`
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — neue Methode `trainingHistory(for:sessions:timeframe:)`
- `MotionCore/Views/Progression/View/MuscleHeatmapView.swift` — Sheet-Aufruf erweitern, `MuscleDetailSheet` um History-Section ergänzen

## Implementation Steps

### Schritt 1: Neue Typen in MuscleHeatmapTypes.swift

- [x] Struct `MuscleTrainingHistoryExercise` hinzufügen:
  - `exerciseName: String`, `setCount: Int`, `totalReps: Int`, `maxWeight: Double`, `totalVolume: Double`, `isPrimary: Bool`
- [x] Struct `MuscleTrainingHistorySession` hinzufügen:
  - `id: UUID` (= sessionUUID), `sessionDate: Date`, `planName: String?`, `exercises: [MuscleTrainingHistoryExercise]`

### Schritt 2: CalcEngine — `trainingHistory(for:sessions:timeframe:)`

- [x] Neue Methode `func trainingHistory(for svgRegionId: String, sessions: [StrengthSession], timeframe: SummaryTimeframe) -> [MuscleTrainingHistorySession]`
- [x] `filterSessions` aufrufen (bestehende private Methode wiederverwenden)
- [x] Pro Session: Sets durchgehen, `resolveDetailedMuscles` für primary + secondary aufrufen, passende Übungen identifizieren
- [x] Relevante Sets nach `groupKey` gruppieren → pro Gruppe aggregieren: setCount, totalReps, maxWeight, totalVolume, isPrimary
- [x] `MuscleTrainingHistorySession` erstellen mit `session.sessionUUID`, `session.date`, `session.planName`
- [x] Ergebnis nach `sessionDate` absteigend sortieren, nur Sessions mit mindestens einer Übung zurückgeben

### Schritt 3: Sheet-Aufruf in MuscleHeatmapView anpassen

- [x] `MuscleDetailSheet` erhält zusätzlich `sessions: [StrengthSession]` und `timeframe: SummaryTimeframe`
- [x] `.sheet`-Aufruf entsprechend erweitern

### Schritt 4: MuscleDetailSheet — History-Section

- [x] `@State private var history: [MuscleTrainingHistorySession] = []`
- [x] `.task(id: data.svgRegionId) { history = MuscleHeatmapCalcEngine().trainingHistory(...) }`
- [x] Section "Trainingshistorie" nach bestehenden Statistiken:
  - Header: Datum + Planname
  - Pro Übung: Name, Sets×Reps, Maxgewicht, Volumen
  - Sekundäre Muskeln visuell unterscheidbar (`.secondary` Farbe)
- [x] Leerer Zustand: Section wird nur angezeigt wenn `!history.isEmpty`

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Simulator: Muskelregion antippen → bestehende Statistiken weiterhin sichtbar
- [ ] Simulator: Trainingshistorie-Section mit gruppierten Sessions + Übungen
- [ ] Simulator: neueste Sessions stehen oben
- [ ] Simulator: Planname wird angezeigt wenn vorhanden
- [ ] Simulator: untrainierte Region → keine History-Section

---

## Fortschritt

**2026-04-06**

Abgeschlossene Schritte: 1–4 (alle Implementierungsschritte)

Geänderte Dateien:
- `MotionCore/Models/Types/MuscleHeatmapTypes.swift` — `MuscleTrainingHistoryExercise` + `MuscleTrainingHistorySession` hinzugefügt
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — `trainingHistory(for:sessions:timeframe:)` eingefügt
- `MotionCore/Views/Progression/View/MuscleHeatmapView.swift` — Sheet-Aufruf erweitert, `MuscleDetailSheet` um Properties, `.task`, History-Section und Hilfsfunktionen ergänzt

Anpassungen gegenüber Plan:
- `groupKey` ist auf `ExerciseSet` nicht optional → kein `?? exerciseNameSnapshot` Fallback nötig
- `session.planName` als berechnete Property genutzt (entspricht `sourceTrainingPlan?.title`)
- `resolveDetailedMuscles` Parameter heißt `for:`, nicht `from:`
- `svgRegionId` auf `DetailedMuscle` ist optional → Vergleich `$0.svgRegionId == svgRegionId` funktioniert korrekt (Optional == String? ergibt false bei nil)

Offene Punkte: Manueller Build + Simulator-Test durch den Nutzer
