# Quality Gate — Smart Plan-Update

**Datum:** 2026-03-21
**Task:** Smart Plan-Update (`tasks/current.md`)
**Reviewte Dateien:** 12 (6 neu, 6 geändert)

---

## Status nach Fixes

**Review:** ✅ Passed
**Verification:** ✅ Passed (nach 3 Fixes)

---

## Behobene Issues

### Finding 1 — [Hoch] sourceSessionUUID zeigte auf vorheriges Update

- `PlanUpdateProposal` um `sourceSessionUUID: String?` erweitert
- `PlanUpdateCalcEngine.analyze()` befüllt das Feld mit `sessions.first?.id.uuidString`
- `PlanUpdateSheet.applyChanges()` übergibt `proposal.sourceSessionUUID` an Applicator

### Finding 3 — [Mittel] Sheet Race Condition

- `@State private var planUpdateSheetProposal: PlanUpdateProposal?` als lokale Sheet-State-Variable eingeführt
- `PlanUpdateProposal` implementiert `Identifiable` (via `plan.planUUID`)
- `.sheet(item: $planUpdateSheetProposal)` statt `isPresented` + innere `if let`-Prüfung
- Banner-Sichtbarkeit (`pendingPlanUpdateProposal`) und Sheet-Öffnen (`planUpdateSheetProposal`) sind damit getrennt

### Finding 7 — [Niedrig] Skipped-Toggle aktivierbar ohne Wirkung

- `.disabled(isSkipped)` auf den Toggle in `PlanUpdateChangeRow`
- Berechnete `isSkipped`-Property kapselt den Case-Check

---

## Offene Punkte (Low — kein Blocker)

### Finding 2 — planUpdateMinRepsDelta ohne Wirkung

`planUpdateMinRepsDelta` ist in `AppSettings` und CalcEngine vorhanden, aber in `analyzeSetCountTrend` nicht genutzt (hardcodiert `>= 1`). Da `targetRepsUpdate` in v1 explizit ausgeschlossen ist, ist das akzeptabel. Technische Schuld für v2 wenn Reps-Trend implementiert wird.

### Finding 4 — Implizite Sortierungsabhängigkeit in detectNewExercises

`newestSets` setzt auf die Annahme, dass `sessions` neueste-zuerst sortiert ist. Kommentar im Code wäre hilfreich, kein funktionales Problem.

### Finding 5 — Skipped-Logik weicht von Spec ab (bewusste Verbesserung)

Implementierung zeigt Skipped-Warnung wenn Übung in ≥ 50% der Sessions fehlt (nicht nur wenn komplett übersprungen). Ist vertretbar und informativer. Spec sollte bei Gelegenheit aktualisiert werden.

### Finding 6 — PlanUpdateProposal trägt TrainingPlan-Referenz

Value-Type-Struct enthält SwiftData-Referenz. Für v1-Lifecycle (kurzlebige Proposals) unbedenklich. Bei zukünftiger Persistierung von Proposals überdenken.

---

## Positive Befunde

- CalcEngine ist pure struct, kein State, kein SwiftUI ✅
- Applicator trennt Mutations-Logik sauber ✅
- `ExerciseSetSnapshot` mit `isUnilateralSnapshot` und `supersetGroupId` ✅
- `lastUpdateSourceSessionUUID: String?` (CloudKit-kompatibel) ✅
- Gewichtsformatierung inline, kein AppFormatter ✅
- 2/3-Threshold mit Double-Cast korrekt ✅
- `smartPlanUpdateEnabled`-Guard in `finishWorkout()` vorhanden ✅
- `planUUID`-Check im Banner für Plan-Zuordnung ✅
- `@EnvironmentObject var sessionManager` in TrainingDetailView ✅
- Index-basiertes Binding in PlanUpdateSheet korrekt ✅
- `.glassCard()` in ChangeRow und Banner ✅
- Leere Sektionen werden ausgeblendet ✅
- Keine force-unwraps in kritischen Pfaden ✅
- Alle neuen Dateien < 220 Zeilen ✅

---

## Manual Verification (ausstehend)

- [ ] Xcode Build (`Cmd+B`) — **neue Dateien müssen manuell zum Target hinzugefügt werden**
- [ ] Preview: `PlanUpdateChangeRow` — alle 4 Varianten, Skipped-Toggle deaktiviert
- [ ] Preview: `PlanUpdateBanner` — Tap öffnet Sheet, X schließt Banner
- [ ] Preview: `PlanUpdateSheet` — alle 3 Sektionen, Übernehmen-Button
- [ ] Preview: `WorkoutSettingsView` — neue Section, Toggle zeigt/versteckt Stepper
- [ ] Simulator: Plan-basiertes Workout beenden → Banner in TrainingDetailView sichtbar
- [ ] Simulator: Banner-Tap → Sheet → Übernehmen → Plan aktualisiert, Banner weg
- [ ] Simulator: Banner-X → Banner weg, keine Änderungen am Plan
- [ ] Simulator: Smart Plan-Update deaktiviert → kein Banner nach Workout-Ende
- [ ] Simulator: Workout ohne Plan → kein Banner, kein Crash
