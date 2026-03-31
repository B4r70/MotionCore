# Quality Gate — DecimalTextField

**Datum:** 2026-03-31
**Status:** ✅ Bestanden (nach Quick-Fixes)

## Quick-Fixes (bereits angewendet)

- **Finding 4:** `formatValue` Switch durch generische Zeile `String(format: "%.\(decimalPlaces)f", val)` ersetzt
- **Finding 2:** Temperatur-Wrapper mit Kommentar zu bekannten Einschränkungen (0 °C = nil, kein Minus über decimalPad) dokumentiert

## Findings (verbleibend / informativ)

### [Niedrig] onChange-Reihenfolge: redundanter aber harmloser Double-Update
- `DecimalTextField.swift` — beim Focus-Verlust feuern `onChange(text)` und `onChange(isFocused)` beide; führt zu zweifacher `value`-Zuweisung, aber mit identischem Ergebnis. Kein Bug.

### [Niedrig] Externer + interner FocusState auf demselben View
- `OutdoorFormSectionsMetrics.swift` — `.focused($isFocused)` intern + `.focused(focusedField, equals: .xxx)` extern auf demselben View. iOS unterstützt das. Muss im Simulator mit Keyboard-Navigation verifiziert werden.

## Positives

- Kernlogik korrekt: String-Puffer, Formatierung erst bei Focus-Verlust, Komma/Punkt-Normalisierung
- iOS 17 Two-Parameter `onChange(of:)` Syntax korrekt verwendet
- `onAppear` zeigt leer bei 0 — gutes UX-Default
- Alle Suffix-Texte (km, m, km/h, kg, °C) in HStack-Layouts erhalten
- DecimalTextField ist pure View — keine Business-Logik
- Alle Aufrufsites konsistent migriert

## Manual Verification Required

- [ ] Xcode Build (`Cmd+B`) — **Wichtig:** `DecimalTextField.swift` muss im Target registriert sein (File Inspector → Target Membership)
- [ ] OutdoorFormView: Distanz "42" tippen → bleibt "42", Feld verlassen → "42.00"
- [ ] OutdoorFormView: Keyboard-Navigation (Pfeiltasten) — DecimalTextField formatiert korrekt beim programmatischen Focus-Wechsel
- [ ] Temperatur 0 eingeben → Feld leert sich (bekannte Einschränkung, dokumentiert)
- [ ] EBikeProfileView: Gewicht eingeben — kein Nullen-Auffüllen
- [ ] Cardio FormView: Distanz eingeben — kein Nullen-Auffüllen
