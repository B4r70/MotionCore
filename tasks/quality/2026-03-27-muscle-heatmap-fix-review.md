# Quality Gate — Muscle Heatmap Fix + Exercise-Edit Absicherung

**Datum:** 2026-03-27

---

## Findings

### [MITTEL] ExerciseSeeder.upsertAll() löscht Enrichment-Daten durch den neuen Setter

**Datei:** `Models/Seeder/ExerciseSeeder.swift`, Zeilen 131–132

`apply(seed:to:)` schreibt `existing.primaryMuscles = seed.primaryMuscles`. Der neue Setter leert dabei `detailedPrimaryMusclesRaw = []` auf dem bestehenden Exercise-Objekt. Damit würden bei einem `upsertAll()`-Aufruf alle via Supabase-Enrichment gespeicherten feingranularen Muskeldaten gelöscht — gegenteiliger Effekt zum Bug-Fix.

`upsertAll()` ist kein normaler App-Pfad (expliziter Reset-Modus), aber das Risiko sollte vor dem nächsten Seeder-Aufruf behoben werden.

**Fix:** `apply(seed:to:)` auf direkte Raw-Schreibzugriffe umstellen:
```swift
existing.primaryMusclesRaw = seed.primaryMusclesRaw
existing.secondaryMusclesRaw = seed.secondaryMusclesRaw
// detailedPrimaryMusclesRaw / detailedSecondaryMusclesRaw bleiben unberührt
```

---

### [GERING] Bestehendes TODO in StrengthDetailView (pre-existing)

**Datei:** `StrengthDetailView.swift`, Zeile 565

`repeatWorkout()` navigiert nicht zur `ActiveWorkoutView`. Nicht durch diese Änderung eingeführt.

---

### [INFO] ExerciseImportManager schreibt direkt auf Raw-Felder — kompatibel

`enrichWithDetailedMuscles()` schreibt auf `detailedPrimaryMusclesRaw` direkt, nicht über den Setter. Setter-Fix hat keinen Einfluss auf den Enrichment-Pfad.

---

## Positives

- Setter-Fix korrekt: Getter fällt nach Leeren von `detailedPrimaryMusclesRaw` konsistent auf `primaryMusclesRaw` zurück — Root Cause behoben
- `showDeleteButton: Bool = true` vollständig rückwärtskompatibel — alle bestehenden Aufrufstellen unverändert
- Sekundär-Faktor 0.3 ist der einzige `volume *`-Ausdruck für secondary in der Engine — kein weiteres 0.5 übersehen
- Kein Force-Unwrap, keine Business-Logik in Views

---

## Static Checks

- [x] Compiler-Risiken — keine
- [x] `showDeleteButton`-Aufrufstellen vollständig (`ExerciseListView` Zeile 126, 199 → unverändert, `StrengthDetailView` → `false`)
- [x] Kein weiteres `0.5` für secondary in `MuscleHeatmapCalcEngine`
- [x] Kein neuer Force-Unwrap

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Exercise Muskeln via `ellipsis.circle` korrigieren → Heatmap zeigt korrekte Region
- [ ] Heatmap in MuscleHeatmapView (Analyse-Tab) korrekt
- [ ] ExerciseFormView aus StrengthDetailView — kein Löschen-Button
- [ ] ExerciseFormView aus ExerciseListView — Löschen-Button weiterhin sichtbar
