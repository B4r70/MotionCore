# Quality Gate — E-Bike Outdoor Feature (Phase 1)

**Datum:** 2026-03-30
**Status:** Bestanden (mit 2 Quick-Fixes angewendet)

## Findings

### Behoben

| # | Schwere | Beschreibung | Fix |
|---|---------|-------------|-----|
| 2 | Niedrig | eBikeSection: `.padding(.horizontal)` inkonsistent mit anderen Sections | `.padding(.horizontal)` entfernt |
| 3 | Niedrig | NewWorkoutSheet: Cardio und E-Bike beide `.green` | E-Bike auf `.teal` geaendert |

### Akzeptiert (Phase 1)

| # | Schwere | Beschreibung | Empfehlung |
|---|---------|-------------|------------|
| 1 | Mittel | ListView: `sort()` in body-adjacent computed property (pre-existing) | Phase 2: ViewModel extrahieren |
| 4 | Info | OutdoorFormView: manuelles `.padding(.horizontal)` statt `scrollViewContentPadding()` (konsistent mit FormView) | Kuenftiges Refactoring |
| 5 | Info | Wartungsberechnung approximativ (200 km/Monat hardcoded) | Spaeter: echten km-Stand nutzen |
| 7 | Info | Supabase Upload nach `dismiss()` (pre-existing Pattern) | Langfristig: dismiss() nach Task |

## Positives

- CloudKit-kompatibel: alle neuen Properties mit Defaults
- CalcEngine als pure Struct (kein SwiftUI-Import)
- ViewModel cached alle Outdoor-KPIs korrekt
- Supabase DTO vollstaendig mit CodingKeys
- CLAUDE.md-konform: deutsche Kommentare, englische Variablen
- Dateigroessen-Limit eingehalten (Sections auf 2 Dateien gesplittet)

## Manuell zu pruefen

- [ ] Xcode Build (`Cmd+B`) — alle neuen Dateien zum Target hinzufuegen
- [ ] E-Bike Profil in Einstellungen oeffnen und Werte speichern
- [ ] Tour erfassen: "+" → "E-Bike Tour" → Formular → Speichern
- [ ] ListView: Outdoor-Filter, Card, Detail, Swipe-Delete
- [ ] StatisticView: E-Bike Section nur bei vorhandenen Touren
- [ ] Supabase Console-Log nach Tour-Erfassung
- [ ] Regression: Cardio/Kraft-Flows unveraendert
