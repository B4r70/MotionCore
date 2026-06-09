# Konzept: Realistischere Muskel-Erholungsberechnung

**Komponente:** `MuscleRecoveryCalcEngine`
**Version:** v1.1
**Datum:** 09.06.2026
**Status:** Konzept — Review ausstehend

---

## 1. Problem

Direkt nach einem Training fällt die Recovery der trainierten Muskelgruppen auf ~0 %, **unabhängig davon, wie hart oder kurz das Training war**. Ein 2-Satz-Mini-Workout setzt einen Muskel genauso auf 0 % wie eine harte 20-Satz-Session.

### Root Cause

Das Modell ist rein **zeitbasiert**:

```
recoveryPercent = min(100, (hoursSince / adjusted) * 100)
```

Direkt nach dem Training ist `hoursSince ≈ 0` → `recoveryPercent ≈ 0`. Die akkumulierte `totalFatigue` beeinflusst über `fatigueMultiplier` nur die *Dauer* (`adjusted = baseHours * 0.8…1.5`), **nicht den Startwert**. Die Intensität moduliert also die Steigung der Erholungskurve, aber jeder Trainingsreiz — egal wie klein — beginnt am selben Nullpunkt.

### Zweiter, eigenständiger Fehler (aus realen Daten bestätigt)

In den letzten Sessions ist `body_weight = 0` durchgängig. Damit greift in `normalizedVolume` überall der `70.0`-Fallback. Für Bodyweight-Übungen bedeutet das:

```
effectiveWeight = 70   (statt realistischem Lasteinfluss)
70 kg × 20 reps = 1400 → min(1.0, 1400/500) = 1.0  (Cap gerissen)
```

Ein Bodyweight-Crunch erzeugt damit die **maximal mögliche Volumen-Fatigue** — gleich viel wie ein schwerer Kniebeuge-Satz. Das verstärkt die Über-Erschöpfung zusätzlich. Der harte 500er-Cap nivelliert ohnehin alle mittelschweren bis schweren Sätze auf 1.0.

---

## 2. Zielbild

- Ein leichtes/kurzes Training drückt die Recovery nur **leicht** (z. B. auf 80–90 %).
- Ein hartes Training drückt weiterhin nahe **0 %**.
- Der Volumen-Input differenziert wieder zwischen leichten und schweren Sätzen.
- Bodyweight-Übungen erzeugen einen plausiblen, nicht maximalen Fatigue-Beitrag.
- Rückwärtskompatibel mit `RecoveryTrendCalcEngine` (gleiche `analyze`-Signatur, gleiche `referenceDate`-Semantik).

---

## 3. Lösungsansatz

Drei zusammenhängende Änderungen, alle innerhalb von `MuscleRecoveryCalcEngine`. Reine Funktionen, kein State, keine API-Änderung nach außen.

### 3.1 Fatigue als Startwert (Kern-Fix)

Statt immer bei 0 % zu starten, bestimmt die akkumulierte Fatigue, **wie tief** der Tiefpunkt direkt nach dem Training liegt. Die Erholung füllt dann von diesem Tiefpunkt aus auf 100 % auf.

```swift
// Startdefizit direkt nach dem Training (0…1)
let initialDeficit = min(totalFatigue / Self.fatigueSaturation, 1.0)

// Reiner Zeitanteil der Erholung (0…1)
let timeRecovered = min(1.0, hoursSince / adjusted)

// Recovery beginnt bei (1 - initialDeficit) und füllt auf 100 % auf
let recoveryFraction = (1.0 - initialDeficit) + initialDeficit * timeRecovered
let recoveryPercent = min(100.0, recoveryFraction * 100.0)
```

Wirkung:
- `totalFatigue = 0.5` (leichtes Mini-Workout, `fatigueSaturation = 4`) → `initialDeficit = 0.125` → Start bei ~87 %.
- `totalFatigue ≥ 4` (harte Session) → `initialDeficit = 1.0` → Start bei ~0 % (Verhalten wie bisher).

Die `adjusted`-Dauer bleibt erhalten und steuert weiterhin, wie schnell von diesem Tiefpunkt aufgefüllt wird.

**Neue Konstante:**

```swift
/// Fatigue-Wert, ab dem ein Muskel als vollständig erschöpft gilt (Startdefizit = 100 %)
static let fatigueSaturation: Double = 4.0
```

### 3.2 Volumen-Cap glätten (statt harter Clip)

Den harten `min(1.0, raw/500)`-Clip durch eine glatte Sättigungskurve ersetzen, damit leichte und schwere Sätze wieder auseinanderdriften:

```swift
private static func normalizedVolume(
    weight: Double,
    reps: Int,
    sessionBodyWeight: Double
) -> Double {
    let effectiveWeight = weight > 0 ? weight : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0)
    let raw = effectiveWeight * Double(reps)
    return 1.0 - exp(-raw / volumeSaturation)
}
```

mit:

```swift
/// Sättigungskonstante für die Volumen-Kurve (höher = flacher)
static let volumeSaturation: Double = 600.0
```

Beispielwerte: 200 → 0.28, 600 → 0.63, 1500 → 0.92, 3000 → 0.99. Die Kurve sättigt sanft, ohne hart abzuschneiden.

### 3.3 Bodyweight-Übungen entschärfen

Das eigentliche Problem ist, dass das volle Körpergewicht als Lasthebel in `weight × reps` eingeht, obwohl bei einem Crunch nur ein Bruchteil des Körpergewichts bewegt wird. Zwei Optionen:

**Option 3.3-A (klein, empfohlen):** Körpergewicht-Fallback mit einem Lasthebelfaktor dämpfen.

```swift
let bodyweightLeverage = 0.35   // grober Anteil bewegter Masse bei BW-Übungen
let effectiveWeight = weight > 0
    ? weight
    : (sessionBodyWeight > 0 ? sessionBodyWeight : 70.0) * bodyweightLeverage
```

→ Crunch: `70 × 0.35 × 20 = 490 → ~0.56` statt 1.0. Plausibler.

**Option 3.3-B (größer):** Pro-Übung-Lasthebel aus der Exercise-DB ableiten (z. B. ein `bodyweightLoadFactor`-Feld). Genauer, aber erfordert Datenpflege in `motioncore.exercises` und ein neues Feld. → Zurückstellen, bis die Exercise-Data-Quality-Initiative ohnehin an den Feldern arbeitet.

**Empfehlung:** 3.3-A jetzt, 3.3-B als Backlog-Eintrag.

---

## 4. Kalibrierung

Die Konstanten `fatigueSaturation` und `volumeSaturation` sind **Startwerte aus Bauchgefühl**, keine validierten Zahlen. Grundlage:

- Bei deinem Upper/Lower-Split mit ~8–12 Sätzen pro Muskelgruppe und teils nur einem RPE-erfassten Satz pro Übung liegt eine typische `totalFatigue` grob im Bereich 2–5.
- `fatigueSaturation = 4.0` setzt den „vollständig erschöpft"-Punkt in diesen Bereich.

**Validierungsschritt (Pflicht vor finaler Festlegung):** Nach Implementierung in 2–3 realen Sessions die `totalFatigueScore`-Werte pro Muskel loggen (Feld existiert bereits in `DetailedMuscleRecovery`) und prüfen, ob:
- harte Sessions Werte ≥ `fatigueSaturation` erreichen,
- leichte Sessions deutlich darunter liegen.

Dann `fatigueSaturation` nachjustieren. Empfehlung: temporär ein Debug-Log oder eine Debug-Sektion (analog `DebugReadinessSection`) ergänzen, das die Roh-Fatigue pro Muskel anzeigt.

---

## 5. Betroffene Dateien

| Datei | Änderung |
|---|---|
| `MuscleRecoveryCalcEngine.swift` | Recovery-Formel (3.1), `normalizedVolume` (3.2, 3.3-A), zwei neue Konstanten |
| `MuscleRecoveryTypes.swift` | Keine Änderung (Felder reichen aus) |
| `RecoveryTrendCalcEngine.swift` | Keine Änderung (nutzt `analyze` unverändert) |

Keine Änderung an Signaturen, DTOs, Supabase-Schema oder UI. Der retroaktive Trend (`RecoveryTrendCalcEngine`) rekonstruiert automatisch mit der neuen Formel.

---

## 6. Trade-offs & offene Punkte

- **Set-Count-basierte Fatigue (Option C aus der Diskussion)** — sportwissenschaftlich wäre Fatigue eher an die Anzahl harter Sätze nahe Versagen gekoppelt als an reine Tonnage. Das ist der größte Umbau und überschneidet sich mit dem geplanten **Volume-Landmarks-Feature (MEV/MAV/MRV)**. Bewusst zurückgestellt, um Logik nicht doppelt zu bauen.
- **RIR-Abdeckung:** Da meist nur der letzte Satz `rpeRecorded = true` hat, tragen die übrigen Sätze einen neutralen Intensitätsfaktor (1.0). Das ist akzeptabel, aber falls die Recovery-Werte nach Kalibrierung zu flach wirken, wäre eine Übernahme des `targetRIR` als Fallback-Intensität für nicht-erfasste Sätze ein kleiner Hebel (`targetRIR` ist konsistent gesetzt, meist 2).
- **`body_weight = 0`-Problem:** Liegt außerhalb dieses Konzepts (Session-Erfassung), wird hier nur über den Lasthebelfaktor abgefedert. Falls `bodyWeight` künftig zuverlässig erfasst wird, profitiert die Berechnung automatisch.

---

## 7. Nächster Schritt

Bei Freigabe: Claude-Code-Instruction-Dokument mit nummerierten Phasen und STOPP-Gates erstellen. Vorgeschlagene Phasen:

1. Konstanten + `normalizedVolume` (3.2 + 3.3-A) — STOPP-Gate: Build grün
2. Recovery-Formel (3.1) — STOPP-Gate: Build grün
3. Debug-Logging der Roh-Fatigue für Kalibrierung — STOPP-Gate: Build grün
4. (nach 2–3 Sessions) Kalibrierung der Konstanten — separater Durchlauf
