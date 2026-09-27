# Quality Gate — RestTimer zeigt Gewicht der nächsten Übung

## Review Status

✅ Approved

## Verification Status

✅ Plausible

## Findings

1. **[Info]** Dezimaltrenner in `formatKg`/`weightText` rendert mit Punkt (`String(format: "%.1f", value)` ohne `locale:`-Parameter ist locale-unabhängig, liefert also `82.5` statt der in Plan/Akzeptanzkriterien geschriebenen `82,5`).
   - File: `MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift:183-187`
   - Category: Verification
   - Risk: Keiner — `formatKg` ist eine **exakte Kopie** von `ActiveSetCard.formatWeight` (`MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift:351-357`, identischer Code), also konsistent zur bestehenden Konvention. Die Kommaschreibweise in Plan/Akzeptanzkriterien ist ein Dokumentations-Artefakt, keine funktionale Vorgabe.
   - Recommendation: Beim manuellen Testen nicht als Bug werten und nicht "reparieren" — genau dieses Verhalten war das Ziel von Abweichung 3 (Formatierung analog `ActiveSetCard`).

2. **[Info, pre-existing, out of scope]** `RestTimerCardContainer.swift:36` reicht `nextExerciseName: currentSet?.exerciseName` durch, nicht `exerciseNameSnapshot`. CLAUDE.md und `swift-standards` empfehlen `exerciseNameSnapshot` zu bevorzugen; `SetManager.supersetNextRoundNames`/`supersetDisplayContext` machen bereits den Snapshot-Fallback.
   - File: `MotionCore/Views/Workouts/Active/Components/RestTimerCardContainer.swift:36`
   - Category: Review
   - Risk: Gering (nur Anzeigename), Zeile war vor diesem Task bereits so — nicht Teil dieses Diffs, keine Regression.
   - Recommendation: Nicht in diesem Task ändern (out of scope). Ggf. eigenes Kleinticket.

## Positives

- Alle vier dokumentierten Konzept-Abweichungen sind exakt wie im Plan spezifiziert umgesetzt und gegen Quellcode verifiziert:
  - `effectiveWeight` (`ExerciseSet.swift:167-168`) statt `weightPerSide`/`weight` — bestätigt symmetrisch: `weight` ist bei unilateralen Sätzen der Gesamtwert (`SetEditSheet.swift:241,246-248`: `set.weight = weight` (Gesamt), `weightPerSide = weight/2` ist der abgeleitete Spiegelwert). `LastSessionReferenceCalcEngine.Reference.weight` (`LastSessionReferenceCalcEngine.swift:60`) speist sich ebenfalls aus `ExerciseSet.weight`, also demselben Gesamtwert-Konzept — Plan- und Letztes-Mal-Zweig sind dadurch tatsächlich symmetrisch, keine versteckte Asymmetrie.
  - Zweiquellige Unilateral-Erkennung `(currentSet?.isUnilateralSnapshot ?? false) || (currentSet?.exercise?.isUnilateral ?? false)` (`RestTimerCardContainer.swift:43`) ist wortgleich zur Logik in `ActiveSetCard.formattedLastWeight` (`ActiveSetCard.swift:342`).
  - `formatKg` (`RestTimerCard.swift:183-187`) ist identisch zu `ActiveSetCard.formatWeight` (`ActiveSetCard.swift:351-357`), Label „Letztes Mal:" ebenfalls übernommen.
  - Alle 3 bestehenden Preview-Instanzen nachgezogen + neuer Block „Rest Timer — Gewichtszeile" mit unilateralem und Bodyweight-Fall angelegt.
- Gewichtszeile liegt ausschließlich im `else if let exerciseName …`-Zweig von `nextInfo` (`RestTimerCard.swift:102-118`); der Superset-Zweig (`RestTimerCard.swift:77-101`) ist unangetastet und durch die `if/else if`-Kette strukturell exklusiv — keine Regressionsgefahr.
- Bodyweight-Fall (`nextPlanWeight == 0`): `formattedWeightLine` gibt `nil` zurück, das `if let` im `VStack` erzeugt keinen Leerraum — korrekt implementiert, kein Artefakt.
- `heroCard` (`ActiveWorkoutView.swift:929-949`) berechnet nichts selbst — `lastSessionReference: setManager.cachedCurrentSet.flatMap { setManager.lastSessionReference(for: $0) }` ist ein reiner Optional-Map auf einen O(1)-Dictionary-Lookup (`SetManager.swift:331-333`: `cachedLastSessionReferences[set.groupKey]?[set.setNumber]`). Das im Plan benannte Performance-Risiko (sekündliche Neuauswertung von `heroCard`) ist damit sauber vermieden.
- Cache-Wärme-Behauptung aus dem Plan verifiziert: `onAppear` füllt `cachedLastSessionReferences` für **alle** groupKeys (`ActiveWorkoutView.swift:223-227`), `onChange(exerciseListRefreshID)` erneut für alle (`ActiveWorkoutView.swift:286-293`), `onChange(selectedExerciseKey)` zusätzlich gezielt für den neuen Key (`ActiveWorkoutView.swift:302-304`). Der Übergang zwischen zwei Übungen (Akzeptanzkriterium 3 / Manual-Verification-Punkt) ist damit bereits ab `onAppear` abgedeckt, nicht erst bei Auswahlwechsel.
- Kein zusätzlicher `isTimeBased`-Guard eingebaut — zeitbasierte Sätze (`weight == 0`) fallen automatisch durch den `> 0`-Guard in `formattedWeightLine`, exakt wie im Plan gefordert.
- Memberwise-Init-Reihenfolge an allen 5 Call-Sites (heroCard→Container, Container→Card, 4 Preview-Instanzen) stimmt exakt mit der Deklarationsreihenfolge der neuen `let`-Properties überein — kompiliert nur, wenn keine Call-Site übersehen wurde (das im Plan genannte "Sicherheitsnetz" greift tatsächlich).
- Keine Force-Unwraps, kein TODO/FIXME, keine toten Debug-Prints in den geänderten Dateien.
- Dateigröße `RestTimerCard.swift`: 251 Zeilen (Ziel < 400 Zeilen, deutlich unterschritten).
- Datei-Struktur (Header/Imports/Properties/Body/Subviews/Helpers/Preview) entspricht `swift-standards`-Konvention; neue Properties und Helper wurden an der im Plan vorgegebenen Position eingefügt.

## Static Checks

- [x] Obvious compiler risks checked (Argumentreihenfolge an allen 5 Call-Sites, keine fehlenden Labels, keine Typkonflikte)
- [x] Interface consistency checked (RestTimerCard ↔ RestTimerCardContainer ↔ ActiveWorkoutView.heroCard, keine weiteren Call-Sites gefunden außer den im Plan genannten)
- [x] Open TODO / FIXME checked (keine in den 3 geänderten Dateien)
- [x] Anti-patterns checked (kein `AnyView`, kein Force-Unwrap, kein `+`-Text-Konkat, `.foregroundStyle` statt `.foregroundColor`, `.card()` statt veraltetem `.glassCard()` konsistent zu Calm-2026-Design, keine teure Berechnung im sekündlich re-evaluierten `heroCard`)

## Manual Verification Required

- [ ] Build in Xcode (`Cmd+B`) — Entwickler-Agent berichtet `** BUILD SUCCEEDED **` (`tasks/current.md`), **nicht unabhängig durch dieses Quality Gate verifiziert**
- [ ] Preview „Rest Timer Card" (3 Karten) und „Rest Timer — Gewichtszeile" (2 Karten) im Simulator/Canvas ansehen
- [ ] Simulator-Flow: Plan mit Historie, Satz abschließen → Pausenkarte zeigt Plan-Gewicht, ggf. „Letztes Mal:"
- [ ] Übergang zwischen zwei Übungen: Gewichtszeile für ersten Satz der nächsten Übung erscheint sofort
- [ ] Unilaterale Übung: „2×"-Anzeige in Plan- und Letztes-Mal-Teil, Wert konsistent mit `ActiveSetCard`
- [ ] Bodyweight-Übung: keine Zeile, kein Layout-Sprung
- [ ] Superset-Pause: unverändertes Verhalten (keine Gewichtszeile)
- [ ] Freies Training ohne `sourceTrainingPlan`: nur `Plan: X kg`, kein „Letztes Mal"
- [ ] Regressionen in angrenzenden Screens (v. a. `ActiveSetCard`, `RIRInputSheet`) prüfen

## Overall Assessment

Sauber und exakt nach Plan umgesetzt. Alle vier dokumentierten Konzept-Abweichungen wurden nicht nur behauptet, sondern gegen den tatsächlichen Quellcode verifiziert (`ExerciseSet.effectiveWeight`, `SetEditSheet.saveChanges`, `LastSessionReferenceCalcEngine.Reference.weight`, `ActiveSetCard.formatWeight`/`formattedLastWeight`) — die Symmetrie zwischen Plan- und Letztes-Mal-Zweig, die der ganze Grund für Abweichung 1 war, hält tatsächlich. Das explizit benannte Performance-Risiko (`heroCard` sekündlich neu ausgewertet) ist korrekt als reiner Cache-Lookup gelöst, die Cache-Wärme-Behauptung aus dem Plan-Risiko-Abschnitt ist ebenfalls verifiziert. Superset-Zweig strukturell unberührt, Bodyweight-Fall ohne Leerraum-Artefakt, Dateigröße weit unter Ziel, keine Force-Unwraps/TODOs. Die zwei Findings sind beide Info-Level und nicht blockierend (Dezimaltrenner ist bewusst identisch zu `ActiveSetCard`, `exerciseName` vs. `exerciseNameSnapshot` ist vorbestehend und außerhalb des Scopes).

Ein starker Senior/Staff Engineer würde das genehmigen. Offen bleibt ausschließlich die manuelle Simulator-/Build-Verifikation, die laut Plan bewusst dem Quality Gate/User zugewiesen wurde und durch statische Analyse nicht ersetzbar ist.

## Standard

Frage beantwortet: Ja — ein Senior/Staff Engineer würde diesen Change in der vorliegenden Form genehmigen, vorbehaltlich der noch ausstehenden manuellen Verifikation im Simulator.

---

**Relevante Pfade:**
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/RestTimerCardContainer.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Models/Core/ExerciseSet.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Components/SetEditSheet.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Services/Calculation/LastSessionReferenceCalcEngine.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift`
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift`
- `/Users/bartosz/Developments/MotionCore/tasks/current.md`
