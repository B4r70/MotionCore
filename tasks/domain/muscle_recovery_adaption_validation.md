# Domain Validation — Realistischere Muskel-Erholungsberechnung (v1.1)

**Datum:** 2026-06-09
**Status:** Adjustments Needed — Architektur solide, zwei Kalibrierungsprobleme, kein Richtungsänderungs-Fehler.

## Findings

### 1. `fatigueSaturation = 4.0` saturiert zu früh (§3.1)
Typischer frischer Arbeitssatz (80 kg × 8 → raw 640 → volumeFactor ≈ 0.65, neutrale Intensität) ≈ 0.65 Fatigue/Satz.
- 5–6 Arbeitssätze → totalFatigue ≈ 3.25–3.9 → schon nahe Sättigung
- Echte harte Session (8–14 Sätze + Sekundär) → totalFatigue 8–12, ~3× über Cap
- Konzept-Beispiel "totalFatigue = 0.5 → Mini-Workout" ist unrealistisch klein; echter 2-Satz-Mini-Workout ≈ 1.3 → initialDeficit 0.33 → Start ~67% (nicht 87%).
- **Kernproblem:** Mittlerer Bereich (5–14 Sätze = wo echte Workouts liegen) wird auf initialDeficit = 1.0 zusammengequetscht. 6-Satz- und 14-Satz-Session starten identisch ~0%. Differenzierung existiert nur unter ~5 Sätzen.
- **Empfehlung:** `fatigueSaturation` auf ~8–10. DEBUG-Sektion (Phase 3) validiert: harte Sessions ≈ fatigueSaturation, leichte klar darunter.
- Lineare Interpolation `(1-initialDeficit) + initialDeficit*timeRecovered` ist sportwissenschaftlich vertretbar (vereinfachtes 2-Komponenten-Modell).

### 2. `bodyweightLeverage = 0.35` ist ein Crunch-Wert, kein BW-Durchschnitt (§3.3-A)
0.35 korrekt für Rumpfbeuger, unterschätzt aber große BW-Verbundübungen:
- Push-up ~64% BW, Pull-up/Dip ~95–100% BW, BW-Kniebeuge ~65% BW
- Rücken nach Pull-ups / Brust nach Push-ups werden systematisch als übererholt dargestellt
- Greift **nur** bei `weight == 0` → gewichtete Varianten unbetroffen, Schadenfall limitiert
- **Empfehlung:** Wert auf 0.50 (besserer Erwartungswert über BW-Spektrum). Alt: 3.3-B vorziehen falls Pull-ups/Push-ups prominent.

### 3. `volumeSaturation = 600` (§3.2): validiert
`1 - exp(-raw/600)` differenziert relevanten Bereich korrekt (400→0.49, 640→0.65, 1000→0.81). Bekannte Schwäche (30×20 vs 120×5 identisch) ist explizit zurückgestellt (Volume-Landmarks) → korrekte Priorisierung.

### 4. RIR-Fallback: Engine bereits korrekt
Engine (L219–220) hat `targetRIR`-Fallback bereits implementiert; targetRIR meist 2 → intensityFactor 1.0 (neutral). Kein Handlungsbedarf; Konzept §6 beschreibt es nur ungenau.

## Kritischer Domain-Fehler (Richtungsänderung)?
**Nein.** Architektur korrekt, kein Blocker für Phase 1–2.

## Defaults Check
| Konstante | Aktuell | Bewertung |
|---|---|---|
| fatigueSaturation | 4.0 | Zu niedrig um 2×–2.5×. Startwert 8–10. |
| volumeSaturation | 600.0 | Plausibel |
| bodyweightLeverage | 0.35 | Zu niedrig (Crunch-spezifisch). Kompromiss 0.50 |

## Missing Considerations
- Mit fatigueSaturation = 4.0 werden vermutlich **alle** Sessions als "vollständig erschöpft" geloggt → kein Differenzierungssignal in der DEBUG-Sektion. Das ist das empirische Signal zum Anheben.
- Sekundärmuskeln: initialDeficit aus decayed totalFatigue → "wie hart war letztes Training"-Intuition greift voll nur für Sessions der letzten 1–2 Tage.
