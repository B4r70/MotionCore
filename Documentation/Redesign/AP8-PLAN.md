# AP 8 · Settings & Onboarding — Plan (2026-07-03)

> Branch `redesign/ap8-settings` von `redesign/ap1-shared-components`. Reines UI-Redesign + EINE verlangte funktionale Änderung (Blob-Toggle entfernen).
> Referenz: `source/screens.jsx` (Settings) + Prototyp. 19 Views + AppSettings-Model.

## Plan-Korrektur (am Code verifiziert)
- **Theme-Umschalter existiert BEREITS**: `AppTheme`-Enum (system/light/dark, `.label`, `.colorScheme`), Picker in DisplaySettingsView (`$appSettings.appTheme`), App-Root `.preferredColorScheme(.light)` mit AP-11-Kommentar. → **KEINE neue `@AppStorage("appColorScheme")`-Property** (Handoff-Wortlaut überholt). AP 8 = nur **Blob-Toggle entfernen** (DisplaySettingsView Section "Specials", `showAnimatedBlob`), Picker bleibt.
- Sehr saubere Basis: ~14 rohe Farben, 0 Gradienten, 1 `.ultraThinMaterial` (BodyMeasurementsValueCarousel), 1 `AnimatedBackground` (StudioSetupView).

## Gates (je grün/rot, Build nach jedem; Commit nach visuellem Grün)
- **G1 · Settings-Listen** — MainSettingsView, UserSettingsView, **DisplaySettingsView (Blob-Toggle raus)**, WorkoutSettingsView (Color.orange), BodyMeasurementSettingsView, AboutView, InfoRow, EBikeProfileView (~3 rohe Farben), DataSettingsView, Debug-Sections (DebugReadinessSection/DebugMuscleFatigueSection, Color.orange), Supabase-Sections (SupabaseSyncSection/SupabaseFullBackupSection, green/red → success/danger).
- **G2 · Studio** — StudioSetupView (`AnimatedBackground`→`surfaceApp`), StudioEquipmentEditSheet, StudioEquipmentRow (`Color.accentColor.opacity`→accent).
- **G3 · Onboarding** — BodyMeasurementsValueCarousel (`.ultraThinMaterial`→`.card()`/surfaceSunken, accentColor/green/red DeltaPill→Theme), BodyMeasurementEntrySlide.

## Farb-Map
- Status: Erfolg/fertig → success; Warnung/fällig → warning; Fehler/gelöscht → danger. `Color.accentColor`→`Theme.accent`. Delta-Pill (green/red) → success/danger. Haptic/Debug-Akzente → accent bzw. Theme.
- Segmented Theme-Picker bleibt (System-Control, keine rohen Farben).

## Unangetastet (Logik-Grenze)
- `AppSettings`-Model + alle `@Published`/UserDefaults-didSet (nur Blob-Toggle-VIEW raus, `showAnimatedBlob`-Property bleibt inert im Model).
- DataSettingsView: Import/Export/Delete/FileImporter/ShareSheet/Security-Scoped-Access.
- StudioEquipmentEditSheet: Validierung/Copy-Pattern/`context.insert`+`save`. EBikeProfileView: DatePicker-nil-Handling/computed. BodyMeasurementEntrySlide: HoldButton-Timer + Decimal-Parsing/@FocusState. BodyMeasurementsValueCarousel: KeyPath-Generics/TrendCalcEngine/History-Sheet.
- Debug-Sections (`#if DEBUG`): nur Farben, Logik bleibt.

## Residue-Grep MUSS enthalten: `glassDivider|GlassDivider|.gradient`. Voller Bereichs-Sweep (Views/Settings + Onboarding) nach dem letzten Gate.
