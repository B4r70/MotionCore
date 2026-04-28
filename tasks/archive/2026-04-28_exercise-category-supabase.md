# Plan: ExerciseCategory-Ableitung aus Supabase aufbohren

**Komplexität:** Small
**Implementierungsmodus:** Single Pass
**Status:** Implemented

## Summary

`ExerciseCategory.fromSupabase(...)` so erweitern, dass alle sechs Cases (`compound`, `isolation`, `bodyweight`, `cardio`, `stretching`, `core`) aus Supabase ableitbar werden. Zusätzlich zu `mechanic_type`/`force_type` werden `category` und `equipment[]` einbezogen. Web spiegelt anschließend die finale Mapping-Tabelle 1:1.

## Pflicht-Lektüre — Befunde

- `MotionCore/Models/Types/ExerciseTypes.swift` Z. 312–336: aktuelle `fromSupabase(mechanic:force:)`. Drei Bedingungen, Default `.compound`. Kein Cardio/Stretching/Bodyweight-Pfad.
- `MotionCore/Models/Types/ExerciseTypes.swift` Z. ~280: `ExerciseEquipment.fromSupabase` kennt Bodyweight-Synonyme `"body weight"`, `"bodyweight"`, `"body_only"`. Wird im neuen Mapper wiederverwendet.
- `MotionCore/Models/Core/Exercise.swift` Z. 399–402: Aufrufer in `Exercise.init(from supabase: SupabaseExercise)`.
- `MotionCore/Services/Database/Local/BundledExerciseSeeder.swift` Z. 316–319: **zweiter Aufrufer** in `updateExercise(_:from source: SupabaseExercise)`. Beide haben Zugriff auf `source.category` und `source.equipment`.
- `SupabaseExercise` exportiert `category: String?`, `mechanicType: String?`, `forceType: String?`, `equipment: [String]`.

## Pflicht-Verifikationen — bereits erledigt

- ✅ `grep` — **2 Aufrufer**: `Exercise.swift:399`, `BundledExerciseSeeder.swift:316`. Beide identisch anpassbar.
- ✅ Supabase-Stichprobe `SELECT DISTINCT category, mechanic_type, force_type FROM motioncore.exercises`:
  - `category`: `cardio` (34), `plyometric` (17), `strength` (1220), `stretching` (53). **Kein `flexibility`.**
  - `mechanic_type`: **ausschließlich `"compound"`** — kein einziger `isolation`-Eintrag in der DB.
  - `force_type`: `dynamic`, `push`, `pull`, `static`. `static` kommt aktuell nur unter `strength/compound` vor (z.B. Plank, Hold-Übungen).

## Konsequenzen aus den realen Daten

1. **`mechanic` ist als Diskriminator nutzlos** — alle Übungen sind `"compound"`. Die alte Funktion produzierte praktisch nur `.compound` (außer `force == "static"` → `.core`). Die UI-Cases `.isolation` und `.bodyweight` waren bisher nur über manuelle iOS-Edits oder Custom-Exercises erreichbar.
2. **Bodyweight-Trade-off entfällt:** Da `mechanic` nie `nil` ist, würde Bedingung "`bodyweight` nur wenn `mechanic == nil`" NIE greifen. Damit `.bodyweight` aus DB-Daten ableitbar wird, **muss** die Equipment-Prüfung VOR der Mechanic-Prüfung stehen. Das schließt die offene Trade-off-Frage automatisch.
3. **`flexibility`-Bedingung optional** — kommt heute nicht vor. Zur Robustheit gegenüber zukünftigen Seeder-Versionen (externer Datenanbieter) trotzdem mit aufnehmen.
4. **`plyometric` fällt durch zu Default** → `.compound`. Plyo-Übungen sind Mehrgelenk-Bewegungen, das passt semantisch.
5. **`force == "static"` muss vor `mechanic == "compound"` ausgewertet werden**, sonst gewinnt mechanic immer und Plank/Hold landet in `.compound` statt `.core`. (Ist im Vorschlag bereits korrekt durch Reihenfolge "category → equipment → static → mechanic" abgedeckt, sofern static vorgezogen wird.)

## Affected Files

- `MotionCore/Models/Types/ExerciseTypes.swift` — `ExerciseCategory.fromSupabase` neu schreiben mit erweiterter Signatur, deutsche Inline-Kommentare. Bodyweight-Synonyme als private `static let` extrahieren und zwischen `ExerciseCategory` und `ExerciseEquipment` teilen (oder Inline-Set mit Konsistenz-Kommentar — Implementer-Wahl, beides ok).
- `MotionCore/Models/Core/Exercise.swift` — Aufrufer (Z. 399–402) auf neue Signatur umstellen.
- `MotionCore/Services/Database/Local/BundledExerciseSeeder.swift` — Aufrufer (Z. 316–319) auf neue Signatur umstellen.

## Mapping-Reihenfolge — final (gegeben durch Daten-Realität)

Reihenfolge ist semantisch relevant; frühere Treffer überstimmen spätere. Alle String-Vergleiche `.lowercased()`.

1. `category == "cardio"` → `.cardio`
2. `category in {"flexibility", "stretching"}` → `.stretching`
3. `force == "static"` → `.core`
4. `equipment` enthält eines aus `{"body weight", "bodyweight", "body_only"}` → `.bodyweight`
5. `mechanic == "isolation"` → `.isolation`
6. `mechanic == "compound"` → `.compound`
7. Sonst → `.compound` (Default)

### Begründung

- **1 & 2 zuerst:** Domänenspezifische Kategorien aus DB sind autoritativ — keine Heuristik soll Cardio/Stretching überstimmen.
- **3 vor mechanic:** Reale DB hat `mechanic` immer `"compound"`. Equipment-Prüfung muss vorgezogen werden, sonst ist `.bodyweight` aus DB-Daten unerreichbar. Trade-off entfällt durch Daten-Realität.
- **4 vor mechanic:** `force == "static"` ist der einzige robuste `.core`-Indikator (Plank etc.). Wenn mechanic vorher gewinnt, landen Holds in `.compound`.
- **5 vor 6:** Falls `isolation` jemals in DB landet (heute nicht), soll spezifischer Wert vor `compound`-Default greifen.
- **7 Default `.compound`:** `plyometric`, `strength` ohne Bodyweight-Equipment, alle anderen Restfälle. Bestehendes Verhalten — keine Regression.

## Mapping-Tabelle (Spec für Web-Spiegelung)

| # | Bedingung (alle Strings `lowercased()`) | ExerciseCategory |
|---|------------------------------------------|------------------|
| 1 | `category == "cardio"` | `.cardio` |
| 2 | `category in {"flexibility", "stretching"}` | `.stretching` |
| 3 | `force == "static"` | `.core` |
| 4 | `equipment ∋ {"body weight", "bodyweight", "body_only"}` | `.bodyweight` |
| 5 | `mechanic == "isolation"` | `.isolation` |
| 6 | `mechanic == "compound"` | `.compound` |
| 7 | sonst (Default) | `.compound` |

Bodyweight-Synonym-Liste: identisch zu `ExerciseEquipment.fromSupabase`. Web muss exakt dieselbe Liste nutzen.

## Implementation Steps

- [x] User-OK zur finalen Reihenfolge einholen (Bodyweight VOR Mechanic + force-static VOR Mechanic, Begründung in den Daten).
- [x] `ExerciseTypes.swift`: `ExerciseCategory.fromSupabase`-Signatur erweitern auf `(category: String?, mechanic: String?, force: String?, equipment: [String])`.
- [x] Body neu schreiben mit den 7 Bedingungen oben. Alle String-Vergleiche `.lowercased()`. Bodyweight-Synonyme aus geteilter Quelle (siehe Affected Files).
- [x] Deutsche Inline-Kommentare an jeder Bedingung (kurz, ein Satz pro Case).
- [x] Aufrufer 1 in `Exercise.swift` Z. 399–402 anpassen: `category: supabase.category, mechanic: supabase.mechanicType, force: supabase.forceType, equipment: supabase.equipment`.
- [x] Aufrufer 2 in `BundledExerciseSeeder.swift` Z. 316–319 analog: `category: source.category, mechanic: source.mechanicType, force: source.forceType, equipment: source.equipment`.
- [x] `Cmd+B` grün.

## Risks

- **Bestehende `Exercise.categoryRaw`-Daten werden NICHT migriert.** Bereits importierte Exercises behalten ihr altes Mapping (überwiegend `.compound`/`.core`). Out of scope; optionaler Folge-Task: Re-Import via `Exercise.init(from:)` für alle `apiID != nil`-Datensätze.
- **`BundledExerciseSeeder`-Update-Pfad:** Bei nächstem App-Start mit aktualisiertem Bundle wird `updateExercise` für jede Exercise aufgerufen — falls `existing.category != newCategory`, wird neu gesetzt. Das **migriert** dann automatisch viele Exercises auf das neue Mapping (z.B. Cardio-Übungen weg von `.compound` hin zu `.cardio`). Effekt ist gewollt, sollte aber kommuniziert werden — ggf. UX-Test ob die neuen Kategorien-Buckets die User-Erwartung treffen.
- **Backup-Push:** `SupabaseFullBackupService` schreibt `categoryRaw` heute nicht zurück (siehe vorheriger Plan: `category_override` ausgeklammert). Bleibt unverändert.

## Manual Verification

- [ ] `Cmd+B` baut sauber.
- [ ] Stichproben gegen Produktion (App neu starten lassen, damit `BundledExerciseSeeder` durchläuft):
  - Cardio-Übung (z.B. Treadmill Run) → `.cardio`
  - Stretching-Übung (z.B. Hamstring Stretch) → `.stretching`
  - Liegestütze (Push-Up, Equipment `"body weight"`) → `.bodyweight`
  - Klimmzüge (Pull-Up, Equipment `"body weight"`) → `.bodyweight`
  - Bizeps-Curl mit Hantel → `.compound` (DB hat `mechanic="compound"` für alles; `.isolation` nur via manuelle iOS-Anpassung erreichbar — siehe Konsequenz #1)
  - Kniebeuge → `.compound`
  - Plank (`force="static"`) → `.core`
- [ ] Lese-Pfad: Exercise-Detail-View für oben genannte Stichproben zeigt korrekten Kategorie-Chip/Icon.
- [ ] Plyometric-Übung (z.B. Box Jump) → `.compound` (Default, keine Spezialbehandlung).

## Open Questions

Keine mehr — Bodyweight-Trade-off durch Daten-Realität geklärt. User soll nur die finale Reihenfolge bestätigen, dann implementieren.

---

## Progress

**2026-04-27**

Alle Steps abgeschlossen. BUILD SUCCEEDED.

**Geanderte Dateien:**
- `MotionCore/Models/Types/ExerciseTypes.swift` — `ExerciseCategory.fromSupabase` auf neue 4-Parameter-Signatur umgeschrieben (7 Bedingungen, deutsche Kommentare). `ExerciseEquipment.bodyweightSynonyms` als `static let Set<String>` extrahiert — wird in `fromSupabase(_:)` und `ExerciseCategory.fromSupabase(...)` geteilt (Single Source of Truth, Extraktion gelungen).
- `MotionCore/Models/Core/Exercise.swift` — Aufrufer Z. 399 auf neue Signatur umgestellt.
- `MotionCore/Services/Database/Local/BundledExerciseSeeder.swift` — Aufrufer Z. 316 auf neue Signatur umgestellt.

**Auffaelligkeiten:** Keine. Kein dritter Aufrufer gefunden. Build ohne Warnings zu den geaenderten Stellen.
