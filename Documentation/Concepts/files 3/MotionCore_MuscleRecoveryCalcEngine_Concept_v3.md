# MotionCore — MuscleRecoveryCalcEngine Konzeptdokument v3

> **Stand:** 25.04.2026 — Update-Strategie überarbeitet (siehe Abschnitt 7).
> **Vorgänger:** v2 (gleicher Tag, kurz davor)
> **Bezug:** Phase 2 Readiness ist seit 24.04.2026 abgeschlossen.

---

## 1. Zusammenfassung

Die `MuscleRecoveryCalcEngine` berechnet pro Muskelgruppe einen Erholungsstatus (0–100%), basierend auf den StrengthSessions der **letzten 14 Tage mit exponentiellem Decay** (ältere Sessions zählen weniger). Sie nutzt Volumen, Intensität (RPE/RIR) und den Zeitabstand seit der letzten Belastung.

Der Score wird im neuen **Body-Tab** angezeigt (TabView zwischen Stats und Training) sowie als kompakte Vorschau in der **SummaryView** direkt nach der `ReadinessSummaryCard`.

**Wichtige Trennung:** Tagesform-Readiness (`SessionReadiness`) und Muscle-Recovery sind **architektonisch getrennt** — beide existieren als eigene Cards nebeneinander. Es gibt keine Vermischung der Scores.

**Update-Strategie (v3):** Die UI berechnet on-the-fly bei View-Aktivierung. Supabase erhält **genau einen Snapshot pro Tag** ab dem ersten App-Open nach 6:00 morgens — das ergibt eine saubere 1:1-Beziehung Tag → Snapshot für historische Auswertungen.

---

## 2. Entscheidungen (final)

| Frage | Entscheidung |
|---|---|
| Engine-Name | `MuscleRecoveryCalcEngine` |
| Granularität | DetailedMuscle intern, MuscleGroup im UI (7 enum cases: chest, back, shoulders, arms, legs, core, glutes) |
| Verhältnis zur Tagesform | **Strikt getrennt** — keine Vermischung |
| Zeitfenster | **14 Tage mit exponential decay** |
| UI-Platzierung | **Body-Tab (neu)** + SummaryView-Vorschau |
| Reihenfolge SummaryView | **Direkt nach `ReadinessSummaryCard`** |
| Tab-Position | **Zwischen Stats und Training** |
| Body-Tab Phase 1 | `MuscleRecoveryCard` + Readiness-Faktoren-Aufschlüsselung |
| Tap-Verhalten | Card komplett tappable → `MuscleRecoveryDetailView` |
| Darstellungsform | Donuts (wie Mockup) mit **Gradient-Farben** (rot → orange → gelb → grün) |
| Untrainierte Muskeln | 100% mit **grauem Ring** zur visuellen Differenzierung |
| Berechnungslogik | **Hybrid** — Ermüdung erhöht nötige Erholungszeit + Zeit-basierte Erholung |
| Sekundäre Beteiligung | **30% Volumen, kein Set-Zählen** (analog MuscleHeatmap) |
| Persistenz lokal | **Keine** — alles on-the-fly im SummaryViewModel + neuem BodyViewModel |
| Persistenz Supabase | **Ja** — neue Tabelle `muscle_recovery_snapshots` in `motioncore`-Schema |
| **Sync-Trigger** | **NUR App-Open ab 6:00 Uhr morgens, max. 1× pro Tag** |
| **UI-Refresh** | **Bei View-Aktivierung (`.onAppear` + `scenePhase`-Wechsel)** |
| Tabellen-Strategie | Append-Only, Tag-basierte Deduplikation via UserDefaults-Flag |
| Schema-Granularität | 1 Zeile pro Snapshot mit MuscleGroup-Spalten (chest_recovery, back_recovery, …) |
| Muskel-Auflösung | Fallback-Kette aus `MuscleHeatmapCalcEngine` wiederverwenden |

---

## 3. Architektur

### 3.1 Neue Dateien

```
MuscleRecoveryCalcEngine.swift     — Pure struct, Berechnung
MuscleRecoveryTypes.swift          — Ergebnis-Typen
MuscleRecoveryDonut.swift          — Donut-Subkomponente
MuscleRecoveryCard.swift           — Card mit Donut-Reihe (für SummaryView und BodyView)
MuscleRecoveryDetailView.swift     — Detail-Sheet bei Tap
BodyView.swift                     — Neuer Top-Level-Tab
BodyViewModel.swift                — ViewModel für Body-Tab
SupabaseMuscleRecoverySnapshot.swift — DTO für Supabase
SupabaseMuscleRecoveryService.swift — Upload-Logik
```

### 3.2 Bestehende Dateien (Änderungen)

```
BaseView.swift                — Body-Tab zwischen Stats und Training einfügen + App-Open-Trigger
SummaryView.swift             — MuscleRecoveryCard nach ReadinessSummaryCard einbinden
SummaryViewModel.swift        — recoveryAnalysis Property + recalculate-Aufruf
```

### 3.3 Kein neues SwiftData-Model in Phase 1

Die Engine berechnet alles on-the-fly aus bestehenden `StrengthSession`/`ExerciseSet`-Daten. Auf iOS-Seite **keine** lokale Persistenz — der Snapshot wird ausschließlich nach Supabase gepusht.

---

## 4. Datenmodell — MuscleRecoveryTypes.swift

```swift
import Foundation

// MARK: - Recovery-Score pro DetailedMuscle (intern)

struct DetailedMuscleRecovery: Identifiable {
    let id: String                      // = DetailedMuscle.rawValue
    let muscle: DetailedMuscle
    let recoveryPercent: Double         // 0.0–100.0 (100 = voll erholt)
    let lastTrainedDate: Date?
    let totalFatigueScore: Double       // Kumulative Ermüdung (decay-gewichtet)

    var displayName: String { muscle.displayName }
    var muscleGroup: MuscleGroup { muscle.parentGroup }
}

// MARK: - Aggregierter Recovery-Score pro MuscleGroup (UI)

struct MuscleGroupRecovery: Identifiable {
    let id: String                      // = MuscleGroup.rawValue
    let muscleGroup: MuscleGroup
    let recoveryPercent: Double         // 0.0–100.0 (Durchschnitt der DetailedMuscles)
    let muscleDetails: [DetailedMuscleRecovery]
    let lastTrainedDate: Date?
    let wasTrainedInTimeframe: Bool     // false → "untrainiert" (grauer Ring)

    var displayName: String { muscleGroup.description }
    var isFullyRecovered: Bool { recoveryPercent >= 95.0 }
}

// MARK: - Gesamt-Analyse

struct MuscleRecoveryAnalysis {
    let analysisDate: Date
    let timeframeDays: Int                              // = 14
    let muscleGroupScores: [MuscleGroupRecovery]        // Alle 7 MuscleGroups
    let detailedScores: [DetailedMuscleRecovery]        // Alle relevanten DetailedMuscles

    /// Sortiert nach niedrigstem Recovery-Score (am meisten ermüdet zuerst)
    var leastRecoveredGroups: [MuscleGroupRecovery] {
        muscleGroupScores
            .filter { $0.wasTrainedInTimeframe }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
    }

    /// Durchschnittliche Erholung über trainierte Gruppen
    var overallRecoveryPercent: Double {
        let trained = muscleGroupScores.filter { $0.wasTrainedInTimeframe }
        guard !trained.isEmpty else { return 100.0 }
        return trained.map(\.recoveryPercent).reduce(0, +) / Double(trained.count)
    }
}
```

---

## 5. Berechnungslogik — MuscleRecoveryCalcEngine.swift

### 5.1 Konstanten

```swift
struct MuscleRecoveryCalcEngine {

    // MARK: - Konstanten

    /// Basis-Erholungszeiten in Stunden pro MuscleGroup
    static let baseRecoveryHours: [MuscleGroup: Double] = [
        .chest:     60,     // 2.5 Tage
        .back:      72,     // 3 Tage
        .shoulders: 48,     // 2 Tage
        .arms:      48,     // 2 Tage
        .legs:      72,     // 3 Tage
        .glutes:    72,     // 3 Tage
        .core:      36,     // 1.5 Tage
        .other:     48,
        .fullBody:  72
    ]

    /// Sekundäre Muskelbeteiligung — Volumen-Faktor (Sets werden NICHT mitgezählt)
    static let secondaryVolumeWeight: Double = 0.30

    /// Zeitfenster in Tagen
    static let timeframeDays: Int = 14

    /// Decay-Halbwertszeit in Tagen — nach diesen Tagen zählt eine Session nur noch 50%
    static let decayHalfLifeDays: Double = 7.0
}
```

### 5.2 Algorithmus — `analyze(sessions:)`

```
Eingabe:  [StrengthSession]
Ausgabe:  MuscleRecoveryAnalysis

1. Sessions filtern: nur letzte 14 Tage, isCompleted == true

2. Pro Session → Pro ExerciseSet (work-Sets, isCompleted, reps > 0):
   a) DetailedMuscles auflösen via resolveDetailedMuscles()
      (identische Fallback-Kette wie MuscleHeatmapCalcEngine)

   b) Decay-Faktor pro Session berechnen:
      ageInDays = (now - session.date) / 86400
      decayFactor = pow(0.5, ageInDays / decayHalfLifeDays)
      → Frische Session: 1.0
      → 7 Tage alt:      0.5
      → 14 Tage alt:     0.25

   c) Ermüdung pro Set:
      fatiguePerSet = volumeFactor × intensityFactor × decayFactor

      volumeFactor    = normalizedVolume(set.weight, set.reps, session.bodyWeight)
      intensityFactor = intensityFromRIR(set)  → 0.5–1.5

   d) Primary-Muskeln: volle fatigue
      Secondary-Muskeln: fatigue × 0.30 (Volumen-Faktor)

3. Pro DetailedMuscle: kumulative fatigue + jüngstes lastTrainedDate sammeln

4. Recovery-Score berechnen (für trainierte DetailedMuscles):

   hoursSince = (now - lastTrainedDate) / 3600
   baseHours  = baseRecoveryHours[muscle.parentGroup]
   adjusted   = baseHours × fatigueMultiplier(totalFatigue)
   recoveryPercent = min(100, (hoursSince / adjusted) × 100)

5. DetailedMuscle → MuscleGroup aggregieren:
   - Nur trainierte DetailedMuscles fließen ein
   - recoveryPercent = Durchschnitt aller trainierten DetailedMuscles der Gruppe
   - wasTrainedInTimeframe = true wenn mindestens 1 DetailedMuscle Daten hat

6. Untrainierte Gruppen: recoveryPercent = 100, wasTrainedInTimeframe = false

7. MuscleRecoveryAnalysis zurückgeben (alle 7 MuscleGroups, fixe Reihenfolge)
```

### 5.3 Hilfsfunktionen

```swift
// Wandelt RPE/RIR in Intensitätsfaktor (0.5–1.5)
private static func intensityFromRIR(_ set: ExerciseSet) -> Double {
    let rir: Int
    if set.rpeRecorded {
        rir = max(0, 10 - set.rpe)
    } else if set.targetRIR > 0 {
        rir = set.targetRIR
    } else {
        return 1.0
    }
    return max(0.5, min(1.5, 1.5 - Double(rir) * 0.25))
}

// Volumen-Normalisierung mit bodyWeight-Fallback
private static func normalizedVolume(weight: Double, reps: Int, sessionBodyWeight: Double) -> Double {
    let effectiveWeight = weight > 0 ? weight : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0)
    let raw = effectiveWeight * Double(reps)
    let reference = 1000.0
    return min(1.0, raw / reference)
}

// Ermüdungs-Multiplikator (0.8–1.5)
private static func fatigueMultiplier(_ totalFatigue: Double) -> Double {
    let normalized = min(totalFatigue / 5.0, 1.0)
    return 0.8 + (normalized * 0.7)
}
```

> **Wichtig:** `rpeRecorded` (Phase 1.5 Bugfix) wird zur Disambiguierung von `rpe=0` genutzt — siehe `ExerciseSet`.

---

## 6. UI-Integration

### 6.1 BaseView.swift — Neuer Body-Tab

```swift
// Tab-Enum erweitern:
enum Tab: Hashable {
    case summary, workouts, stats, body, training
}

// In TabView (zwischen Stats und Training):
NavigationStack {
    BodyView()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HeaderView(title: "MotionCore", subtitle: "Body")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { MainSettingsView() } label: {
                    ToolbarButton(icon: .system("gearshape"))
                }
            }
        }
}
.tabItem {
    Label("Body", systemImage: "figure.arms.open")
}
.tag(Tab.body)
```

### 6.2 BodyView.swift — Phase-1-Inhalt

Inhalt:
- `MuscleRecoveryCard` (volle Größe, LazyVGrid mit 4 Spalten)
- Readiness-Faktoren-Aufschlüsselung (HRV / Schlaf / Ruhepuls / Aktivität — wiederverwendet aus `ReadinessFactorRow`)

**Refresh-Trigger (siehe Abschnitt 7.1):**
- `.task { viewModel.recalculate(...) }` beim ersten Erscheinen
- `.onChange(of: scenePhase)` — bei Wechsel auf `.active` neu rechnen

### 6.3 SummaryView.swift — Vorschau-Card

Direkt nach `ReadinessSummaryCard`:

```swift
if let recovery = viewModel.recoveryAnalysis {
    MuscleRecoveryCard(analysis: recovery, style: .compact) {
        showMuscleRecoveryDetail = true
    }
}
```

→ `MuscleRecoveryCard` hat Style-Parameter `.compact` (für SummaryView, kleinere Donuts) und `.full` (für BodyView).

Refresh erfolgt automatisch durch das bestehende `recalculate()` der `SummaryViewModel`.

### 6.4 MuscleRecoveryDetailView

Bei Tap auf die Card öffnet sich ein Sheet mit:
- Header: Gesamt-Recovery + Zeitfenster (14 Tage)
- Pro MuscleGroup: Donut groß + Liste der DetailedMuscles mit Recovery-Werten
- Letzte Belastung pro Muskelgruppe (relative Zeit-Anzeige: "vor 2 Tagen")

### 6.5 Donut-Design (Gradient stufenlos)

```swift
// Rot (0%) → Orange (33%) → Gelb (66%) → Grün (100%)
func recoveryColor(percent: Double) -> Color {
    let p = percent / 100.0
    let hue = p * 120.0 / 360.0
    return Color(hue: hue, saturation: 0.75, brightness: 0.85)
}

// Untrainiert (wasTrainedInTimeframe == false): grauer Ring statt Gradient
```

---

## 7. Update-Strategie

### 7.1 UI-Refresh (clientseitig)

**Berechnung erfolgt on-the-fly bei jedem Refresh-Trigger:**

| Trigger-Stelle | Wie | Ergebnis |
|---|---|---|
| `SummaryView` öffnet | Bestehender `viewModel.recalculate()` | UI-Wert für Vorschau-Card |
| `SummaryView` Tab-Wechsel zurück | `.onAppear` + `scenePhase`-Beobachter | UI-Wert frisch |
| `BodyView` öffnet | `.task { viewModel.recalculate(...) }` | UI-Wert für volle Card |
| `BodyView` aktiv + App geht Foreground | `.onChange(of: scenePhase)` | UI-Wert frisch |

**Begründung:** Der Recovery-Wert ändert sich kontinuierlich (mit jeder vergangenen Stunde steigt er leicht). Wenn die App stundenlang offen liegt und der User wieder in den Body-Tab wechselt, soll der Wert aktuell sein. Da die Berechnung praktisch kostenlos ist (~200 Sets pro Aufruf), ist Recompute-bei-Sicht das einfachste und korrekteste Vorgehen.

### 7.2 Supabase-Sync (historisches Logbuch)

**Genau ein Snapshot pro Tag**, ausgelöst durch:

> **Erster App-Open am Tag nach 6:00 Uhr morgens.**

**Logik:**
1. Beim Wechsel `scenePhase → .active` (in `BaseView.swift` oder `MotionCoreApp.swift`)
2. Lese UserDefaults-Key `lastMuscleRecoverySnapshotDate` (Date oder nil)
3. Bedingung für neuen Snapshot:
   - `lastMuscleRecoverySnapshotDate` ist nil **ODER**
   - `lastMuscleRecoverySnapshotDate` liegt vor heute 6:00 Uhr (Calendar.current)
4. Falls Bedingung erfüllt:
   - Sessions abrufen, `analyze()` aufrufen
   - Snapshot via `SupabaseMuscleRecoveryService.shared.uploadSnapshot(...)`
   - Bei Erfolg: `lastMuscleRecoverySnapshotDate = Date()` setzen

**Was bewusst NICHT triggert:**
- Session-Complete: Der Wert direkt nach dem Training ist trivial (frisch trainierte Muskeln sind ~10% erholt) und liefert keinen analytischen Mehrwert
- Multiple App-Opens am Tag: Der erste Snapshot des Tages reicht — er repräsentiert den Stand "nach der Nacht"

**Begründung 6:00 Uhr Schwelle:**
Wenn man stattdessen "heute 0:00" als Schwelle nähme, würde ein App-Open um 23:50 einen Snapshot erzeugen, der den Tag praktisch beendet — und ein App-Open um 0:10 sofort den nächsten. Mit der 6:00-Uhr-Regel bekommt jeder Tag genau einen Snapshot, der den Erholungsgewinn der Nacht vollständig erfasst.

### 7.3 Pseudo-Code

```swift
// In BaseView.swift oder MotionCoreApp.swift:

@Environment(\.scenePhase) private var scenePhase
@Environment(\.modelContext) private var context

.onChange(of: scenePhase) { _, newPhase in
    guard newPhase == .active else { return }
    triggerDailyMuscleRecoverySnapshotIfNeeded()
}

private func triggerDailyMuscleRecoverySnapshotIfNeeded() {
    let key = "lastMuscleRecoverySnapshotDate"
    let last = UserDefaults.standard.object(forKey: key) as? Date

    let calendar = Calendar.current
    let todaySixAM = calendar.date(
        bySettingHour: 6, minute: 0, second: 0, of: Date()
    ) ?? Date()

    // Nur wenn noch kein Snapshot seit heute 6:00 morgens existiert
    if let last, last >= todaySixAM { return }

    Task {
        let sessions = (try? context.fetch(FetchDescriptor<StrengthSession>(
            predicate: #Predicate { $0.isCompleted }
        ))) ?? []
        let analysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)

        await SupabaseMuscleRecoveryService.shared.uploadSnapshot(
            analysis: analysis,
            triggerSource: "app_open"
        )
        UserDefaults.standard.set(Date(), forKey: key)
    }
}
```

### 7.4 Was wir gewinnen

- **Saubere 1:1 Beziehung:** Jeder Tag hat genau einen Snapshot in Supabase
- **Einfacher Code:** Keine 1h-Dedup-Logik im Service nötig (UserDefaults reicht)
- **Frische UI:** Refresh bei View-Aktivierung statt zufälliger Recompute-Zeitpunkte
- **Konsistente Auswertung:** Trend-Diagramme über Wochen/Monate haben gleichmäßige Datenpunkte

---

## 8. Supabase-Schema

### 8.1 Tabelle

```sql
CREATE TABLE motioncore.muscle_recovery_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    captured_at TIMESTAMPTZ NOT NULL,
    snapshot_date DATE NOT NULL,
    trigger_source TEXT NOT NULL,                  -- 'app_open' (Phase 1)

    chest_recovery NUMERIC(5,2) NOT NULL,
    back_recovery NUMERIC(5,2) NOT NULL,
    shoulders_recovery NUMERIC(5,2) NOT NULL,
    arms_recovery NUMERIC(5,2) NOT NULL,
    legs_recovery NUMERIC(5,2) NOT NULL,
    core_recovery NUMERIC(5,2) NOT NULL,
    glutes_recovery NUMERIC(5,2) NOT NULL,

    chest_trained BOOLEAN NOT NULL DEFAULT FALSE,
    back_trained BOOLEAN NOT NULL DEFAULT FALSE,
    shoulders_trained BOOLEAN NOT NULL DEFAULT FALSE,
    arms_trained BOOLEAN NOT NULL DEFAULT FALSE,
    legs_trained BOOLEAN NOT NULL DEFAULT FALSE,
    core_trained BOOLEAN NOT NULL DEFAULT FALSE,
    glutes_trained BOOLEAN NOT NULL DEFAULT FALSE,

    overall_recovery NUMERIC(5,2) NOT NULL,
    timeframe_days INT NOT NULL DEFAULT 14,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_muscle_recovery_captured_at ON motioncore.muscle_recovery_snapshots(captured_at DESC);
CREATE INDEX idx_muscle_recovery_snapshot_date ON motioncore.muscle_recovery_snapshots(snapshot_date DESC);
```

> **Hinweis:** `related_session_uuid` aus v2 entfällt, da kein Session-Complete-Trigger mehr existiert.

### 8.2 Service-Logik (vereinfacht)

```swift
@MainActor
final class SupabaseMuscleRecoveryService {
    static let shared = SupabaseMuscleRecoveryService()
    private let client = SupabaseClient.shared

    func uploadSnapshot(analysis: MuscleRecoveryAnalysis, triggerSource: String) async {
        let dto = SupabaseMuscleRecoverySnapshotDTO(
            id: UUID(),
            capturedAt: Date(),
            snapshotDate: Calendar.current.startOfDay(for: Date()),
            triggerSource: triggerSource,
            // ... pro MuscleGroup: recoveryPercent + wasTrainedInTimeframe
            overallRecovery: analysis.overallRecoveryPercent,
            timeframeDays: analysis.timeframeDays
        )

        do {
            try await client.insert(
                endpoint: "motioncore.muscle_recovery_snapshots",
                body: dto
            )
        } catch {
            #if DEBUG
            print("⚠️ MuscleRecovery upload failed:", error)
            #endif
        }
    }
}
```

Keine Dedup-Logik im Service nötig — der UserDefaults-Tag-Check im Trigger-Pfad verhindert doppelte Inserts.

---

## 9. Implementierungsreihenfolge

### Phase 1 — Engine + Body-Tab + Sync

| Schritt | Datei(en) | Beschreibung |
|---|---|---|
| 1 | `MuscleRecoveryTypes.swift` | Alle Ergebnis-Typen |
| 2 | `MuscleRecoveryCalcEngine.swift` | Engine mit `analyze(sessions:)` |
| 3 | **STOPP** | Build, Engine mental durchgehen |
| 4 | `MuscleRecoveryDonut.swift` + `MuscleRecoveryCard.swift` | UI-Komponenten |
| 5 | `MuscleRecoveryDetailView.swift` | Detail-Sheet |
| 6 | **STOPP** | Build, Preview testen |
| 7 | `BodyViewModel.swift` + `BodyView.swift` | Neuer Tab-Inhalt mit Refresh-Triggern |
| 8 | `BaseView.swift` | Body-Tab in TabView einfügen |
| 9 | **STOPP** | Build, neuen Tab visuell testen |
| 10 | `SummaryViewModel.swift` | `recoveryAnalysis` Property |
| 11 | `SummaryView.swift` | `MuscleRecoveryCard` einbinden |
| 12 | **STOPP** | Build, SummaryView visuell testen |
| 13 | Supabase-Migration `muscle_recovery_snapshots` | Tabelle + Indices |
| 14 | `SupabaseMuscleRecoverySnapshot.swift` | DTO |
| 15 | `SupabaseMuscleRecoveryService.swift` | Upload-Logik |
| 16 | `BaseView.swift` (oder `MotionCoreApp.swift`) | App-Open-Trigger via scenePhase |
| 17 | **STOPP** | End-to-End-Test: App neu öffnen → Snapshot in Supabase prüfen |

### Phase 2 — Adaptives Modell (separat, später)

Adaptive Anpassung der `baseRecoveryHours` aus tatsächlichem Trainingsverhalten — eigenes Konzept, nicht Teil dieser Phase.

---

## 10. Abhängigkeiten & Risiken

| Risiko | Mitigation |
|---|---|
| Muscle-Resolution dupliziert aus MuscleHeatmapCalcEngine | Phase 1: Copy-Paste mit `// TODO: extract to SharedMuscleResolver`. Phase 2 evaluieren. |
| Decay-Berechnung bei vielen Sessions performant? | 14-Tage-Filter limitiert Datenmenge stark (~200 Sets). Recompute-Kosten sind irrelevant. |
| Body-Tab bricht bestehende Tab-Navigation | `Tab`-Enum erweitern, nur `BaseView.swift` betroffen |
| `rpeRecorded`-Feld konsistent vorhanden? | Phase 1.5 ist abgeschlossen — Feld existiert |
| Supabase Schema-Migration vergessen | `apply_migration` MUSS vor erstem Sync laufen — Schritt 13 ist explizit gelistet |
| User installiert App neu, UserDefaults-Flag fehlt | Beim ersten App-Open nach Reinstall wird sofort ein Snapshot erzeugt (gewünschtes Verhalten) |
| App wird vor 6:00 morgens geöffnet | Trigger-Bedingung greift nicht, nächster App-Open nach 6:00 erzeugt Snapshot — fachlich korrekt |

---

## 11. Edge Cases

1. **Keine Sessions in 14 Tagen:** Alle Gruppen `wasTrainedInTimeframe = false`, alle 100%, alle grau. Card zeigt Hinweis "Noch keine Trainingsdaten". Trotzdem wird ein Snapshot pro Tag erzeugt (alle Werte 100, alle `_trained` = false).
2. **Session ohne RPE/RIR:** Fallback-Kette `rpeRecorded → targetRIR → 1.0 (neutral)`.
3. **Bodyweight-Übungen (weight = 0):** `effectiveWeight = session.bodyWeight > 0 ? session.bodyWeight : 70.0`.
4. **Mehrere Sessions am selben Tag:** Beide werden mit ihrem jeweiligen Decay-Faktor (≈ 1.0) addiert.
5. **App wird nie geöffnet an einem Tag:** Kein Snapshot für diesen Tag. Bei nächstem App-Open wird nur der dann aktuelle Snapshot erzeugt (keine Backfill-Logik in Phase 1).
6. **Supabase nicht erreichbar:** Fail silently, UserDefaults-Flag wird NICHT gesetzt → nächster App-Open versucht es nochmal.
7. **App über mehrere Tage offen, scenePhase wechselt mehrfach:** Pro Wechsel zu `.active` wird die 6-Uhr-Regel geprüft. Erster Wechsel nach 6:00 morgens erzeugt den Snapshot, alle weiteren am gleichen Tag werden geskippt.

---

## 12. Geänderte Annahmen gegenüber v2

| Aspekt | v2 | v3 (final) |
|---|---|---|
| Sync-Trigger | App-Open + Session-Complete | NUR App-Open ab 6:00 Uhr |
| Snapshots pro Tag | 1–4 | Genau 1 |
| Dedup-Logik | 1h-Fenster im Service | UserDefaults-Tag-Check im Trigger |
| `related_session_uuid` Spalte | Vorhanden | Entfällt |
| UI-Refresh-Strategie | Implizit über `recalculate()` | Explizit bei `.onAppear` + `scenePhase`-Wechsel |
| Service-Komplexität | Höher (Fetch + Compare + Insert) | Niedriger (nur Insert) |
