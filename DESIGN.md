# MotionCore — Design Guide (SwiftUI)

> **Verbindliche UI-Vorgabe für die MotionCore iOS-App.** Calm Redesign 2026.
> Ziel: helle, ruhige Oberfläche statt dunklem „Liquid Glass" — *data-as-curve*,
> bewusst **nicht** der laute Look gängiger Fitness-Apps. Dies ist die SwiftUI-native
> Fassung des Design Guides; halte dich bei **jeder** UI-Arbeit strikt daran.
>
> **Stand v2 (final):** Akzent = Tiefblau `#2C6BCB` (app-weit). Theme als
> Asset-Catalog-Colorsets (Light + Dark). Dark Mode in Settings umschaltbar.

MotionCore ist ein persönlicher iOS-Fitness-Tracker (Cardio, Outdoor, Kraft, mit
Apple-Watch-Begleiter und HealthKit). SwiftUI + SwiftData.

---

## 1 · Designprinzipien

1. **Ruhig vor laut.** Viel Weißraum, gedämpfte Farben, **eine** Leitfarbe. Sättigung ist die Ausnahme.
2. **Eine Farbe pro Kennzahl.** Jede Metrik hat genau einen ruhigen Farbton — sichtbar nur auf Zahl, Icon oder Füllung, nie als ganze Fläche.
3. **Daten als Kurve.** Ring, Balken, dünne Linie statt Dekoration. Charts minimalistisch.
4. **Karten als einzige Fläche.** Alles lebt in einer Karte mit feiner Hairline-Kontur und flüsterleisem Schatten.
5. **Ehrlich & sachlich.** Fakten und sanfte Empfehlungen statt Motivationsgeschrei.

---

## 2 · Farben — `Theme`

Eine **zentrale** Farbquelle. Im UI-Code **nur** diese semantischen Namen, nie rohe Hexwerte.

**Implementierung:** Jedes Token ist ein **Asset-Catalog-Colorset** mit *Light-* und *Dark-Appearance* (Werte siehe Tabelle). Zugriff über das `Theme`-Enum. Der bestehende `Color(hex: String)`-Initializer (`ColorHexExtension.swift`) bleibt für Einzelfälle — `Theme` selbst nutzt ihn nicht.

```swift
import SwiftUI

enum Theme {
    // Flächen
    static let surfaceApp    = Color("surfaceApp")    // Seiten-Hintergrund
    static let surfaceCard   = Color("surfaceCard")   // Karte
    static let surfaceSunken = Color("surfaceSunken") // Inset · Track · sekundär

    // Text (kühles Navy-Slate, nie reines Schwarz/Weiß)
    static let textPrimary   = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary  = Color("textTertiary")

    // Linien
    static let line     = Color("line")               // Hairline (Standard)
    static let lineSoft = Color("lineSoft")

    // Akzent — EINE Quelle, app-weit. Tiefblau #2C6BCB.
    static let accent      = Color("accent")
    static let accentHover = Color("accentHover")
    static let accentPress = Color("accentPress")
    static let accentSoft  = Color("accentSoft")      // weiche Fläche
    static var accentWash: Color { accent.opacity(0.08) } // 7–13 % Tönung

    // Status / Domäne
    static let success = Color("success")   // Erfolg · Erholung · Body
    static let warning = Color("warning")   // Streak · Rekorde · Kalorien (Amber)
    static let danger  = Color("danger")    // nur Fehler · Puls-Herz

    // Datenreihen (Charts) — in dieser Reihenfolge verwenden
    static let series: [Color] = [
        Color("series1"), // Blau
        Color("series2"), // Teal
        Color("series3"), // Violett
        Color("series4"), // Amber
        Color("series5"), // Rosé
    ]
    static let chartGrid = Color("chartGrid")
}
```

### Token-Werte (Asset Catalog: Light + Dark)

| Token | Light | Dark |
|---|---|---|
| `surfaceApp` | `#F4F6F8` | `#0E141C` |
| `surfaceCard` | `#FFFFFF` | `#171F29` |
| `surfaceSunken` | `#E9EDF1` | `#222C37` |
| `textPrimary` | `#16202B` | `#E8EDF2` |
| `textSecondary` | `#5A6877` | `#9BA8B6` |
| `textTertiary` | `#8A95A2` | `#7C8997` |
| `line` | `#D9E0E7` | `#2A343F` |
| `lineSoft` | `#E9EDF1` | `#222C36` |
| `accent` | `#2C6BCB` | `#2C6BCB` |
| `accentHover` | `#3A7CDC` | `#3A7CDC` |
| `accentPress` | `#21539E` | `#21539E` |
| `accentSoft` | `#D7E4F8` | `#1C2E48` |
| `success` | `#1F9E6E` | `#2FB587` |
| `warning` | `#C7902F` | `#E0A93C` |
| `danger` | `#CF5656` | `#E06B6B` |
| `series1` | `#3A8FC9` | `#5BA8DC` |
| `series2` | `#0F9488` | `#1FB3A4` |
| `series3` | `#7A6FD0` | `#968CE0` |
| `series4` | `#C7902F` | `#E0A93C` |
| `series5` | `#CB6685` | `#D982A0` |
| `chartGrid` | `#E9EDF1` | `#222C37` |

**Domänen-Mapping** (welche Farbe für welche Kennzahl):
`Tagesform → accent` · `Erholung/Body → success` · `Streak/Rekorde → warning` ·
`neutrale Daten/Volumen → series[0]` (Blau) · `Puls → danger` · `Kalorien → warning`.
**Nie mehr als ein bis zwei gesättigte Akzente gleichzeitig sichtbar.**

> **App-Akzent:** **Tiefblau `#2C6BCB`** (app-weit, in Light und Dark identisch — bewusst, damit der Weiß-auf-Akzent-Kontrast erhalten bleibt). `Theme.accent` ist die einzige Stelle. Wirkt der Akzent als *Vordergrund* (Text/Icon/Ring) auf Dunkel zu dunkel, `accentHover` nutzen.

---

## 3 · Typografie

**Schrift = native SF Pro.** Große Zahlen in **SF Pro Rounded**. Zahlen **immer** `.monospacedDigit()` (tabellarisch). Mode-unabhängig.

```swift
enum AppFont {
    static let hero      = Font.system(size: 48, weight: .bold,     design: .rounded)
    static let metric    = Font.system(size: 32, weight: .bold,     design: .rounded)
    static let title     = Font.system(size: 22, weight: .bold)                 // tracking -0.5
    static let headline  = Font.system(size: 17, weight: .semibold)
    static let body      = Font.system(size: 15, weight: .regular)
    static let callout   = Font.system(size: 13, weight: .regular)
    static let caption   = Font.system(size: 12, weight: .regular)
    static let eyebrow   = Font.system(size: 10, weight: .bold)                 // UPPERCASE, tracking +0.6
}
```

- **Titel:** `.tracking(-0.5)`, Bold, `textPrimary`.
- **Eyebrow:** `.textCase(.uppercase)`, `.tracking(0.6)`, `textTertiary`.
- **Große Zahl:** `AppFont.metric/hero` + `.monospacedDigit()`.

**Deutsche Formatierung:** Komma-Dezimal (`82,4 kg`), Schmalleerzeichen-Tausender (`12 480 kg`), 24-Stunden-Zeit (`14:20`), Einheiten `kg / kcal / bpm / km`. `NumberFormatter` mit `locale = Locale(identifier: "de_DE")`.

---

## 4 · Abstände, Radien, Schatten

```swift
enum Space { static let s1=4.0, s2=8.0, s3=12.0, s4=16.0, s5=20.0, s6=24.0, s8=32.0 }
enum Radius { static let sm=10.0, md=14.0, lg=20.0, xl=26.0 }   // pill = .capsule
```

- **Raster:** 8pt. Stapel-Abstand 14–16, Karten-Polster 20–24.
- **Radien:** Kachel `md` 14 · Karte `lg` 20 · Sheet/Hero `xl` 26 · Pille `Capsule()`.
- **Schatten:** flüsterleise. Karten führen mit der **Hairline**, nicht mit Schatten. Kein dunkler Glow. **In Dark trägt die Hairline + der Surface-Helligkeitssprung die Elevation, der Schatten entfällt** (siehe §5/§11).

---

## 5 · Die Karte (Kern-Modifier)

Ersetzt den alten `.glassCard()`-Stil: solide Fläche, weiche Rundung, **1px Hairline**, kaum Schatten. Dark-ready (Farben adaptiv aus `Theme`, Schatten nur in Light).

```swift
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = Space.s6
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
            // Schatten nur in Light; in Dark trägt Hairline + Surface-Sprung die Elevation.
            .shadow(color: scheme == .dark ? .clear : Color(hex: "#16202B").opacity(0.04),
                    radius: 2, y: 1)
    }
}
extension View { func card(padding: CGFloat = Space.s6) -> some View { modifier(CardStyle(padding: padding)) } }
```

Getönte Variante (z. B. Erholungs-Kachel): `surfaceCard` durch `Theme.success.opacity(0.09)` o. ä. ersetzen, Hairline weglassen.

---

## 6 · Bewegung & Zustände

- **Motion:** `.easeOut` (Eingänge), `.easeInOut` (Zustandswechsel). Dauern **0.14 / 0.24 / 0.36 s**. Ringe/Balken animieren ihre Füllung; Sheets gleiten hoch. Keine Bounces, keine Endlos-Loops, kein Parallax.
- **Reduced Motion** respektieren (`@Environment(\.accessibilityReduceMotion)`) — Endzustände bleiben lesbar.
- **Press:** Buttons `.scaleEffect(0.97)`, FAB `0.92`. Kein Farbblitz — Bewegung trägt das Feedback.
- **Transparenz/Blur:** gezielt und selten — nur die gefrostete TabBar und Sheets über Inhalt (`.ultraThinMaterial`). Tönungen sonst flach.

---

## 7 · Ikonografie — SF Symbols

**Native SF Symbols.** Strichgewicht zum Text passend, erben Farbe via `.foregroundStyle(...)`. **Keine Emoji.** Häufige Glyphen: `figure.strengthtraining.traditional`, `dumbbell.fill`, `heart.fill`, `flame.fill`, `bolt.fill`, `crown.fill`, `clock.fill`, `pause.circle.fill`, `forward.fill`, `checkmark` / `checkmark.circle.fill`, `slider.horizontal.3`, `applewatch`, `chevron.right/down/left`, `plus` / `minus`, `flag.fill`, `gearshape`, `trophy.fill`, `chart.bar.fill`.

---

## 8 · Layout

Mobile-first, einspaltig. Fester Nav-Header oben, feste gefrostete `TabBar` unten (5 Tabs: Übersicht · Workouts · Statistik · Body · Training), FAB unten rechts auf Listen-Screens. Inhalt scrollt dazwischen. **Hit-Targets ≥ 44pt.**

---

## 9 · Komponenten-Bausteine (Soll-Aussehen)

| Baustein | Regel |
|---|---|
| **Primär-Button** | voll `Theme.accent`, weiße Schrift, Radius `md`, Höhe ~44, Semibold; Press 0.97 |
| **Sekundär-Button** | `accentSoft`-Fläche, `accent`-Text, 1px `line`-Inset (in Dark `accentSoft` = dunkle Fläche → hellen Akzent-Text, z. B. `accentHover`) |
| **Ghost-Button** | transparent, `accent`-Text, Hover/Press füllt `accentSoft` |
| **Chip** | Capsule; inaktiv `surfaceCard` + 1px Hairline, aktiv voll Akzent + weiße Schrift |
| **Badge** | Capsule, klein, uppercase; soft (getönt) oder solid (voll) |
| **Stat-Kachel** | Eyebrow + große Rounded-Zahl (monospaced) auf blasser Tönung, Radius `md` |
| **Fortschritt/Ring** | Track `surfaceSunken`, Füllung Akzent (einfarbig, **kein Gradient**), animierte Füllung |
| **Sheet** | Bottom-Sheet, Grabber, Radius `xl` oben, `.presentationDetents` |

---

## 10 · Migration vom alten Theme (Checkliste)

- [ ] `Color.blue`/`#0038BD` → `Theme.accent`; `Color.green`-Erfolg → `Theme.success`; `Color.red`/`Color.yellow` für Rekorde/Streak → `Theme.warning` (Amber).
- [ ] `.glassCard()` / dunkles Material → `.card()` (Hairline).
- [ ] `AnimatedBackground`/Blobs entfernen → flacher `Theme.surfaceApp`-Hintergrund.
- [ ] `MCColor.*` (`MCColorPalette.swift`) → `Theme.*` (mcEnergy→accent, mcBody→success, mcStat→series[0], mcStreak→warning); Datei danach entfernen.
- [ ] Fortschritts-Gradienten (`[.blue, .green]`) → einfarbig `Theme.accent`.
- [ ] Große Zahlen: `design: .rounded` + `.monospacedDigit()` sicherstellen.
- [ ] Reines Schwarz/Weiß im Text → `Theme.textPrimary/Secondary/Tertiary`.

---

## 11 · Dark Mode

Dark Mode ist **in den Einstellungen umschaltbar**: System / Hell / Dunkel.

```swift
enum AppColorScheme: String, CaseIterable {
    case system, light, dark
    var resolved: ColorScheme? {           // nil = dem System folgen
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
// Persistenz + Anwendung am App-Root:
@AppStorage("appColorScheme") private var appScheme: AppColorScheme = .system
// …
.preferredColorScheme(appScheme.resolved)
```

Regeln für Dunkel:
- **Werte:** kommen aus der Dark-Appearance der Asset-Catalog-Colorsets (§2-Tabelle). Kein zweiter Code-Pfad.
- **Elevation:** Schatten in Dark weglassen; Hairline (`line`) + Surface-Stufen (App→Card→Sunken) tragen die Tiefe.
- **`accentSoft`:** in Dark eine dunkle Fläche (`#1C2E48`) — Sekundär-/Ghost-Flächen brauchen darauf hellen Akzent-Text (`accentHover`), nicht `accent`.
- **Status/Series** sind in Dark leicht angehoben (Kontrast auf dunklem Grund).
- **Heatmap-SVG** (`MuscleHeatmapSVGView`, injizierte Hex-Strings): die helle sky→accent-Skala ist auf Hell ausgelegt — in Dark eine eigene Injection-Skala verwenden.
- **Kontrast** in **beiden** Modi gegen WCAG AA prüfen (Grenzfall: Weiß auf `accent` sowie Akzent-Text auf `accentSoft`).

---

## Referenzen

- **Token-CSS:** `Documentation/Redesign/tokens/colors.css` (Light + Dark, Tiefblau).
- **Visuelle Wahrheit:** HTML-Prototypen `Documentation/Redesign/MotionCore-App-prototype.html` und `ActiveWorkoutView-prototype.html` bzw. `Documentation/Redesign/source/*.jsx`.
- **Screen-Spezifikation ActiveWorkoutView:** `Documentation/Redesign/README.md` (enthält §2-Tokens als Tabelle + Komponenten Schritt für Schritt).

*© 2025–2026 Bartosz Stryjewski · MotionCore · Calm Redesign 2026.*