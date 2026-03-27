# Domain Validation — Muscles Heatmap: Metrik-Wahl

**Datum:** 2026-03-27
**Status:** Anpassungen empfohlen (Sekundär-Faktor + Bodyweight-Lücke)

---

## Metrik-Empfehlung: Volumen bleibt korrekt

**Volumen (Sets × Reps × Gewicht)** ist der stärkste Einzel-Prädiktor für Muskelwachstum (Hypertrophie-Forschung). Er integriert automatisch sowohl Häufigkeit als auch Gewicht. Die aktuelle Implementierung ist fachlich richtig — keine Metrik-Umstellung nötig.

Intensität allein wäre falsch: ein einzelner schwerer Satz würde Muskeln als "maximal trainiert" markieren, obwohl das Trainingsvolumen minimal war. Frequenz allein wäre falsch: 1 Set zählt gleich wie 5 Sets.

---

## Findings

### [MITTEL] Sekundär-Faktor 0.5 ist zu hoch → 0.3

**Datei:** `MuscleHeatmapCalcEngine.swift` — `volume * 0.5`

Bei Verbundübungen erhalten sekundäre Muskeln in der Realität ca. 30–40 % des primären Stimulus. Der Faktor 0.5 (50 %) überschätzt das systematisch. Bei 4 sekundären Muskeln akkumulieren diese zusammen `4 × 0.5 = 2.0` des Volumens — mehr als die primären Muskeln zusammen. Das erklärt das Quadrizeps-Problem (wenn Beinpresse mit Quads als secondary bei anderen Übungen eingetragen ist).

**Empfehlung:** 0.5 → 0.3

---

### [MITTEL] Bodyweight-Übungen werden komplett ignoriert

**Datei:** `MuscleHeatmapCalcEngine.swift` — `guard volume > 0`

`set.weight = 0` → `volume = 0` → Guard schlägt fehl → Klimmzüge, Liegestütze etc. erscheinen nicht in der Heatmap. Wer ausschließlich Bodyweight trainiert, sieht eine leere Heatmap.

**Empfehlung:** Separater Task. Mögliche Lösung: Bodyweight-Sets mit einem Schätz-Gewicht (z.B. 70 % Körpergewicht aus HealthKit oder einem Default) oder als Frequenz-Punkt mit Minimalvolumen zählen. Produktentscheidung nötig.

---

### [INFO] Relative Normierung zeigt Verteilung, nicht absolute Belastung

`relativeIntensity = volume / maxVolume` — der meisttrainierte Muskel bekommt immer 1.0, unabhängig vom absoluten Trainingsvolumen. In einer leichten Woche erscheint der "Gewinner" trotzdem rot.

Das ist für Heatmaps üblich und akzeptabel. In der UI sollte klar kommuniziert werden: "Relative Verteilung dieser Periode" — nicht "objektiver Trainingsaufwand".

---

## Static Checks

| Parameter | Aktuell | Bewertung |
|---|---|---|
| Primär-Faktor | 1.0 | Korrekt |
| Sekundär-Faktor | 0.5 | Zu hoch → 0.3 |
| `setsByRegion` nur für primary | ja | Korrekt |
| HeatLevel-Schwellen | <0.01/0.10/0.25/0.50/0.75/1.0 | Akzeptabel |
| Bodyweight-Handling | `guard volume > 0` → excluded | Lücke, separater Task |
