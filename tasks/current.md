# Heatmap Composite Score

**Complexity:** Small

## Summary

Rekalkulation der Muskel-Heatmap: `relativeIntensity` wird von reinem Volumen auf einen gewichteten Composite Score aus Volumen (40%), Satzzahl (35%) und Frequenz (25%) umgestellt.

## Affected Files

- `MotionCore/Models/Types/MuscleHeatmapTypes.swift` — `totalFrequency` Property + `frequencyFormatted` zu `MuscleHeatData`; `totalFrequency` zu `MuscleHeatmapAnalysis`; `topRegions` Sortierung auf `relativeIntensity`
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — `frequencyByRegion` Dictionary, Session-UUID-Tracking, Composite Score Berechnung, angepasste Initialisierungen
- `MotionCore/Views/Progression/View/MuscleHeatmapView.swift` — `topMusclesCard` zeigt Sets + Frequenz; `MuscleDetailSheet` bekommt Frequenz-Zeile

## Implementation Steps

### Schritt 1: MuscleHeatmapTypes.swift erweitern

- [x] `MuscleHeatData`: neues Property `let totalFrequency: Int` nach `totalSets` einfügen
- [x] `MuscleHeatData`: Computed Property `frequencyFormatted` hinzufügen
- [x] `MuscleHeatmapAnalysis`: neues Property `let totalFrequency: Int` nach `totalSets` einfügen
- [x] `MuscleHeatmapAnalysis.topRegions`: Sortierung von `.totalVolume` auf `.relativeIntensity` ändern

### Schritt 2: MuscleHeatmapCalcEngine.swift — Composite Score

- [x] `frequencyByRegion: [String: Set<UUID>]` Dictionary anlegen
- [x] Im Primär-Block: `session.sessionUUID` in `frequencyByRegion` einfügen
- [x] Im Sekundär-Block: `session.sessionUUID` in `frequencyByRegion` einfügen
- [x] Maxima für `maxSets` und `maxFrequency` berechnen
- [x] Gewichtungskonstanten definieren (0.40 / 0.35 / 0.25)
- [x] In der `for regionId`-Schleife: normalisierte Faktoren + `compositeScore` berechnen
- [x] `relativeIntensity` und `heatLevel` auf `compositeScore` umstellen
- [x] `MuscleHeatData`-Init: `totalFrequency: frequency` ergänzen
- [x] `MuscleHeatmapAnalysis`-Return: `totalFrequency: maxFrequency` ergänzen

### Schritt 3: MuscleHeatmapView.swift — UI anpassen

- [x] `topMusclesCard`: `Text(region.volumeFormatted)` → `Text("\(region.totalSets) Sets · \(region.frequencyFormatted)")`
- [x] `MuscleDetailSheet`: Frequenz-Zeile nach Sets-Zeile einfügen

## Manual Verification

- [ ] Xcode Build (Cmd+B)
- [ ] Simulator: MuscleHeatmapView öffnen → Heatmap-Farben prüfen
- [ ] Simulator: "Meist trainiert"-Card → zeigt Sets + Sessions statt kg
- [ ] Simulator: Muskelregion antippen → Detail-Sheet zeigt Frequenz-Zeile
- [ ] Simulator: Timeframe wechseln → Werte aktualisieren sich korrekt

---

## Fortschritt

**2026-04-06**

Abgeschlossene Schritte: Schritt 1, 2, 3 (alle Implementierungsschritte vollständig)

Geänderte Dateien:
- `MotionCore/Models/Types/MuscleHeatmapTypes.swift` — `totalFrequency` in `MuscleHeatData` + `MuscleHeatmapAnalysis`, `frequencyFormatted`, `topRegions` Sortierung
- `MotionCore/Services/Calculation/MuscleHeatmapCalcEngine.swift` — `frequencyByRegion` Dictionary, Session-UUID-Tracking in Primär- und Sekundär-Block, `maxSets`/`maxFrequency` Maxima, Gewichtungskonstanten, Composite Score Berechnung, angepasste Initialisierungen
- `MotionCore/Views/Progression/View/MuscleHeatmapView.swift` — `topMusclesCard` zeigt Sets + Frequenz, `MuscleDetailSheet` Frequenz-Zeile

Offen: Manuelle Verifikation im Simulator (Xcode Build + visuelle Prüfung)
