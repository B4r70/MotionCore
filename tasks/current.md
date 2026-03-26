# Muskel-Heatmap — Implementierungsplan

**Komplexität:** Large (4 Blocks)
**Freigabe:** Block A (aktiv) | Block B–D (pending)

## Summary

Interaktive Muskel-Heatmap für MotionCore basierend auf einem neuen feingranularen `DetailedMuscle` Enum (39 Cases, 1:1 mit Supabase-Identifiern) und SVG-Visualisierung. Integration in den Analyse-Tab als zweites Segment neben Progression.

## Datensicherheits-Garantie

- Keine bestehende Exercise, Relationship oder Funktionalität darf verloren gehen
- `MuscleGroup` Enum bleibt unverändert
- `primaryMusclesRaw` und `secondaryMusclesRaw` bleiben als Felder erhalten
- Convenience Init und Supabase Init werden in Block A NICHT angefasst

---

## Block A: DetailedMuscle Enum + Exercise-Felder [AKTIV]

### A1 — DetailedMuscle ersetzen [OPEN]
- **Datei:** `MotionCore/Models/Types/StrengthTypes.swift`
- Altes `enum DetailedMuscle` (Zeile 53–120) durch neues 39-Case-Enum ersetzen
- Extension mit: `svgRegionId: String?`, `parentGroup: MuscleGroup`, `displayName: String`, `supabaseIdentifier: String?`
- `MuscleGroup` + `StrengthWorkoutType` bleiben unberührt

### A2 — Exercise neue Felder [OPEN]
- **Datei:** `MotionCore/Models/Core/Exercise.swift`
- **A2a:** `detailedPrimaryMusclesRaw` + `detailedSecondaryMusclesRaw` nach `secondaryMusclesRaw` (Zeile 66), vor `@Relationship` (Zeile 68)
- **A2b:** Computed Properties `detailedPrimaryMuscles` + `detailedSecondaryMuscles` nach `secondaryMuscles` (Zeile 199), vor `allMuscles` (Zeile 201)
- **A2c:** `primaryMuscles` + `secondaryMuscles` Getter mit Fallback-Logik (DetailedMuscle → parentGroup, sonst alte Raw-Felder)
- **A2d:** Haupt-Init um 2 neue Parameter erweitern nach `secondaryMusclesRaw: [String] = []` (Zeile 112)
- Convenience Init + Supabase Init: NICHT ändern

### Validierung Block A
- [ ] Xcode Build (`Cmd+B`) erfolgreich
- [ ] `DetailedMuscle` Treffer nur in `StrengthTypes.swift` und `Exercise.swift`
- [ ] `detailedPrimaryMusclesRaw` Treffer nur in `Exercise.swift`
- [ ] Keine anderen Dateien verändert

---

## Block B: Import-Pipeline + Enrichment [PENDING]

### B1 — MuscleGroupMapper erweitern [PENDING]
- `mapDetailed(supabaseValue:) -> DetailedMuscle?` hinzufügen

### B2 — Exercise Supabase-Init anpassen [PENDING]
- Muscle-Mapping auf DetailedMuscle umstellen, `detailedPrimaryMusclesRaw` befüllen

### B3 — In-Place Enrichment [PENDING]
- `ExerciseImportManager.enrichWithDetailedMuscles(context:progressHandler:)` hinzufügen

---

## Block C: Types + CalcEngine + ViewModel [PENDING]

### C1 — MuscleHeatmapTypes.swift [PENDING]
- `HeatLevel` Enum, `MuscleHeatData` Struct, `MuscleHeatmapAnalysis` Struct

### C2 — MuscleHeatmapCalcEngine.swift [PENDING]
- Reiner Struct, `analyze(sessions:timeframe:) -> MuscleHeatmapAnalysis`

### C3 — MuscleHeatmapViewModel.swift [PENDING]
- `@Observable`, gecachtes Ergebnis

---

## Block D: SVG + Views + Tab-Umbau [PENDING]

### D1–D5 — Neue View-Dateien [PENDING]
- `MuscleHeatmapSVGView`, `MuscleHeatmapLegend`, `MuscleHeatmapView`, `MuscleHeatmapMiniView`

### D6 — ProgressionAnalyseView Umbau [PENDING]
- Segmented Control (Progression | Heatmap)

### D7 — StrengthDetailView Mini-Heatmap [PENDING]
- `MuscleHeatmapMiniView(session:)` einfügen

---

## Geänderte/neue Dateien (Gesamt)

| Datei | Block | Status |
|---|---|---|
| `StrengthTypes.swift` | A | OPEN |
| `Exercise.swift` | A+B | OPEN |
| `MuscleGroupMapper.swift` | B | PENDING |
| `ExerciseImportManager.swift` | B | PENDING |
| `MuscleHeatmapTypes.swift` (neu) | C | PENDING |
| `MuscleHeatmapCalcEngine.swift` (neu) | C | PENDING |
| `MuscleHeatmapViewModel.swift` (neu) | C | PENDING |
| `MuscleHeatmapSVGView.swift` (neu) | D | PENDING |
| `MuscleHeatmapLegend.swift` (neu) | D | PENDING |
| `MuscleHeatmapView.swift` (neu) | D | PENDING |
| `MuscleHeatmapMiniView.swift` (neu) | D | PENDING |
| `ProgressionAnalyseView.swift` | D | PENDING |
| `StrengthDetailView.swift` | D | PENDING |

## Progress Log

### 26.03.2026 — Block A gestartet
