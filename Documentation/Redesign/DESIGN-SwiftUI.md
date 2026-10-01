# MotionCore — Design Guide (SwiftUI)

> **Verbindliche UI-Vorgabe für die MotionCore iOS-App.** Calm Redesign 2026.
> Ziel: helle, ruhige Oberfläche statt dunklem „Liquid Glass" — *data-as-curve*,
> bewusst **nicht** der laute Look gängiger Fitness-Apps. Diese Datei ist die
> SwiftUI-native Fassung des Design Guides; halte dich bei **jeder** UI-Arbeit
> strikt daran.

MotionCore ist ein persönlicher iOS-Fitness-Tracker (Cardio, Outdoor, Kraft, mit
Apple-Watch-Begleiter und HealthKit). SwiftUI + SwiftData.

---

## 1 · Designprinzipien

1. **Ruhig vor laut.** Viel Weißraum, gedämpfte Farben, **eine** Leitfarbe. Sättigung
   ist die Ausnahme.
2. **Eine Farbe pro Kennzahl.** Jede Metrik hat genau einen ruhigen Farbton — sichtbar
   nur auf Zahl, Icon oder Füllung, nie als ganze Fläche.
3. **Daten als Kurve.** Ring, Balken, dünne Linie statt Dekoration. Charts minimalistisch.
4. **Karten als einzige Fläche.** Alles lebt in einer weißen Karte mit feiner
   Hairline-Kontur und flüsterleisem Schatten.
5. **Ehrlich & sachlich.** Fakten und sanfte Empfehlungen statt Motivationsgeschrei.

---

## 2 · Farben — `Theme.swift`

Lege **eine** zentrale Farbquelle an. Nutze im UI-Code **nur** diese semantischen
Namen, nie rohe Hexwerte.

```swift
import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: alpha)
    }
}

enum Theme {
    // Flächen
    static let surfaceApp    = Color(hex: 0xF4F6F8)   // Seiten-Hintergrund
    static let surfaceCard   = Color.white            // Karte
    static let surfaceSunken = Color(hex: 0xE9EDF1)   // Inset · Track · sekundär

    // Text (kühles Navy-Slate, nie reines Schwarz)
    static let textPrimary   = Color(hex: 0x16202B)
    static let textSecondary = Color(hex: 0x5A6877)
    static let textTertiary  = Color(hex: 0x8A95A2)

    // Linien
    static let line     = Color(hex: 0xD9E0E7)        // Hairline (Standard)
    static let lineSoft = Color(hex: 0xE9EDF1)

    // Akzent — EINE Konstante, app-weit umschaltbar.
    // App-Standard: Tiefblau #2C6BCB (vom Nutzer festgelegt). DS-Default war Teal #0F9488.
    static let accent      = Color(hex: 0x2C6BCB)
    static let accentHover = Color(hex: 0x3A7CDC)
    static let accentPress = Color(hex: 0x21539E)
    static let accentSoft  = Color(hex: 0xD7E4F8)     // weiche Fläche
    static var accentWash: Color { accent.opacity(0.08) } // 7–13 % Tönung

    // Status / Domäne
    static let success = Color(hex: 0x1F9E6E)   // Erfolg · Erholung · Body
    static let warning = Color(hex: 0xC7902F)   // Streak · Rekorde · Kalorien (Amber)
    static let danger  = Color(hex: 0xCF5656)   // nur Fehler · Puls-Herz

    // Datenreihen (Charts) — in dieser Reihenfolge verwenden
    static let series: [Color] = [
        Color(hex: 0x3A8FC9), // Blau
        Color(hex: 0x0F9488), // Teal
        Color(hex: 0x7A6FD0), // Violett
        Color(hex: 0xC7902F), // Amber
        Color(hex: 0xCB6685), // Rosé
    ]
    static let chartGrid = Color(hex: 0xE9EDF1)
}
```

**Domänen-Mapping** (welche Farbe für welche Kennzahl):
`Tagesform → accent` · `Erholung/Body → success` · `Streak/Rekorde → warning` ·
`neutrale Daten/Volumen → series[0]` (Blau) · `Puls → danger` · `Kalorien → warning`.
**Nie mehr als ein bis zwei gesättigte Akzente gleichzeitig sichtbar.**

> **App-Akzent festgelegt:** **Tiefblau `#2C6BCB`** (app-weit). `Theme.accent` ist die
> einzige Stelle — nie eine zweite Akzentfarbe im View-Code einführen.

---

## 3 · Typografie

**Schrift = native SF Pro.** Große Zahlen in **SF Pro Rounded**. Zahlen **immer**
`.monospacedDigit()` (tabellarisch).

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

**Deutsche Formatierung:** Komma-Dezimal (`82,4 kg`), Schmalleerzeichen-Tausender
(`12 480 kg`), 24-Stunden-Zeit (`14:20`), Einheiten `kg / kcal / bpm / km`. Nutze
`NumberFormatter` mit `locale = Locale(identifier: "de_DE")`.

---

## 4 · Abstände, Radien, Schatten

```swift
enum Space { static let s1=4.0, s2=8.0, s3=12.0, s4=16.0, s5=20.0, s6=24.0, s8=32.0 }
enum Radius { static let sm=10.0, md=14.0, lg=20.0, xl=26.0 }   // pill = .capsule
```

- **Raster:** 8pt. Stapel-Abstand 14–16, Karten-Polster 20–24.
- **Radien:** Kachel `md` 14 · Karte `lg` 20 · Sheet/Hero `xl` 26 · Pille `Capsule()`.
- **Schatten:** flüsterleise. Karten führen mit der **Hairline**, nicht mit Schatten.
  Kein dunkler Glow.

---

## 5 · Die Karte (Kern-Modifier)

Ersetzt den alten `.glassCard()`-Stil: solides Weiß, weiche Rundung, **1px Hairline**,
kaum Schatten.

```swift
struct CardStyle: ViewModifier {
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
            .shadow(color: Color(hex: 0x16202B, alpha: 0.04), radius: 2, y: 1)
    }
}
extension View { func card(padding: CGFloat = Space.s6) -> some View { modifier(CardStyle(padding: padding)) } }
```

Getönte Variante (z. B. Erholungs-Kachel): `surfaceCard` durch `Theme.success.opacity(0.09)`
o. ä. ersetzen, Hairline weglassen.

---

## 6 · Bewegung & Zustände

- **Motion:** `.easeOut` (Eingänge), `.easeInOut` (Zustandswechsel). Dauern
  **0.14 / 0.24 / 0.36 s**. Ringe/Balken animieren ihre Füllung; Sheets gleiten hoch.
  Keine Bounces, keine Endlos-Loops, kein Parallax.
- **Reduced Motion** respektieren (`@Environment(\.accessibilityReduceMotion)`) —
  Endzustände bleiben lesbar.
- **Press:** Buttons `.scaleEffect(0.97)`, FAB `0.92`. Kein Farbblitz — Bewegung trägt
  das Feedback.
- **Transparenz/Blur:** gezielt und selten — nur die gefrostete TabBar und Sheets über
  Inhalt (`.ultraThinMaterial`). Tönungen sonst flach.

---

## 7 · Ikonografie — SF Symbols

**Native SF Symbols.** Strichgewicht zum Text passend, erben Farbe via
`.foregroundStyle(...)`. **Keine Emoji.** Häufige Glyphen:
`figure.strengthtraining.traditional`, `dumbbell.fill`, `heart.fill`, `flame.fill`,
`bolt.fill`, `crown.fill`, `clock.fill`, `pause.circle.fill`, `forward.fill`,
`checkmark` / `checkmark.circle.fill`, `slider.horizontal.3`, `applewatch`,
`chevron.right/down/left`, `plus` / `minus`, `flag.fill`, `gearshape`,
`trophy.fill`, `chart.bar.fill`.

---

## 8 · Layout

Mobile-first, einspaltig. Fester Nav-Header oben, feste gefrostete `TabBar` unten
(5 Tabs: Übersicht · Workouts · Statistik · Body · Training), FAB unten rechts auf
Listen-Screens. Inhalt scrollt dazwischen. **Hit-Targets ≥ 44pt.**

---

## 9 · Komponenten-Bausteine (Soll-Aussehen)

| Baustein | Regel |
|---|---|
| **Primär-Button** | voll `Theme.accent`, weiße Schrift, Radius `md`, Höhe ~44, Semibold; Press 0.97 |
| **Sekundär-Button** | `accentSoft`-Fläche, `accent`-Text, 1px `line`-Inset |
| **Ghost-Button** | transparent, `accent`-Text, Hover/Press füllt `accentSoft` |
| **Chip** | Capsule; inaktiv weiß + 1px Hairline, aktiv voll Akzent + weiße Schrift |
| **Badge** | Capsule, klein, uppercase; soft (getönt) oder solid (voll) |
| **Stat-Kachel** | Eyebrow + große Rounded-Zahl (monospaced) auf blasser Tönung, Radius `md` |
| **Fortschritt/Ring** | Track `surfaceSunken`, Füllung Akzent (einfarbig, **kein Gradient**), animierte Füllung |
| **Sheet** | Bottom-Sheet, Grabber, Radius `xl` oben, `.presentationDetents` |

---

## 10 · Migration vom alten Theme (Checkliste)

- [ ] `Color.blue`/`#0038BD` → `Theme.accent`; `Color.green`-Erfolg → `Theme.success`;
      `Color.red`/`Color.yellow` für Rekorde/Streak → `Theme.warning` (Amber).
- [ ] `.glassCard()` / dunkles Material → `.card()` (weiß, Hairline).
- [ ] `AnimatedBackground`/Blobs entfernen → flacher `Theme.surfaceApp`-Hintergrund.
- [ ] Fortschritts-Gradienten (`[.blue, .green]`) → einfarbig `Theme.accent`.
- [ ] Große Zahlen: `design: .rounded` + `.monospacedDigit()` sicherstellen.
- [ ] Reines Schwarz/Weiß im Text → `Theme.textPrimary/Secondary/Tertiary`.

---

## Referenzen
- Visuelle Wahrheit: HTML-Prototypen im Design-System-Projekt
  (`ui_kits/app/`, `ui_kits/active-workout/`) bzw. die exportierten Standalone-Dateien.
- Screen-Spezifikation ActiveWorkoutView: `design_handoff_active_workout/README.md`
  (enthält §2-Tokens als Tabelle + Komponenten Schritt für Schritt).

*© 2025–2026 Bartosz Stryjewski · MotionCore · Calm Redesign 2026.*
