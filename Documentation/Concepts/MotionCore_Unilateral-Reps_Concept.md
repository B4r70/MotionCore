# Unilaterale Übungen — Darstellung "pro Seite"

**Status:** Konzept (gewählte Variante A)
**Datum:** 2026-09-30

## Gewählte Variante

**A: Getrennte Labels** — Gewicht als "2× 10 kg", Reps-Label als "Wdh./Seite".
Konsistent mit dem bestehenden 2×-Pattern für Gewichte. Minimaler Umbau.

## Datenmodell

**Kein neues Feld nötig.** Bestehende Konvention:

| Feld | Bedeutung |
|------|-----------|
| `weight` | Total-Gewicht (beide Seiten, z.B. 20 kg) |
| `weightPerSide` | Gewicht pro Seite (z.B. 10 kg) |
| `isUnilateralSnapshot` | `true` = einseitige Übung |
| `reps` | Wiederholungen **pro Seite** (Gym-Konvention) |
| `volume` | `weight × reps` = korrekt (Total × proSeite) |

## Touchpoints

| Stelle | Datei:Zeile | Gewicht | Reps | Änderung |
|--------|-------------|---------|------|----------|
| ActiveSetCard — Big Number | `ActiveSetCard.swift:249` | `set.weight` (Total) | "Wdh." | → "2× {perSide}" + "Wdh./Seite" |
| ActiveSetCard — Letztes Mal | `ActiveSetCard.swift:279` | ✅ "2× X kg" | "Wdh." | → "Wdh./Seite" |
| ExercisesOverviewCard | `ExercisesOverviewCard.swift:509` | `set.weight` (Total) | "Wdh." | → "2× {perSide} kg × N Wdh./S." |
| StrengthDetailView — Set-Zeile | `StrengthDetailView.swift:528` | `set.weight` (Total) | "Wdh." | → "2× {perSide} kg × N Wdh./S." |
| RestTimerCard | `RestTimerCard.swift:178` | ✅ "2× X kg" | N/A | — |
| SetPreviewRow | `SetConfigurationSheet.swift:916` | ✅ "2× X kg" | (Plan) | Optional: "/S." |
| TemplateSetCard | `TemplateSetCard.swift:223,242` | ✅ "2× X kg" | N/A | — |

**4 Stellen MUSS, 1 optional, 2 bereits korrekt.**

## Volumen-Korrektheit

`volume = weight × reps = totalWeight × repsPerSide`
→ Mathematisch korrekt: 20 kg × 12 = 240 (= 10 kg × 12 Wdh. × 2 Seiten).
Keine Änderung an Volume-Berechnung nötig.

## Scope-Abgrenzung

- ❌ Kein Links/Rechts-Split (neues Datenmodell, anderer Scope)
- ❌ Kein `repsPerSide`-Feld (reps SIND bereits pro Seite)
- ❌ Keine Änderung an SetEditSheet (Eingabe bleibt identisch)
- ❌ Keine Änderung an Progression/CalcEngine (reps-Vergleich symmetrisch)
