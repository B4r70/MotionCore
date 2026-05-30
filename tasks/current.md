# In-Session Supersets

**Komplexität:** Large · **Steps:** 7 · **STOPP-Gates nach Schritt 1, 2, 3 & End-to-End**

## Summary

Im aktiven Workout (`ActiveWorkoutView`) können 2–5 aufeinanderfolgende, noch nicht gestartete Übungen per Multi-Select zu einem Superset zusammengefasst werden. Pausen werden automatisch auf 0 s zwischen den Übungen einer Runde gesetzt, der Plan bleibt unverändert.

## Scope

**Included**
- Session-API `createSuperset(fromGroupIndices:)` + `removeFromSuperset(groupAt:)` auf `StrengthSession`
- Multi-Select-Modus in `ExercisesOverviewCard` (Bolt-Button, Selection-Visuals, Eligibility-Checks)
- Floating Action Bar in `ActiveWorkoutView` über `bottomActionBar`
- Pure Berechnungs-Helper `SupersetSelectionHelper`
- Cache-Refresh nach create/remove über `setManager.rebuildGroupedCaches()` + `refreshSetCaches()`
- Mehrere Supersets pro Session (eigene UUID je Superset)

**Explizit ausgeschlossen**
- Plan-Sync (kein `PlanUpdateProposal` für Session-Supersets)
- Konfigurierbare Pausenzeit innerhalb des Supersets
- Lückenhafte Auswahl
- Schema-Migration (`ExerciseSet.supersetGroupId` existiert bereits)

## Betroffene Dateien

| Datei | Status | Aktuelle Zeilenzahl | Aktion |
|-------|--------|---------------------|--------|
| `MotionCore/Models/Core/StrengthSession.swift` | Existiert | 283 L | Extension am Dateiende |
| `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` | Existiert | 583 L | Bolt-Button, Bindings, Visuals |
| `MotionCore/Views/Workouts/Active/Components/SupersetSelectionHelper.swift` | **Neu** | — | Pure Struct für Eligibility-Logik |
| `MotionCore/Views/Workouts/Active/Components/ActiveWorkoutSupersetActionBar.swift` | **Neu** | — | Floating Action Bar (extrahiert, da ActiveWorkoutView 931 L) |
| `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` | Existiert | 931 L | State + Verdrahtung (minimal) |

## Risiken

- **`.contextMenu` Conditional-Falle (lessons.md):** "Aus Superset entfernen" darf NICHT via `if ... { .contextMenu }` angehängt werden — collabiert HStack-Inhalt. Stattdessen: `.contextMenu { if isSupersetMember { Button(...) } }` — Modifier unconditional, Inhalt conditional.
- **`ActiveWorkoutView` >800 L:** Action Bar MUSS in eigene Datei — kein optionales Cleanup.
- **`restSeconds` destruktiv:** Original-Werte werden nicht gespeichert — `removeFromSuperset` stellt sie nicht wieder her (Konzept-konform).
- **Tap-Verhalten:** Normal-Modus löst `onToggleExpand()` aus (Accordion-Open), nicht `onSelectAsActive`. Selection-Modus muss diesen Pfad ersetzen, ohne ihn zu verändern.
- **`safe:`-Subscript:** Existiert bereits in ExercisesOverviewCard + ActiveWorkoutView — nicht erneut definieren.

## Implementierungs-Schritte

- [x] **Step 1 — Session-API** (`StrengthSession.swift`): Extension mit `createSuperset(fromGroupIndices:)` und `removeFromSuperset(groupAt:)`. Referenz: `TrainingPlan.swift` Z. 280–322. Eligibility-Check: `groups[idx].allSatisfy { !$0.isCompleted }`. Pausen-Anpassung: `restSeconds = 0` für alle Indizes außer dem letzten (letzte Übung pro Runde behält Original). Kein `context.save()`. **→ STOPP-Gate 1**

- [x] **Step 2 — `SupersetSelectionHelper.swift` anlegen**: Pure Struct `SupersetSelectionHelper(groupedSets: [[ExerciseSet]])` mit Methoden `isEligible(at:)`, `isInOtherSuperset(at:)`, `eligibleCount`, `isContiguous(_:)`, `canCreateSuperset(from:)`. Eigene Datei mit korrektem Header-Block (Datum 26.05.2026).

- [x] **Step 3 — `ExercisesOverviewCard` — State als Bindings + Bolt-Button**: Direkt `@Binding var isSupersetSelectionMode: Bool` + `@Binding var selectedGroupIndicesForSuperset: Set<Int>` (kein `@State`-Zwischenschritt). Callbacks `onRemoveFromSuperset: ((Int) -> Void)? = nil`. Bolt-Button im Header rechts neben Sort/Add-Button: disabled wenn `helper.eligibleCount < 2 || isSortMode`. Mutex via `.onChange`: Sort-Modus beendet Selection und umgekehrt. **→ STOPP-Gate 2**

- [x] **Step 4 — `ExerciseOverviewRow` Selection-Visuals**: Neue Parameter `isSupersetSelectionMode`, `isSelectedForSuperset`, `isEligibleForSuperset`, `isInOtherSuperset`, Callback `onToggleSupersetSelection`. Overlays topTrailing: Checkmark-Badge (selected), Schloss-Icon (not eligible), Link-Icon (in other superset). Border 2 pt Color.blue wenn selected. `opacity(0.5)` wenn not eligible. Tap-Handler erweitern: im Selection-Modus toggle nur wenn eligible + nicht in anderem Superset, sonst Haptic `.rigid`. Normal-Modus: unverändert. `.contextMenu { if isSupersetMember { Button("Aus Superset entfernen") } }` unconditional anhängen. **→ STOPP-Gate 3**

- [x] **Step 5 — `ActiveWorkoutSupersetActionBar.swift` anlegen**: View mit Parametern `selectedCount: Int`, `canCreate: Bool`, `hasGap: Bool`, `onCancel`, `onCreate`. Layout: HStack mit Label + Hinweistext ("Mindestens 2 für ein Superset" / "Nur aufeinanderfolgende Übungen" orange), Abbrechen-Button, "Superset"-Capsule-Button. `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))`, Stroke 0.8pt weiß, Shadow.

- [x] **Step 6 — `ActiveWorkoutView` verdrahten**: `@State private var isSupersetSelectionMode: Bool = false`, `@State private var selectedGroupIndicesForSuperset: Set<Int> = []`. Bindings an `ExercisesOverviewCard` + `onRemoveFromSuperset`-Callback. In `body`: `ActiveWorkoutSupersetActionBar` über `bottomActionBar` mit `.transition(.move(edge: .bottom).combined(with: .opacity))` + `.animation(.spring(...), value: isSupersetSelectionMode)`. Methoden `createSupersetFromSelection()` + `removeFromSupersetAtIndex(_:)` (session-API → save → rebuildGroupedCaches → refreshSetCaches → State-Reset → Haptic). **→ STOPP-Gate 5 (End-to-End)**

- [x] **Step 7 — Cleanup**: Deutschen UI-Strings prüfen, keine Force-Unwraps (außer durch `guard` geschütztem `sorted.last!`), MARK-Sections konsistent, File-Header in neuen Dateien. Edge Cases: Pause-Timer läuft weiter, Sort/Select-Mutex.

## Manuelle Verifikation

- [ ] **Build:** Xcode `Cmd+B` ohne neue Warnings
- [ ] **Test A — Standard:** 5-Übungen-Workout, alle als Superset; Action Bar erscheint über `bottomActionBar`; nach "Superset" visuell verbunden; `RestTimerCard` zeigt Folge-Übungen
- [ ] **Test B — Eligibility:** Übung 1 abgeschlossen → Schloss-Icon, Tap `.rigid` Haptic, restliche Übungen wählbar
- [ ] **Test C — Lücken:** Übungen 1+3 wählen → "Nur aufeinanderfolgende Übungen" orange, Button disabled
- [ ] **Test D — Mehrere Supersets:** 1+2 als Superset, danach 4+5; beide unabhängig, eigene `supersetGroupId`
- [ ] **Test E — Auflösen:** Kontextmenü → "Aus Superset entfernen"; bei <2 restlichen Übungen gesamtes Superset aufgelöst
- [ ] **Test F — Plan unverändert:** Nach Workout-Ende Plan-Detail prüfen; kein Superset im Template; PlanUpdateSheet zeigt keinen Superset-Diff
- [ ] **Test G — `.contextMenu` Layout-Regression:** Cards im Normalmodus zeigen alle HStack-Elemente vollständig
- [ ] **Test H — Mutex:** Sort/Select schließen sich aus
- [ ] **Test I — Pause:** Bolt-Modus während Pause-Timer → Timer läuft weiter
- [ ] **Test J — restSeconds nach Auflösen:** Zwischen-Sätze behalten `restSeconds = 0` (Konzept-konform)
- [ ] **Test K — Live Activity + Watch:** Keine Regression

---

## Implementierungs-Fortschritt

**Datum:** 26.05.2026

**Abgeschlossene Steps:** 1, 2, 3, 4, 5, 6, 7

**Geänderte Dateien:**
- `MotionCore/Models/Core/StrengthSession.swift` — Extension `// MARK: - Superset-API` am Dateiende hinzugefügt (283 → 354 L)
- `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` — Bindings, Bolt-Button, Row-Visuals, contextMenu, LongPress-Guard (583 → 713 L)
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — @State, Bindings-Durchreichung, supersetActionBar, createSupersetFromSelection, removeFromSupersetAtIndex (931 → 1009 L)

**Neue Dateien:**
- `MotionCore/Views/Workouts/Active/Components/SupersetSelectionHelper.swift` (neu, 53 L)
- `MotionCore/Views/Workouts/Active/Components/ActiveWorkoutSupersetActionBar.swift` (neu, 77 L)

**Abweichungen vom Plan:**
1. Bolt-Button als Toggle implementiert (`isSupersetSelectionMode.toggle()`) statt reines Set-auf-true — ehrlicher für den User, da der Button im Selection-Modus sichtbar bleibt
2. `+Übung`-Button wird im Selection-Modus ausgeblendet (plan: nur im Sort-Modus; ergibt UX-Sinn, da Selection-Modus eine exclusive Aktion ist)
3. Sort-Button wird im Selection-Modus ausgeblendet (plan: nur Mutex via State; verhindert verwirrende simultane Buttons)
4. Accordion-Detail wird im Selection-Modus nicht ausgefahren (`isExpanded && !isSupersetSelectionMode`)
5. LongPress-Löschen im Selection-Modus geblockt (defensiv, nicht im Plan)
6. Plural-Handling in der Action Bar: "1 Übung" / "N Übungen" (plan: immer "N Übungen")
7. Dritter Zustand in Action Bar: "Superset erstellen" wenn >=2 eligible und contiguous aber Button enabled
8. `createSupersetFromSelection()` ruft nicht `watchBridge.sendState()`/`liveActivity.syncDebounced()` auf — entspricht dem Pattern von reorder/delete; Watch zeigt ggf. bis zum nächsten Satz-Abschluss alten Zustand

**Beibehaltene Code-Smells (nicht angefasst):**
- `ActiveWorkoutView.swift` ist auf 1009 L angewachsen (Grenze 1000 L per Plan, harter Stopp war aber auf FAB-Extraktion beschränkt — die ist erfolgt)
- `ExercisesOverviewCard.swift` bei 713 L (Plan-Kandidat für `// MARK: - Superset`-Extraktion ab 700 L, aber nicht gefordert)

---

## Review-Fixes L1-Watch-002 + L1-Watch-004

**Datum:** 29.05.2026

**Abgeschlossene Steps:** L1-Watch-002, L1-Watch-004

**Geänderte Dateien:**
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — Z. 122–135 (L1-Watch-002) + Z. 188–212 (L1-Watch-004)

**L1-Watch-002:** `restEndDate`/`isResting` werden jetzt nur bei State-Messages (erkennbar am `workoutState`-Key) überschrieben. Lifecycle-Messages (start/stop/pause/resume/transition/snapshot/heartbeat) lassen den Rest-Timer-State unverändert. Invariante vor Umsetzung verifiziert: `sendWorkoutState()` enthält immer `workoutState`, `sendLifecycleMessage()` niemals.

**L1-Watch-004:** Reply-Variante von `didReceiveMessage` delegiert jetzt alle Nicht-Snapshot-Nachrichten via `self.session(session, didReceiveMessage:)` an den No-Reply-Pfad und quittiert danach mit `replyHandler([:])`. Early return bei `requestSnapshot` verhindert Doppelverarbeitung durch `handleHealthLifecycle`.

**Offen:** Build-Verifikation durch Bartosz (STOPP-Gate).

---

## Review-Fixes L1-Watch-001 + L1-Watch-003

**Datum:** 29.05.2026

**Abgeschlossene Steps:** L1-Watch-001, L1-Watch-003

**Geänderte Dateien:**
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — Z. 39–47, 66–67 (L1-Watch-001) + Z. 162, 234, 263, 274 (L1-Watch-003)

**L1-Watch-001 (objectWillChange-Forwarding):** `workoutManager` hat jetzt einen `didSet`, der via `AnyCancellable` (`workoutManagerObservation`) die inneren `objectWillChange`-Ereignisse von `WatchWorkoutManager` an den äußeren `WatchSessionManager` weiterleitet. `workoutManagerObservation` wird bei jeder Neuzuweisung ersetzt — auch beim Nil-Setzen. Das Cancellable liegt als `private var workoutManagerObservation: AnyCancellable?` in den Private Properties.

**L1-Watch-003 (isTearingDown-Flag):** Neues `private var isTearingDown: Bool = false`. Gesetzt am Anfang von `stopHealthTracking` (vor `guard`) und von `discardHealthTracking`. Gelöscht am Anfang von `startHealthTracking`. Self-Healing-Guard erweitert auf `&& !self.isTearingDown`. Kein Reset auf `.idle` — überlebt den trailing `paused`-Push nach Discard.

**Offen:** Build-Verifikation durch Bartosz (STOPP-Gate).

---

## Review-Fixes L1-Watch-007 + L1-Watch-009

**Datum:** 29.05.2026

**Abgeschlossene Steps:** L1-Watch-007, L1-Watch-009

**Geänderte Dateien:**
- `MotionCore/Views/Workouts/Active/ViewModel/WatchBridge.swift` — Z. 74–87 (L1-Watch-007)
- `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` — Z. 17, 27–36 (L1-Watch-009)

**L1-Watch-007 (Satz N+1/N):** `completedInGroup` (COUNT aller abgeschlossenen Sätze) ersetzt durch `displaySetIndex` (INDEX des nächsten offenen Satzes via `firstIndex(where: { !$0.isCompleted })`). Alle erledigt → clampen auf `max(0, totalInGroup - 1)`. `completedInGroup`-Variable entfernt (kein toter Code).

**L1-Watch-009 (Doppelklick Pause):** `@State private var isPauseLocked = false` hinzugefügt. Pause/Resume-Button wrapped mit guard + 500 ms Debounce-Lock via `Task.sleep`. `.disabled(isPauseLocked)` auf dem Button. `completeSet`-Button unberührt.

**Offen:** Build-Verifikation durch Bartosz (STOPP-Gate).

---

## Review-Fixes L1-Watch-005 + L1-Watch-008

**Datum:** 29.05.2026

**Abgeschlossene Steps:** L1-Watch-005, L1-Watch-008

**Geänderte Dateien:**
- `MotionCore/Services/Watch/WatchMessageKeys.swift` — Z. 57–65: `WatchAppGroup`-Enum hinzugefügt (SSoT für App-Group-Identifier)
- `MotionCore/Services/Watch/WatchComplicationService.swift` — Z. 21–32: `private static let appGroup` entfernt, `WatchAppGroup.defaults` verwendet
- `MotionCoreWatch Watch App/Complications/StreakComplication.swift` — Z. 27: `sharedDefaults` delegiert an `WatchAppGroup.defaults`
- `MotionCoreWatch Watch App/Complications/WeeklyProgressComplication.swift` — Z. 27: `sharedDefaults` delegiert an `WatchAppGroup.defaults`
- `MotionCoreWatch Watch App/Views/IdleView.swift` — Z. 17–27: `sharedDefaults` + 3 computed properties ersetzt durch `@AppStorage`-Properties (L1-Watch-008); body unverändert

**L1-Watch-005 (SSoT App-Group):** `WatchAppGroup.identifier` + `WatchAppGroup.defaults` in `WatchMessageKeys.swift` definiert (in beiden Targets kompiliert via `membershipExceptions`). 4 Literal-Stellen aus Review bereinigt.

**L1-Watch-008 (IdleView Re-Render):** `@AppStorage(key, store: WatchAppGroup.defaults)` für `streakCount`, `weeklyCount`, `weeklyGoalRaw`. `weeklyGoal` bleibt als computed wrapper mit `> 0 ? : 5` Fallback.

**Nicht berührt (Entscheidung ausstehend):**
- (keine mehr)

**Offen:** Build-Verifikation durch Bartosz (STOPP-Gate).

---

## Review-Fix L1-Watch-006

**Datum:** 29.05.2026

**Abgeschlossene Steps:** L1-Watch-006

**Geänderte Dateien:**
- `MotionCore/Views/Workouts/Active/ViewModel/WatchBridge.swift` — Z. 73–75: `exerciseName` durch Snapshot-Fallback-Pattern ersetzt

**L1-Watch-006 (exerciseNameSnapshot statt exerciseName):** `grouped[safe: exIdx]?.first?.exerciseName ?? ""` ersetzt durch zweistufiges Pattern: `firstSet?.exerciseNameSnapshot.isEmpty == false ? firstSet!.exerciseNameSnapshot : (firstSet?.exerciseName ?? "")`. Entspricht dem Fallback-Pattern, das CLAUDE.md und der Review fordern.

**Offen:** Build-Verifikation durch Bartosz (STOPP-Gate).

---

## Review-Fixes L1-Watch-005 + L1-Watch-008 (Fortsetzung — Items 1–3)

**Datum:** 29.05.2026

**Abgeschlossene Steps:** Item 1 (import Foundation), Item 2 (MotionCoreApp literal), Item 3 (WidgetsExtension target membership + WidgetDataStore literal)

**Geänderte Dateien:**
- `MotionCore/Services/Watch/WatchMessageKeys.swift` — `import Foundation` nach Header-Block eingefügt (Z. 16), vor erstem `// MARK:`
- `MotionCore/App/MotionCoreApp.swift` — Z. 37: `appGroupID` verwendet jetzt `WatchAppGroup.identifier`
- `MotionCore.xcodeproj/project.pbxproj` — `Services/Watch/WatchMessageKeys.swift` zu WidgetsExtension `membershipExceptions` hinzugefügt; `plutil -lint` → OK
- `MotionCore/Services/Widget/WidgetDataStore.swift` — Z. 23: `static let appGroup` verwendet jetzt `WatchAppGroup.identifier`

**Mechanismus:** Projekt nutzt `PBXFileSystemSynchronizedBuildFileExceptionSet` (Xcode 16 Synchronized Groups), keine klassischen `PBXBuildFile`/`PBXSourcesBuildPhase`-Einträge. `WatchMessageKeys.swift` war bereits via `membershipExceptions` in MotionCoreWatch eingebunden — identisches Muster für WidgetsExtension angewendet.
