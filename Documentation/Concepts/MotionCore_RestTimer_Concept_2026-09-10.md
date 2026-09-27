# MotionCore — Konzept: RestTimer zeigt Gewicht der nächsten Übung

**Version:** 1.0
**Datum:** 10.09.2026
**Status:** Bereit für `motioncore-developer`
**Kontext:** Punkt 5/5 aus Feature-Session vom 10.09.2026 (Barto)

---

## 1. Problem / Ist-Zustand

Während der `RestTimerCard` (Pause zwischen Sätzen) sieht man aktuell nur Übungsname
und "Satz X von Y" des nächsten Satzes — kein Gewicht. Man muss raten oder aus dem
Kopf wissen, was als Nächstes ansteht.

Relevante bestehende Bausteine, die bereits existieren und nur verdrahtet werden
müssen:

- `SetManager.lastSessionReference(for:)` liefert eine gegatete
  `LastSessionReferenceCalcEngine.Reference?` (nur wenn ≥ 2 Work-Sets vom Plan
  abwichen — verhindert Rauschen bei Standard-Verläufen). Wird bereits in
  `ActiveSetCard` für die "Letztes Mal: …"-Zeile genutzt.
- `RestTimerCardContainer` hat `currentSet` (= Plan-Template des nächsten Satzes)
  bereits im Zugriff, ruft die Referenz aber nicht ab.
- `ExerciseSet` trägt `weight`, `weightPerSide`, `isUnilateralSnapshot` — exakt die
  Felder, die für die Anzeige gebraucht werden.

## 2. Ziel / Soll-Zustand

In `RestTimerCard.nextInfo` erscheint unter "Nächster: Satz X von Y" eine zusätzliche
Zeile mit:

- **Plan-Gewicht** des nächsten Satzes (aus `currentSet`)
- **Zuletzt verwendetes Gewicht** (aus `lastSessionReference`, sofern vorhanden)

Format bilateral: `Plan: 80.0 kg · Zuletzt: 82.5 kg`
Format unilateral: `Plan: 2× 20.0 kg · Zuletzt: 2× 21.0 kg`
Ohne Referenz: `Plan: 80.0 kg`

## 3. Entscheidungen & Annahmen

| Entscheidung | Begründung | Alternative, falls gewünscht |
|---|---|---|
| Bodyweight-Übungen (Gewicht 0 auf beiden Seiten) → Zeile komplett ausgeblendet | Während der Pause ist "kein Gewicht" keine Info, die Aufmerksamkeit verdient | Wie `ActiveSetCard`: explizit "Körpergewicht" anzeigen |
| Superset-Zweig (`supersetNextRoundNames`) bleibt unverändert | Mehrere Übungen als Nächstes → eigene Konzeption nötig, kein Teil dieses Scopes | Eigenes Folge-Ticket |
| Nur Gewicht, keine Wiederholungen | Explizite Anforderung | — |
| Kein neuer Shared-Formatter in diesem Scope | Kleine, in sich geschlossene Änderung; Refactor separat behandeln (siehe Abschnitt 6) | Bei AP 1 direkt mit erledigen |

## 4. Betroffene Dateien

- `RestTimerCard.swift`
- `RestTimerCardContainer.swift`
- `ActiveWorkoutView.swift`

Kein Modell-Change, keine Migration, keine CalcEngine-Änderung — reines
UI+Wiring auf bestehenden Feldern.

---

## 5. Implementierungsplan

Alle drei Schritte hängen linear voneinander ab (kein Parallelisierungspotential),
daher ein gemeinsames STOPP-Gate am Ende statt einzelner Gates pro AP.

### AP 1 — RestTimerCard.swift

Neue Properties:

```swift
let nextPlanWeight: Double          // 0 = kein Gewicht / unbekannt
let nextPlanWeightPerSide: Double   // > 0 nur bei unilateral
let nextIsUnilateral: Bool
let nextLastUsedWeight: Double?     // nil = keine Referenz (Gating kommt aus SetManager)
```

Erweiterung in `nextInfo` (nur im `nextExerciseName`-Zweig, nicht im Superset-Zweig),
direkt nach der bestehenden "Nächster: Satz X von Y"-Zeile:

```swift
if let weightLine = formattedWeightLine {
    Text(weightLine)
        .font(AppFont.caption)
        .foregroundStyle(Theme.textTertiary)
}
```

Neue private Helpers:

```swift
private var formattedWeightLine: String? {
    guard nextPlanWeight > 0 || nextPlanWeightPerSide > 0 else { return nil }

    let planText = nextIsUnilateral && nextPlanWeightPerSide > 0
        ? "2× \(formatKg(nextPlanWeightPerSide))"
        : formatKg(nextPlanWeight)

    guard let last = nextLastUsedWeight, last > 0 else {
        return "Plan: \(planText)"
    }

    let lastText = nextIsUnilateral
        ? "2× \(formatKg(last / 2))"
        : formatKg(last)

    return "Plan: \(planText) · Zuletzt: \(lastText)"
}

private func formatKg(_ value: Double) -> String {
    String(format: "%.1f kg", value)
}
```

Preview-Block am Dateiende um mindestens einen Fall mit `nextLastUsedWeight != nil`
und einen unilateralen Fall ergänzen.

### AP 2 — RestTimerCardContainer.swift

Neue Property:

```swift
let lastSessionReference: LastSessionReferenceCalcEngine.Reference?
```

`RestTimerCard`-Aufruf erweitern:

```swift
RestTimerCard(
    remainingSeconds: restTimerManager.remainingSeconds,
    targetSeconds: completedSet.restSeconds,
    onSkip: onSkip,
    onAdjust: onAdjust,
    nextExerciseName: currentSet?.exerciseName,
    nextSetNumber: currentSet?.setNumber,
    totalSetsForExercise: setsForCurrentExercise,
    supersetNextRoundNames: supersetNextRoundNames,
    nextPlanWeight: currentSet?.weight ?? 0,
    nextPlanWeightPerSide: currentSet?.weightPerSide ?? 0,
    nextIsUnilateral: currentSet?.isUnilateralSnapshot ?? false,
    nextLastUsedWeight: lastSessionReference?.weight
)
```

### AP 3 — ActiveWorkoutView.swift

Im `heroCard`-Aufruf von `RestTimerCardContainer` (Rest-Branch, `isResting == true`)
den neuen Parameter ergänzen:

```swift
let restTimer = RestTimerCardContainer(
    restTimerManager: restTimerManager,
    completedSet: completedSet,
    currentSet: setManager.cachedCurrentSet,
    setsForCurrentExercise: setsForCurrentExercise,
    supersetNextRoundNames: completedSet.supersetGroupId != nil
        ? setManager.supersetNextRoundNames(for: completedSet)
        : nil,
    lastSessionReference: setManager.cachedCurrentSet.flatMap {
        setManager.lastSessionReference(for: $0)
    },
    onSkip: {
        restTimerManager.skip()
        hapticGenerator.impactOccurred()
    },
    onAdjust: { delta in
        restTimerManager.adjust(delta: delta)
        liveActivity.syncDebounced(saveResume: saveResumeState)
    }
)
```

Alle übrigen Call-Sites von `RestTimerCardContainer` (falls vorhanden, z. B. Previews)
entsprechend nachziehen.

---

## 6. Akzeptanzkriterien

- [ ] Pause nach bilateralem Satz mit Plan-Gewicht > 0 → Zeile zeigt `Plan: X kg`
- [ ] Pause nach unilateralem Satz → Zeile zeigt `Plan: 2× X kg`
- [ ] Existiert eine gegatete Last-Session-Referenz für den nächsten Satz → Zeile
      zeigt zusätzlich `· Zuletzt: …`
- [ ] Bodyweight-Übung (Gewicht 0) → Zeile wird komplett ausgeblendet, kein Leerraum-Artefakt
- [ ] Superset-Pause (nächste Runde) → unverändertes Verhalten, keine Regression
- [ ] Build ohne Warnings, Datei-Größe von `RestTimerCard.swift` bleibt unter 400 Zeilen

## 7. Out of Scope / Follow-ups

- **Shared `WeightDisplayFormatter`**: Die "2× X kg"-Logik (Gewicht halbieren,
  per-Side anzeigen) ist nach diesem Change in mindestens fünf Dateien dupliziert
  (`SetPreviewRow`, `SetEditSheet`, `AddExerciseDuringWorkoutSheet`,
  `ActiveSetCard.formattedLastWeight`, jetzt `RestTimerCard`). Nach den
  Swift-Standards ("Multiple files use the same formatting logic → extract to a
  shared helper") ein guter Kandidat für `AppFormatter.swift` — separates Ticket,
  guter Anschlusspunkt bei Punkt 1 (reps pro Seite).
- **Superset-Gewichtsanzeige**: nächste Runde zeigt aktuell nur Übungsnamen, kein
  Gewicht — eigene Konzeption nötig (mehrere Übungen gleichzeitig).

---

## 8. STOPP-Gate

Freigabe erforderlich vor Merge:

- [ ] Code entspricht AP 1–3 wie oben spezifiziert
- [ ] Akzeptanzkriterien (Abschnitt 6) manuell durchgetestet
- [ ] Keine Abweichung von den dokumentierten Annahmen (Abschnitt 3) ohne Rücksprache

**Status:** 🔴 wartet auf Freigabe
