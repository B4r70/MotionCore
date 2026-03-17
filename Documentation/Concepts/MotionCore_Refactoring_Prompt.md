# MotionCore – Refactoring-Auftrag für Claude Code

## Kontext

MotionCore ist eine iOS Fitness-App (SwiftUI, SwiftData, CloudKit, HealthKit) mit ~181 Dateien.
Dieses Dokument beschreibt einen systematischen Refactoring-Auftrag in 4 Bereichen.

## ⚠️ Wichtige Regeln

1. **Cardio-Code NICHT anfassen.** Ein großer Cardio→Warmup-Umbau ist separat geplant. Alle Dateien die primär mit `CardioSession` arbeiten, bleiben unverändert. Dazu gehören:
   - `CardioSession.swift`, `CardioTypes.swift`, `SessionUI.swift`
   - `FormView.swift`, `FormViewSection.swift`, `WorkoutCard.swift`
   - `StatisticCalcEngine.swift` (basiert auf CardioSession)
   - `RecordCalcEngine.swift`, `RecordView.swift`, `StatisticView.swift`
   - Cardio-bezogene Teile in `Export.swift`, `IODataManager.swift`
   - Cardio-bezogene Properties in `AppSettings.swift` (defaultDevice, defaultProgram, etc.)
   - Cardio-Referenzen in `BaseView.swift`, `ListView.swift`, `SummaryCalcEngine.swift`, `SummaryView.swift`

2. **Architektur-Prinzip:** Keine Business-Logik in Views. Berechnungen gehören in CalcEngine-Klassen.

3. **Code-Kommentare auf Deutsch**, Variablen/Methoden auf Englisch.

4. **Keine "NEU:"-Kommentare** hinzufügen, es sei denn explizit angefordert.

5. **Nur Produktionscode** – kein Testcode erstellen.

6. **Kleine Fixes direkt durchführen**, große Änderungen erst als Liste vorschlagen und auf Freigabe warten.

---

## Auftrag 1: Toten Code finden und entfernen

Durchsuche alle 181 Dateien nach:

### Sofort entfernbar (direkt löschen):
- **`Untitled.swift`** – komplett leer, kann sofort gelöscht werden
- **`SwiftDataFactory.swift`** – komplett auskommentiert (`/* ... */`), wird nicht mehr genutzt (Container-Logik ist in `MotionCoreApp.swift`). Kann gelöscht werden.
- **`GlassButtonExamples.swift`** – reine Beispiel-Datei mit Previews. Prüfe ob irgendeine View diese Datei referenziert. Falls nein → löschen.

### Systematisch suchen:
- **Auskommentierte Code-Blöcke** (größer als 5 Zeilen) – entweder entfernen oder mit TODO-Kommentar versehen warum sie bleiben
- **Unused imports** – z.B. `import Combine` oder `import AVKit` die nicht genutzt werden
- **Nicht aufgerufene Funktionen/Properties** – insbesondere in CalcEngines und Services
- **Debug-print-Statements** die in Produktion nicht mehr nötig sind (z.B. die vielen `print("📅 ...")` in `CoreSessionCalcEngine.sessionsThisMonth`)
- **`AppSettingsUserDefaults.swift`** – enthält nur `loadInitialBirthdayDate()`. Prüfe ob diese Funktion irgendwo aufgerufen wird. Falls nicht → löschen. Falls ja → könnte direkt in `AppSettings.init()` integriert werden.
- **Deprecated Properties** wie `isWarmup` in `ExerciseSet.swift` (Zeile 71-74) – wird das noch irgendwo genutzt oder kann es raus?

### Report erstellen für:
- Liste aller gefundenen toten Code-Stellen mit Dateiname und Zeilennummer
- Empfehlung: löschen / behalten / unklar

---

## Auftrag 2: Doppelten/duplizierten Code zusammenführen

### Bekannte Duplikate prüfen:
- **`formattedTotalDuration`** – existiert sowohl in `CoreSessionCalcEngine` als auch in `SummaryCalcEngine` mit identischer Logik. Könnte als Extension auf `Int` oder als statische Hilfsfunktion extrahiert werden.
- **`actualDuration`** – wird in `CardioSession` UND im `CoreSession`-Protokoll (Default-Implementation) definiert. Die CardioSession-Version ist redundant (aber: Cardio nicht anfassen, nur notieren).
- **`start()` / `complete()`** – gleiche Situation wie `actualDuration`.
- **Zeitfilter-Logik** – `sessionsThisWeek`, `sessionsThisMonth`, etc. in `CoreSessionCalcEngine` vs. ähnliche Logik in `StrengthStatisticCalcEngine.filtered(by:)`. Prüfe ob `StrengthStatisticCalcEngine` stattdessen `CoreSessionCalcEngine` delegieren könnte.

### Systematisch suchen:
- Identische oder nahezu identische Code-Blöcke in verschiedenen Dateien
- Ähnliche View-Modifier die in eine gemeinsame Extension extrahiert werden könnten
- Wiederholte String-Formatierungen die in `AppFormatter` zentralisiert werden könnten

### Report erstellen für:
- Alle gefundenen Duplikate mit konkretem Refactoring-Vorschlag
- Priorisierung: hoch (>10 Zeilen dupliziert) / mittel (5-10 Zeilen) / niedrig (<5 Zeilen)

---

## Auftrag 3: Naming-Konsistenz prüfen

### Regeln:
- **Variablen, Funktionen, Klassen:** Englisch (Swift-Konvention)
- **Kommentare:** Deutsch
- **UI-Texte (die der User sieht):** Deutsch
- **Enum RawValues:** Englisch

### Bekannte Inkonsistenzen prüfen:
- Property-Namen: Gibt es deutsche Property-Namen die englisch sein sollten?
- Funktionsnamen: Gibt es Mischformen wie `berechneTotal()` statt `calculateTotal()`?
- Prüfe Konsistenz bei ähnlichen Konzepten:
  - `allWorkouts` vs `allSessions` vs `sessions` – wird das einheitlich verwendet?
  - `workout` vs `session` – Cardio nutzt "workout", Strength nutzt "session". Für den Strength-Bereich: ist es konsistent?
- **Parameter-Namen in Inits:** Sind die konsistent? Z.B. `workouts:` vs `sessions:` als Parameter-Label

### Report erstellen für:
- Liste aller Inkonsistenzen mit Vorschlag zur Vereinheitlichung
- Dabei beachten: Cardio-Code nicht ändern (wird sowieso bald entfernt)

---

## Auftrag 4: File-Organisation prüfen

### Aktuelle Ordnerstruktur (aus Memory):
```
Models/
Types/
Services/Database/Local
Services/Database/Remote
CalcEngines/
Components/Cards/
Utils/Formatters/
```

### Prüfen:
- Sind alle Dateien im richtigen Ordner? Z.B.:
  - `TrendPoint`, `DonutChartData`, `IntensitySummary`, `ProgramSummary` sind in `StatisticCalcEngine.swift` definiert – gehören diese Helper-Structs in eine eigene Datei (z.B. `ChartTypes.swift`)?
  - `MixedWorkoutItem` ist in `ListView.swift` definiert – sollte das in eine Types-Datei?
  - `StatsSegment` ist in `StatsAndRecordsView.swift` – eigene Datei oder okay?
  - `WorkoutTypeFilter` ist in `ListView.swift` – gehört das in `FilterTypes.swift`?
  - `WorkoutTypeButton` ist private in `NewWorkoutSheet.swift` – okay so?
- Gibt es Dateien die zu groß sind und aufgesplittet werden sollten?
  - `FormViewSection.swift` ist 48KB – wie viele Sections sind da drin?
  - `ActiveWorkoutView.swift` ist 61KB – könnte in Sub-Views aufgeteilt werden
  - `ExerciseSeeder.swift` ist 46KB – sind das nur hardcodierte Daten?
- Gibt es Dateien die zusammengehören und in eine gemeinsame Datei könnten?

### Report erstellen für:
- Vorschläge zur Umorganisation mit Begründung
- Dabei pragmatisch bleiben: Nur verschieben wenn es die Übersichtlichkeit wirklich verbessert

---

## Ausgabeformat

Erstelle einen strukturierten Report in folgendem Format:

```
## 🗑️ Toter Code

### Sofort gelöscht:
- [Datei] – [was wurde entfernt] – [Begründung]

### Vorschlag (Freigabe nötig):
- [Datei:Zeile] – [was] – [Empfehlung]

## 🔁 Duplikate

### Direkt refactored:
- [was] – [von wo nach wo] – [Begründung]

### Vorschlag (Freigabe nötig):
- [Duplikat beschreiben] – [Refactoring-Vorschlag]

## 📝 Naming

### Direkt gefixt:
- [Datei] – [alt → neu] – [Begründung]

### Vorschlag (Freigabe nötig):
- [Inkonsistenz] – [Vorschlag]

## 📁 File-Organisation

### Vorschläge:
- [Datei] – [aktueller Ort → vorgeschlagener Ort] – [Begründung]
```

---

## Reihenfolge

1. Zuerst den **vollständigen Scan** durchführen (alle 181 Dateien lesen)
2. Dann den **Report** erstellen
3. **Kleine Fixes** (leere Dateien löschen, offensichtlich toten Code entfernen, Debug-Prints aufräumen) direkt durchführen
4. **Große Vorschläge** im Report auflisten und auf Freigabe warten
