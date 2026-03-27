# Quality Gate — StrengthDetailView Toolbar und Aktionen Umbau

**Datum:** 27.03.2026
**Status:** Änderungen nötig (2 Punkte zur Abstimmung)

---

## Positives

- Toolbar-Placement korrekt als `.topBarTrailing` — beide Buttons sauber zusammengefasst
- `showDeleteAlert` und `showEditSheet` korrekt verdrahtet, keine doppelten State-Variablen
- `NavigationLink` zu `TrainingDetailView(plan: plan)` korrekt mit `if let plan = session.sourceTrainingPlan` bewacht — kein Force-Unwrap
- "Training löschen"-Button in `actionsSection` entfernt, Löschen nur noch via Toolbar
- `.foregroundStyle(.red)` auf dem Trash-Icon folgt iOS-Konvention für destruktive Aktionen
- `Alert`-Confirmation mit `.destructive` Role korrekt eingesetzt

---

## Findings

### [MITTEL] Icon-Stil bricht Projektkonventionen

**Datei:** `StrengthEditView.swift`, Zeilen 110–123

Alle anderen Sheets im Projekt (`SetEditSheet`, `PlanUpdateSheet`, `TrainingFormView`, `PlanPickerSheet`) nutzen Text-Labels (`"Abbrechen"`, `"Fertig"`) für Toolbar-Buttons. Die neuen Icon-Buttons (`chevron.left`, `checkmark`) sind ein Ausreißer.

**Empfehlung:** Abstimmen, ob dies bewusst ein neuer Standard sein soll (dann alle anderen Sheets angleichen) oder ob zurück auf Text-Labels gewechselt werden sollte.

---

### [MITTEL] `TrainingDetailView` benötigt `ActiveSessionManager` — transitiv, nicht explizit

**Datei:** `StrengthDetailView.swift`, Zeilen 471–488

`TrainingDetailView` deklariert `@EnvironmentObject private var sessionManager: ActiveSessionManager`. Der `NavigationLink` übergibt kein `.environmentObject(...)` explizit. Das Environment kommt transitiv von `BaseView`. Funktioniert im normalen Navigationsfluss, ist aber fragil und im Simulator zwingend zu prüfen.

---

### [GERING] Vorbestehendes TODO in `repeatWorkout()`

**Datei:** `StrengthDetailView.swift`, Zeile 546

`repeatWorkout()` legt eine neue Session an, navigiert aber nicht zur `ActiveWorkoutView`. Kein Handlungsbedarf in diesem Task.

---

## Static Checks

- [x] Keine fehlenden Imports, keine nicht-existenten Methoden
- [x] `TrainingDetailView(plan:)` Signatur korrekt — `@Bindable var plan: TrainingPlan` passt
- [x] Kein Business-Logic in Views
- [x] Keine neuen `sorted/filter/map` im `body`

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Toolbar zeigt `square.and.pencil` und `trash` Icons
- [ ] Trash-Icon: Delete Alert erscheint, Session wird gelöscht
- [ ] Pencil-Icon: `StrengthEditView` Sheet öffnet sich, `chevron.left` und `checkmark` sichtbar
- [ ] Session MIT Plan: "Plan bearbeiten" navigiert korrekt zu `TrainingDetailView`
- [ ] Session OHNE Plan: "Plan bearbeiten" Button nicht sichtbar
- [ ] "Fertig" in StrengthEditView: Supabase-Resync-Flag korrekt gesetzt
