# In-Session-Supersets — Konzept v1

## Ziel

Im aktiven Workout (`ActiveWorkoutView`) Supersets aus zwei oder mehr
Übungen bilden, ohne den Trainingsplan dauerhaft zu verändern.

**Use Case (Barto):** Während des Trainings wird die Zeit knapp. Statt die
restlichen Einzelübungen abzubrechen, werden sie zu einem Superset
zusammengefasst, um die Pausenstruktur abzukürzen.

## Scope

**In Scope:**
- Multi-Select-Modus in `ExercisesOverviewCard` für Übungs-Auswahl.
- Floating Action Bar im Sichtfeld (über der `bottomActionBar`).
- Session-API `createSuperset(fromGroupIndices:)` und
  `removeFromSuperset(groupAt:)` auf `StrengthSession`.
- Automatische Pausen-Anpassung: alle Zwischen-Sätze bekommen
  `restSeconds = 0`, der letzte Satz der letzten Übung pro Runde behält
  seine Original-Pausenzeit.
- Mehrere unabhängige Supersets pro Session möglich.
- Cache-Refresh und Live-Update der Superset-Anzeige.

**Out of Scope (Phase 2 oder später):**
- Übernahme der Session-Supersets in den `TrainingPlan` (kein
  PlanUpdate-Vorschlag).
- Konfigurierbare Pausenzeit innerhalb eines Supersets
  (User-Feature-Wunsch, separat).
- Lückenhafte Auswahl (z.B. Übung 1, 3, 5) — erste Version nur
  aufeinanderfolgend.

## Regeln

### Eligibility-Regel
Eine Übung darf in ein Superset überführt werden, wenn **kein einziger
Satz dieser Übung abgeschlossen** ist (`sets.allSatisfy { !$0.isCompleted }`).

Spielt keine Rolle, ob es die gerade ausgewählte aktive Übung ist —
ausschlaggebend ist nur der Completion-Zustand der Sätze.

### Auswahl-Regel
- Mindestens 2 Übungen.
- Maximal 5 Übungen (wie im Plan-Edit).
- Indizes müssen **lückenlos aufeinanderfolgen** in
  `cachedGroupedSets`. Lücken werden im UI verhindert (Auswahl von
  nicht-aufeinanderfolgenden Übungen blockiert die Erstellung).

### Pausen-Anpassung
Beim Erstellen eines Supersets aus N Übungen mit jeweils M Sätzen:
- Pro Runde (Round = Set-Index 1 bis M) werden alle Sätze der Übungen
  1 bis N−1 sowie alle Sätze der Übung N **außer dem letzten Satz vor
  einer neuen Runde** auf `restSeconds = 0` gesetzt.
- Der letzte Satz der letzten Übung pro Runde behält seine
  Original-Pausenzeit.

Konkret bei 3 Übungen mit je 3 Sätzen:
- Runde 1: Ü1-S1 (0s), Ü2-S1 (0s), Ü3-S1 (original)
- Runde 2: Ü1-S2 (0s), Ü2-S2 (0s), Ü3-S2 (original)
- Runde 3: Ü1-S3 (0s), Ü2-S3 (0s), Ü3-S3 (original)

Beim Auflösen eines Supersets (`removeFromSuperset`) bleiben die
angepassten `restSeconds = 0` **bestehend**. Der User kann sie über das
Satz-Edit-Sheet manuell wiederherstellen. (Begründung: keine Original-
Werte mehr gespeichert; Heuristik wäre fehleranfällig.)

### Mehrere Supersets pro Session
Jedes Superset bekommt eine neue `UUID().uuidString` als
`supersetGroupId`. Beim Schließen des Selection-Modus wird der Auswahl-
State sauber geleert, damit ein zweites Superset gebildet werden kann
ohne Re-Mount der View.

### Plan bleibt unverändert
Der ursprüngliche `TrainingPlan` wird durch das Session-Superset **nicht**
modifiziert. Beim nächsten Training aus dem Plan startet die Session
ohne Superset (wie zuvor).

## Edge Cases

| Fall | Verhalten |
|------|-----------|
| Auswahl mit Lücke (z.B. Index 0, 2) | Superset-Button disabled, kleiner Hinweis-Text in der Action Bar: "Nur aufeinanderfolgende Übungen" |
| Übung mit ≥1 completed Set angetippt | Tap wird ignoriert, kurze Haptic; Karte zeigt Schloss-Icon |
| Bereits in einem anderen Superset | Tap wird ignoriert, Karte zeigt Link-Icon (analog Plan-Edit) |
| Selection-Modus während aktiver Pause | Erlaubt; Timer läuft im Hintergrund weiter |
| Nur eine eligible Übung übrig | Bolt-Button bleibt sichtbar, Selection-Modus zeigt sofort "Mindestens 2 für ein Superset" |
| Keine eligible Übung übrig | Bolt-Button **disabled** (opacity 0.4), Tap zeigt keinen Modus |

## UI-Komponenten

### Bolt-Button im Header von `ExercisesOverviewCard`
- Position: rechts neben dem bestehenden Sort/Add-Button.
- Icon: `bolt` (analog Plan-Edit).
- Disabled wenn keine ≥2 eligible Übungen vorhanden sind.
- Aktiviert den Multi-Select-Modus.

### Multi-Select-Modus
- Tap auf eligibele Übung → Auswahl toggle, blauer Border + Checkmark-Badge.
- Übungen mit completed Sets → Schloss-Icon, disabled, halbtransparent.
- Übungen bereits in anderem Superset → Link-Icon, disabled.

### Floating Action Bar
- Position: `safeAreaInset(edge: .bottom)` auf der ScrollView, sitzt
  **über** der `bottomActionBar` (Pause/Beenden).
- Inhalt: "X Übungen ausgewählt" / "Mindestens 2 für ein Superset",
  Cancel-Button, Superset-Erstellen-Button.
- Sichtbar nur im Selection-Modus, Slide-Up-Transition.

### Kontextmenü-Erweiterung
- Bei Übungen in einem Superset zusätzlicher Menü-Eintrag
  "Aus Superset entfernen" (analog Plan-Edit).

## Datenfluss

```
User tippt Bolt-Button
  └─ ExercisesOverviewCard.isSupersetSelectionMode = true
       └─ Multi-Select-Modus aktiv, Auswahl möglich

User tippt Übung
  └─ selectedGroupIndices.toggle(index) (nur wenn eligible)

User tippt "Superset erstellen"
  └─ Callback nach oben an ActiveWorkoutView
       └─ ActiveWorkoutView ruft session.createSuperset(fromGroupIndices:)
            ├─ Setzt supersetGroupId für alle ausgewählten Sets
            ├─ Passt restSeconds an (0 für Zwischen-Sätze)
            └─ Speichert via context.save()
       └─ setManager.rebuildGroupedCaches() + refreshSetCaches()
       └─ Cache-Refresh triggert ExercisesOverviewCard Re-Render
       └─ Hero-Card (RestTimerCard / ActiveSetCard) zieht aktuelle
          supersetDisplayContext / supersetNextRoundNames
```

## Datenmodell-Änderungen
**Keine.** `ExerciseSet.supersetGroupId: String?` existiert bereits.

## Performance
- Cache-Refresh nach create/remove: einmaliger Rebuild
  (`rebuildGroupedCaches` + `refreshSetCaches`), ~5–10 ms bei
  typischen 5–8 Übungen mit je 3–5 Sätzen. Akzeptabel.
- Supabase-Sync: keine sofortige Aktion nötig — Session wird beim
  Finish ohnehin komplett hochgeladen, Superset-Felder sind im
  `SupabaseExerciseSetDTO` bereits gemappt.
