# Domain Validation — MuscleRecoveryCalcEngine

**Datum:** 2026-04-25
**Gesamturteil:** Gelb — implementierbar mit einer Anpassung (bereits angewendet)

---

## Ergebnis pro Parameter

| Parameter | Wert | Bewertung |
|---|---|---|
| baseHours chest | 60h | ✅ Gut |
| baseHours back | 72h | ✅ Gut |
| baseHours shoulders | 48h | ✅ Gut |
| baseHours arms | 48h | ✅ Gut |
| baseHours legs | 72h | ✅ Gut |
| baseHours glutes | 72h | ✅ Gut |
| baseHours core | 36h | ✅ Akzeptabel (= Abs, nicht Erector spinae → fällt unter `back`) |
| Decay Halbwertszeit | 7 Tage | ⚠️ Eher zu lang physiologisch, für App-Zweck akzeptabel |
| Intensitätsfaktor RIR 0 | 1.5 | ✅ Gut |
| Intensitätsfaktor RIR 2 | 1.0 | ✅ Gut |
| Intensitätsfaktor RIR 4+ | 0.5 | ✅ Gut |
| fatigueMultiplier Min | 0.8 | ✅ Gut |
| fatigueMultiplier Max | 1.5 | ✅ Gut |
| Secondary-Faktor | 0.30 | ✅ Gut |
| Volumen-Referenz | ~~1000~~ → **500** | ✅ Korrigiert (s.u.) |
| Bodyweight-Fallback | 70kg | ✅ Vertretbar |

---

## Korrektur: Volumen-Referenz 1000 → 500

**Problem:** `raw / 1000.0` unterschätzt Isolationsübungen systematisch.  
Beispiel: Bizeps Curl 20kg × 12 = 240 → volumeFactor = 0.24 (zu gering).  
Ein Isolation-Muskel fängt von einem typischen Curl-Set genauso viel Reiz wie ein großer Muskel von einer Compound-Bewegung.

**Fix:** `raw / 500.0`  
- Bizeps Curl 20kg × 12 = 240 → 0.48 (realistischer)  
- 100kg Bench × 10 = 1000 → 1.0 (durch Cap begrenzt — korrekt)  
- Schwere Compounds bleiben durch `min(1.0, ...)` gedeckelt

**Status:** Angewendet in `MuscleRecoveryCalcEngine.swift:232`.

---

## Beobachtungen ohne Handlungsbedarf

- **7-Tage-Halbwertszeit:** Bei 5–6×/Woche-Trainern kann totalFatigue dauerhaft hoch bleiben → fatigueMultiplier bei 1.5. Akzeptabel für Phase 1 — Phase 2 adaptive Anpassung löst das.
- **Lineare Erholung:** Physiologisch ist Erholung eher sigmoidal, für Awareness-App gut genug.
- **Intensitätsfaktor:** Linearer RIR-Abfall unterschätzt near-failure leicht, für Phase 1 ausreichend.
- **Core = Abs:** Erector spinae / Multifidus fallen unter `back` — fachlich korrekt, kein Handlungsbedarf.

---

## Gesamturteil

**Gelb — Implementierung freigegeben.** Die Kernlogik ist für Hobby-Kraftsportler (3–5×/Woche) solide. Die einzige notwendige Korrektur (Volumen-Referenz) wurde direkt angewendet. Alle weiteren Unschärfen werden durch Phase-2-Adaptation datengetrieben behoben.
