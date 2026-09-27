# RestTimer zeigt Gewicht der nächsten Übung

**Complexity:** Medium

> Quelle: `Documentation/Concepts/MotionCore_RestTimer_Concept_2026-09-10.md` (v1.0, Status „Bereit für motioncore-developer").
> Dieser Plan übernimmt AP 1–3 des Konzepts und korrigiert vier Punkte, die gegen den Code-Stand geprüft wurden (siehe „Abweichungen vom Konzept").

## Summary

Während der Pause zeigt die `RestTimerCard` unter „Nächster: Satz X von Y" eine zusätzliche, dezente Zeile mit dem Plan-Gewicht des nächsten Satzes und — sofern eine gegatete Last-Session-Referenz existiert — dem zuletzt verwendeten Gewicht. Reines UI-Wiring auf bestehenden Feldern und einem bereits gefüllten Cache: kein Modell-Change, keine Migration, keine CalcEngine-Änderung.

**Warum Medium und nicht Small:** Nur ~40 additive Zeilen über 3 Dateien, aber der Plan braucht Scope-, Risiko- und Open-Questions-Abschnitte für die gefundenen Konzept-Abweichungen (unilaterale Gewichts-Semantik, Formatierungs-Inkonsistenz zur `ActiveSetCard`). Im Compact-Format hätten diese Informationen keinen Platz und würden verloren gehen.

## Scope

**Included**
- Neue Anzeige-Zeile im `nextExerciseName`-Zweig von `RestTimerCard.nextInfo`.
- Durchreichen von Plan-Gewicht, Unilateral-Flag und Last-Session-Referenz über `RestTimerCardContainer` bis `ActiveWorkoutView.heroCard`.
- Erweiterung aller bestehenden Preview-Instanzen + ein neuer Preview-Block für die neuen Fälle.

**Explicitly excluded**
- **Superset-Zweig (`supersetNextRoundNames`) bleibt unverändert** — mehrere Übungen als „Nächstes" brauchen eine eigene Konzeption (Konzept §3 + §7).
- **Abschnitt 7 des Konzepts ist nicht Teil dieses Tasks:** weder der geteilte `WeightDisplayFormatter`/`AppFormatter` (die „2× X kg"-Logik bleibt bewusst dupliziert, Refactor = eigenes Ticket) noch die Superset-Gewichtsanzeige.
- Keine Wiederholungen in der Zeile (nur Gewicht, Konzept §3).
- Bodyweight-Übungen bekommen **keine** „Körpergewicht"-Zeile — die Zeile entfällt komplett (Konzept §3).
- Kein Eingriff in `SetManager`, `LastSessionReferenceCalcEngine`, `RestTimerManager` oder das Gating der Referenz.

## Affected Files

- `MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift` — 3 neue Properties, bedingte Text-Zeile in `nextInfo`, 2 private Helper, Previews.
- `MotionCore/Views/Workouts/Active/Components/RestTimerCardContainer.swift` — neue Property `lastSessionReference`, erweiterter `RestTimerCard`-Aufruf.
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `heroCard` (Z. 932–948): neuer Parameter am `RestTimerCardContainer`-Aufruf.

## Abweichungen vom Konzept (gegen Code verifiziert)

1. **`nextPlanWeightPerSide` entfällt — stattdessen `ExerciseSet.effectiveWeight`.**
   Verifiziert (`ExerciseSet.swift:166-168`): `effectiveWeight` existiert bereits und liefert `weightPerSide > 0 ? weightPerSide * 2 : weight` — also immer das Gesamtgewicht beider Seiten. `weight` ist bei unilateralen Sätzen das **Gesamtgewicht**, `weightPerSide` ein abgeleiteter Spiegelwert, der 0 sein kann, wenn der Satz nie über `SetEditSheet` bearbeitet wurde.
   Folge im Konzept-Vorschlag: Der Plan-Zweig hätte bei `weightPerSide == 0` den Gesamtwert gezeigt (`Plan: 80 kg`), der Zuletzt-Zweig aber immer halbiert (`Zuletzt: 2× 41,25 kg`) — asymmetrisch und irreführend.
   Korrektur: `nextPlanWeight` wird mit `currentSet?.effectiveWeight ?? 0` gefüllt, beide Zweige nutzen **denselben** Formatierungs-Helper. Die Asymmetrie ist damit konstruktiv unmöglich, und es sind 3 statt 4 neue Properties.

2. **Unilateral-Erkennung zweiquellig.** `ActiveSetCard` prüft `set.isUnilateralSnapshot || (exercise?.isUnilateral ?? false)`. Der Konzept-Vorschlag prüft nur den Snapshot — ein Satz mit leerem/falschem Snapshot, aber unilateraler `exercise`-Relation würde in der `ActiveSetCard` „2×" zeigen und in der `RestTimerCard` nicht. Container übernimmt die zweiquellige Prüfung.

3. **Zahlformat + Label an `ActiveSetCard` angeglichen (User-Entscheidung).** Konzept §2 zeigt `Plan: 80.0 kg · Zuletzt: 82.5 kg`; stattdessen wird das getrimmte Zahlformat der `ActiveSetCard.formatWeight` (`80 kg` / `82,5 kg`) **und** deren Wortlaut `„Letztes Mal: …"` übernommen: `Plan: 80 kg · Letztes Mal: 82,5 kg`.

4. **Previews: alle 3 bestehenden Instanzen sind betroffen.** Das Konzept spricht nur von „ergänzen". Da die neuen Properties `let` ohne Default sind, müssen alle drei bestehenden `RestTimerCard(...)`-Aufrufe im Preview-Block nachgezogen werden; die neuen Fälle kommen in einen **zweiten** `#Preview`-Block (der bestehende VStack würde sonst über die Preview-Höhe hinauslaufen).

**Keine weiteren Call-Sites gefunden:** `RestTimerCardContainer` wird ausschließlich in `ActiveWorkoutView.heroCard` (Z. 932) verwendet, `RestTimerCard` nur im Container + 3 Preview-Instanzen in der eigenen Datei. Vor AP 1 einmal `rg "RestTimerCard(Container)?\("` laufen lassen; zusätzlich sind die neuen `let`-Properties ohne Default selbst das Sicherheitsnetz (jede übersehene Call-Site = Compile-Fehler).

## Risks

- **Ad-hoc-Sessions ohne Plan zeigen nie „Zuletzt".** `SetManager.refreshLastSessionReference` steigt früh aus, wenn `session.sourceTrainingPlan` nil oder ohne passende Template-Sätze ist → `cachedLastSessionReferences[groupKey] = [:]`. Graceful (nur `Plan: …`), aber bewusst so und beim Testen nicht als Bug fehldeuten.
- **Cache-Wärme ist gegeben, aber nicht neu zu bauen.** `lastSessionReference(for:)` ist ein reiner Dictionary-Lookup in `cachedLastSessionReferences`. Der Cache wird in `onAppear` für **alle** groupKeys gefüllt, bei `exerciseListRefreshID` erneut für alle und bei `selectedExerciseKey`-Wechsel für den neuen Key. Damit ist auch der erste Satz der **nächsten** Übung abgedeckt. In `heroCard` darf deshalb ausschließlich der Lookup stehen — `heroCard` wird durch `@StateObject restTimerManager` sekündlich neu ausgewertet; jede Berechnung über Sessions/Fetches an dieser Stelle wäre ein Performance-Bug.
- **Zeitbasierter nächster Satz:** hat `weight == 0` und fällt automatisch durch den `> 0`-Guard (keine Zeile). **Keinen zusätzlichen `isTimeBased`-Check einbauen** — das würde die Invariante duplizieren.
- **Superset-Regression:** Die neue Zeile liegt ausschließlich im `else if let exerciseName …`-Zweig. Der Superset-Zweig wird nicht angefasst; nach der Änderung visuell gegenprüfen, dass dort nichts erscheint.
- **Keine Daten-/CloudKit-Risiken:** keine neuen Felder, kein `AppSchema`-Eingriff, kein `ExerciseSetSnapshot`-Sync nötig, kein neuer Shared-Type.
- **Datei-Größe:** `RestTimerCard.swift` 189 → ca. 230 Zeilen, klar unter dem 400-Zeilen-Ziel.

## Implementation Steps

Alle drei APs hängen linear voneinander ab (Compile-Kette) → ein gemeinsames STOPP-Gate am Ende, ein Commit.

### AP 1 — `RestTimerCard.swift`

- [x] **1a — Properties.** Nach `let supersetNextRoundNames: [String]?` drei Properties ergänzen, mit deutschen Kommentaren:
      `let nextPlanWeight: Double` (Gesamtgewicht beider Seiten, 0 = Körpergewicht/unbekannt),
      `let nextIsUnilateral: Bool`,
      `let nextLastUsedWeight: Double?` (nil = keine gegatete Referenz; Gating liegt im `SetManager`).
- [x] **1b — Anzeige.** In `nextInfo` im Zweig `else if let exerciseName …` **innerhalb** des bestehenden `VStack(spacing: Space.s1)`, direkt nach der „Nächster: Satz X von Y"-`Text`, einfügen:
      `if let weightLine = formattedWeightLine { Text(weightLine).font(AppFont.caption).foregroundStyle(Theme.textTertiary) }`.
      Kein zusätzlicher Spacer/Padding — bei nil entsteht durch das `if` im VStack kein Leerraum-Artefakt.
- [x] **1c — Helper.** Im MARK-Block „Berechnete Properties" (vor `formatRestTime`) ergänzen:
      `formattedWeightLine: String?` → `guard nextPlanWeight > 0 else { return nil }`; Plan-Text über `weightText(nextPlanWeight)`; ohne Referenz (`nextLastUsedWeight == nil` oder `<= 0`) `"Plan: \(planText)"`, sonst `"Plan: \(planText) · Letztes Mal: \(weightText(last))"`.
      `weightText(_ total: Double) -> String` → `nextIsUnilateral ? "2× \(formatKg(total / 2)) kg" : "\(formatKg(total)) kg"`. **Beide Zweige müssen durch diesen einen Helper laufen** (siehe Abweichung 1).
      `formatKg(_ value: Double) -> String` → ganze Zahl ohne Nachkommastelle (`%.0f`), sonst `%.1f` — identische Semantik wie `ActiveSetCard.formatWeight`.
- [x] **1d — Previews.** Alle 3 bestehenden `RestTimerCard(...)`-Aufrufe im Block „Rest Timer Card" um die neuen Argumente erweitern (Bankdrücken-Karte: `nextPlanWeight: 80, nextIsUnilateral: false, nextLastUsedWeight: 82.5`; Superset- und Fallback-Karte: `0 / false / nil`).
      Zweiten Block `#Preview("Rest Timer — Gewichtszeile")` mit zwei Karten anlegen: unilateral (`nextPlanWeight: 40, nextIsUnilateral: true, nextLastUsedWeight: 42` → „Plan: 2× 20 kg · Letztes Mal: 2× 21 kg") und Bodyweight (`nextPlanWeight: 0` bei gesetztem `nextExerciseName` → keine Zeile).

### AP 2 — `RestTimerCardContainer.swift`

- [x] **2a — Property.** `let lastSessionReference: LastSessionReferenceCalcEngine.Reference?` **nach** `supersetNextRoundNames` und **vor** `onSkip` deklarieren (Memberwise-Init-Reihenfolge = Reihenfolge der Call-Site in AP 3).
- [x] **2b — Weiterreichen.** `RestTimerCard`-Aufruf um die drei Argumente ergänzen (Reihenfolge wie in AP 1a deklariert):
      `nextPlanWeight: currentSet?.effectiveWeight ?? 0`,
      `nextIsUnilateral: (currentSet?.isUnilateralSnapshot ?? false) || (currentSet?.exercise?.isUnilateral ?? false)`,
      `nextLastUsedWeight: lastSessionReference?.weight`.
      Kurzkommentar an `nextPlanWeight`, dass `effectiveWeight` bewusst statt `weight`/`weightPerSide` genutzt wird (Gesamtwert, symmetrisch zur Zuletzt-Zeile).

### AP 3 — `ActiveWorkoutView.swift`

- [x] **3a — Call-Site.** Im `heroCard` (Z. 932–948) nach `supersetNextRoundNames:` und vor `onSkip:` ergänzen:
      `lastSessionReference: setManager.cachedCurrentSet.flatMap { setManager.lastSessionReference(for: $0) },`.
      Bewusst hier und nicht im Container berechnet: der Container hat keinen `SetManager` und soll keine Business-Logik bekommen; der Aufruf ist ein O(1)-Cache-Lookup.
- [x] **3b — Build.** `Cmd+B` — der Build ist zugleich die Vollständigkeitsprüfung für übersehene Call-Sites (neue `let` ohne Default).

### STOPP-Gate

- [x] Code entspricht AP 1–3 inkl. der vier dokumentierten Abweichungen.
- [ ] Akzeptanzkriterien (unten) manuell durchgetestet. (offen — Simulator-Test durch Quality Gate / User)
- [x] Keine Abweichung von den Annahmen aus Konzept §3 ohne Rücksprache.

## Akzeptanzkriterien (Konzept Abschnitt 6, Label an ActiveSetCard angeglichen)

- [ ] Pause nach bilateralem Satz mit Plan-Gewicht > 0 → Zeile zeigt `Plan: X kg`
- [ ] Pause nach unilateralem Satz → Zeile zeigt `Plan: 2× X kg`
- [ ] Existiert eine gegatete Last-Session-Referenz für den nächsten Satz → Zeile zeigt zusätzlich `· Letztes Mal: …`
- [ ] Bodyweight-Übung (Gewicht 0) → Zeile wird komplett ausgeblendet, kein Leerraum-Artefakt
- [ ] Superset-Pause (nächste Runde) → unverändertes Verhalten, keine Regression
- [ ] Build ohne Warnings, Datei-Größe von `RestTimerCard.swift` bleibt unter 400 Zeilen

## Manual Verification

- [ ] Xcode-Build (`Cmd+B`) grün, keine neuen Warnings.
- [ ] Preview „Rest Timer Card" (3 Karten) rendert unverändert, Bankdrücken-Karte zeigt zusätzlich `Plan: 80 kg · Letztes Mal: 82,5 kg`.
- [ ] Preview „Rest Timer — Gewichtszeile": unilateral zeigt `Plan: 2× 20 kg · Letztes Mal: 2× 21 kg`, Bodyweight-Karte zeigt keine Zeile.
- [ ] Simulator, Training aus einem Plan mit Historie: Satz abschließen → Pausenkarte zeigt Plan-Gewicht des nächsten Satzes; Wert stimmt mit der `ActiveSetCard` nach Pausenende überein (Zahl **und** Format).
- [ ] Übergang **zwischen** zwei Übungen: letzter Satz Übung A abschließen → Pausenkarte zeigt Gewicht des ersten Satzes von Übung B (Cache für den neuen groupKey ist warm).
- [ ] Unilaterale Übung (z. B. Bulgarian Split Squat): „2× …" in Plan- und Zuletzt-Teil, beide Werte halbiert und konsistent zur `ActiveSetCard`-Zeile „Letztes Mal".
- [ ] Bodyweight-Übung (Klimmzüge, Gewicht 0): keine Zeile, Kartenhöhe/Abstände unverändert.
- [ ] Superset-Pause (nächste Runde): weiterhin nur „Nächste Runde" + Übungsnamen, keine Gewichtszeile.
- [ ] Zeitbasierte Übung als nächster Satz: keine Gewichtszeile, kein Layout-Sprung.
- [ ] Freies Training ohne `sourceTrainingPlan`: `Plan: X kg` erscheint, `Zuletzt:` fehlt — erwartetes Verhalten.

## Open Questions

Geklärt (User-Entscheidung 2026-09-10): Zahlformat + Label folgen `ActiveSetCard` — `Plan: 80 kg · Letztes Mal: 82,5 kg` statt Konzept-Vorschlag `Plan: 80.0 kg · Zuletzt: 82.5 kg`.

## Relevante Pfade

- `MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift`
- `MotionCore/Views/Workouts/Active/Components/RestTimerCardContainer.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift`
- `MotionCore/Services/Calculation/LastSessionReferenceCalcEngine.swift`
- `MotionCore/Models/Core/ExerciseSet.swift` (Beleg: `effectiveWeight` existiert bereits, Z. 166-168)
- `MotionCore/Views/Workouts/Components/SetEditSheet.swift` (Beleg für „`weight` = Gesamtgewicht")

**Umsetzungsmodus:** Single Pass, ein Commit, ein STOPP-Gate am Ende (AP 1–3 sind eine Compile-Kette).
**Hauptrisiken:** unilaterale Gewichts-Semantik (durch `effectiveWeight` entschärft), stumme Nil-Referenz bei Sessions ohne `sourceTrainingPlan`, versehentliches Rechnen statt Cache-Lookup im sekündlich neu ausgewerteten `heroCard`.
**Offene Frage geklärt:** Zahlformat + Label folgen `ActiveSetCard` (`Letztes Mal:`).

## Progress (2026-09-10, Developer Agent)

**Erledigt:** AP 1 (a–d), AP 2 (a–b), AP 3 (a–b) vollständig umgesetzt, wie im Plan spezifiziert (inkl. aller 4 dokumentierten Abweichungen vom Konzept). Vorab-Suche nach weiteren Call-Sites bestätigt: keine außer den 3 Previews in `RestTimerCard.swift` und `ActiveWorkoutView.heroCard`.

**Geänderte Dateien:**
- `MotionCore/Views/Workouts/Active/Components/RestTimerCard.swift` (189 → 251 Zeilen, unter 400-Zeilen-Ziel)
- `MotionCore/Views/Workouts/Active/Components/RestTimerCardContainer.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

**Build:** `xcodebuild -scheme "MotionCore iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug` → `** BUILD SUCCEEDED **`. Keine neuen Warnings; die 8 vorhandenen Warnings in `LiveActivityCtrl.swift` (`#IsolatedConformances`) sind vorbestehend und unabhängig von dieser Änderung.

**Offen:** Manuelle Simulator-Verifikation (Akzeptanzkriterien + Manual Verification-Checklisten) — nicht Teil des Developer-Scopes, folgt im Quality Gate.
