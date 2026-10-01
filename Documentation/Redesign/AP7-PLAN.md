# AP 7 · Training/Pläne — Plan (freigegeben 2026-06-26)

> Branch `redesign/ap7-training` von `redesign/ap1-shared-components`. Reines UI-Redesign, keine Logik.
> Referenz: `source/screens.jsx` (`TrainingScreen`) + `MotionCore-App-prototype.html`. 21 Views, ~4.898 LOC.

## Entscheidungen
- **PlanType-Ton an AP 4 (WorkoutType) angeglichen:** strength→`accent`, cardio→`series[1]`, outdoor→`success`, mixed→`series[2]`. (App-weite Konsistenz Workout↔Plan.)
- Plan-Karte: Buchstaben-Tile (Plan-Initial) im Typ-Ton (weiche Fläche + gesättigtes Icon), Name + Muskelgruppen + neutrale Badges (X Übungen, ~Y min), „Plan starten" → `.mcSecondary`.
- Metrik-Grids (PlanStatisticsCard) → semantische Map (neutral=series[0], Volumen=series[0]); RIR/Warmup-Töne als Domänen-Skala auf Theme.

## Foundation (solo, zuerst)
- **`PlanType` Theme-Extension** in `TypesUI.swift` (`calmTint` + `calmTileBackground`), ersetzt das String-`color` in ~6 Switch-Stellen. (PlanType ist auf KEINEM Sibling migriert → AP 7 besitzt es, kein Konflikt.)
- **FilterChip** AP-4-Calm-Version replizieren (ap1 = Glas; ExercisePicker nutzt sie 3×) → byte-identisch zu ap4 (trivialer Merge).
- Falls AP-7-Views `Intensity`/`CardioDevice`/`TrainingProgram` nutzen: AP-5-TypesUI-Bits replizieren (prüfen).

## Gates (je grün/rot, Build nach jedem; Commit nach jedem Gate nach visuellem Grün)
- **G1 · Plan-Karten + Detail** — `TrainingListView`, `TrainingPlanCard`, `TrainingDetailView`, `PlanInfoCard`, `PlanStatisticsCard`. AnimatedBackground→surfaceApp, PlanType-Töne, Stats→Map, .card(), glassDivider→Divider.
- **G2 · Set-Konfig + Plan-Edit** — `SetConfigurationSheet` (932), `PlanExercisesSection` (771), `TemplateSetCard`, `PlanBasicDataCard`, `PlanActionsSection`, `SetDurationSection`. Warmup/RIR-Töne→Theme, Inputs/Preset-Buttons, .card().
- **G3 · Picker + Import/Sync** — `ExercisePickerSheet`/`ExercisePickerView`, `PlanImportListSheet`/`PlanImportPreviewSheet`/`PlanImportSchemaMismatchBanner`, `PlanUpdateSheet`/`PlanUpdateBanner`/`PlanUpdateChangeRow`, **`SessionPlanSyncSheet`**, **`PlanPickerSheet`** (aus AP 4 deferred).

## Unangetastet (Logik-Grenze)
- Services: `SessionPlanSyncCalcEngine`, `PlanUpdateApplicator`/`PlanUpdateCalcEngine`, `SessionSyncUndoService`, `PlanImportApplyService`/`PlanImportManager`/`SupabasePlanImportService`.
- `PlanExercisesSection`: Drag&Drop (LongPress+Drag, Höhen-Tracking), Superset-Selection, `plan.reorderExercise`/`createSuperset`/`removeFromSuperset`.
- `SetConfigurationSheet`: `bootstrapState()` Exclusivity-Rule, `makeSet()`/`saveSets()`, Timer-Increment/Autorepeat.
- `@Query`-Filter-Pipelines (ExercisePickerView), alle @Binding/@Bindable/Sheet-Callbacks/Navigation.

## Residue-Grep MUSS enthalten: `glassDivider|GlassDivider.tight` (Lehre aus AP 4).
Bewusst auslassen: `setKind.color`, `ExerciseQualityRating.color` (AP 9), `Color.white`/`.clear`.
