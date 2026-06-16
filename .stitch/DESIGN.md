---
name: MotionCore
colors:
  background: '#F0F7FF'
  background-mid: '#C9E6FF'
  background-deep: '#9BD2FF'
  background-dark: '#050814'
  background-dark-mid: '#081024'
  background-dark-deep: '#0E1A36'
  surface: '#FFFFFF33'
  surface-dark: '#FFFFFF14'
  outline: '#FFFFFF73'
  outline-dark: '#FFFFFF4D'
  on-surface: '#1B1B1D'
  on-surface-dark: '#F3F0F2'
  primary: '#2E6DF0'
  primary-container: '#2E6DF02E'
  on-primary: '#FFFFFF'
  accent-energy: '#F5B400'
  accent-energy-soft: '#F5B4002E'
  accent-body: '#5CC63F'
  accent-body-soft: '#5CC63F2E'
  accent-stat: '#2E6DF0'
  accent-stat-soft: '#2E6DF02E'
  accent-streak: '#FF6B4A'
  accent-streak-soft: '#FF6B4A2E'
  success: '#5CC63F'
  warning: '#FF9500'
  error: '#FF3B30'
typography:
  display-lg:
    fontFamily: SF Pro Rounded
    fontSize: 56px
    fontWeight: '300'
    lineHeight: 60px
  display-md:
    fontFamily: SF Pro Rounded
    fontSize: 40px
    fontWeight: '300'
    lineHeight: 44px
  headline-md:
    fontFamily: SF Pro
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: SF Pro
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
  body-md:
    fontFamily: SF Pro
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: SF Pro
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-xs:
    fontFamily: SF Pro
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 13px
---

# Design System: MotionCore

> Extrahiert aus dem SwiftUI-Quellcode (`MotionCore/` — das Projekt hat kein `./src`;
> Quellen: `Utils/Themes/`, `Components/`, `Views/Shared/Redesign/`, Assets-Katalog).
> Natives iOS-Design-System (SwiftUI, iOS 17+), kein Web-Stack.

## 1. Visual Theme & Atmosphere

MotionCore ist eine iOS-Fitness-App im **Liquid-Glass-Stil**: Die gesamte UI
schwebt als halbtransparente, geblurte Glasflächen über einem diagonalen
Dreifarb-Gradient. Im Light Mode ist die Atmosphäre luftig und kühl — ein
Verlauf von fast-weißem Eisblau (`#F0F7FF`) über softes Himmelblau (`#C9E6FF`)
zu kräftigerem Hellblau (`#9BD2FF`). Im Dark Mode kippt dieselbe Bühne in
tiefes Nachtblau (`#050814` → `#0E1A36`) — dramatisch, aber nie reines Schwarz.
Optional wandern zwei weich geblurte Farb-Blobs (Blau/Violett und Cyan/Blau,
60px Blur, 7–8 s Ease-in-out-Loop) langsam über den Hintergrund und geben der
Fläche eine lebendige, "flüssige" Tiefe.

Die Informationsdichte ist hoch (Dashboard-Charakter mit Ringen, Sparklines,
Chips und Kennzahlen-Cards), wird aber durch konsequente Glas-Hierarchie,
großzügige Card-Innenabstände (16 pt) und weiche, weit gestreute Schatten
ruhig gehalten. Zahlen sind die Helden: große, dünne, gerundete Ziffern
(SF Rounded, Light, bis 64 pt) kontrastieren mit kompakten Caption-Labels.
Jede Funktions-Domäne hat eine eigene Signalfarbe, immer in drei Stufen
(Voll / Soft 18 % / Ink 85 %) — die UI wirkt dadurch bunt akzentuiert, aber
systematisch, nie zufällig.

## 2. Color Palette & Roles

### Primary Foundation

| Name | Wert | Rolle |
|:---|:---|:---|
| **Eisblau-Verlauf (Light)** | `#F0F7FF` → `#C9E6FF` → `#9BD2FF` | App-Hintergrund Light, diagonal (topLeading → bottomTrailing) |
| **Nachtblau-Verlauf (Dark)** | `#050814` → `#081024` → `#0E1A36` | App-Hintergrund Dark, gleiche Diagonale |
| **Glas-Fläche** | Weiß 20 % (Light) / Weiß 8 % (Dark) + `thinMaterial`/`ultraThinMaterial` | Alle Cards, Buttons, Chips — nie opake Flächen |
| **Glas-Kontur** | Weiß 45 % (Light) / Weiß 30 % (Dark), 0.8 pt | Highlight-Stroke auf jeder Glasform |

### Accent & Interactive (MCColor-Palette, je 3 Stufen: Voll / Soft 18 % / Ink 85 %)

| Name | Hex | Rolle |
|:---|:---|:---|
| **Energie-Gelb** (`mcEnergy`) | `#F5B400` | Readiness / Energie-Score |
| **Vital-Grün** (`mcBody`) | `#5CC63F` | Muskelstatus / Erholung |
| **Statistik-Blau** (`mcStat`) | `#2E6DF0` | Statistik / Volumen; de-facto Primärakzent |
| **Streak-Koralle** (`mcStreak`) | `#FF6B4A` | Serien / Motivation |
| **System-Blau** | iOS `Color.blue` | Default-Tint für Icons, FABs, EmptyState |

### Typography & Text Hierarchy

| Rolle | Wert |
|:---|:---|
| Primärtext | `Color.primary` (adaptiv Schwarz/Weiß) |
| Sekundärtext | `Color.secondary` — Labels, Untertitel |
| Tertiärtext | `.tertiary` — Sub-Subtexte in Ringen |
| Akzenttext | Domänenfarbe als `foregroundStyle` (z. B. Ringwert in Tint-Farbe) |

### Functional States

| Zustand | Farbe |
|:---|:---|
| Intensität (6 Stufen) | Grau → Grün → Mint → Gelb → Orange → Rot |
| Übungsqualität | Rot (poor) / Orange (neutral) / Grün (good) |
| Muskel-Erholung | Kontinuierliche HSL-Interpolation Hue 0° (rot, 0 %) → 120° (grün, 100 %), Sättigung 0.75, Helligkeit 0.85 |
| Trainingsprogramme | Blau (manuell), Rot (Fettabbau), Pink (Cardio), Mint (Hügel), Indigo (Zufall), Gelb (Fit-Test) |

## 3. Typography Rules

### Hierarchy & Weights

Ausschließlich **SF Pro (System)** — keine Custom Fonts. Zwei Charaktere:

- **Display-Zahlen**: `SF Rounded`, Weight Light, 36–64 pt — große Messwerte
  (Körperdaten, Readiness). Gerundet + dünn = freundlich, nicht klinisch.
  Hero-Ring-Werte dagegen `SF Rounded Bold` (≈ 28 % der Ringgröße).
- **UI-Text**: SF Pro Dynamic-Type-Stile — `.title2.bold()` für
  Empty-State-/Sektionsüberschriften, `.headline` für Card-Titel,
  `.subheadline .semibold` für Chip-Werte, `.caption`/`.caption2` für Labels
  und Metadaten.

### Spacing Principles

- Alle Kennzahlen mit `.monospacedDigit()` — kein Zittern bei Live-Updates.
- Wert + Label vertikal eng gekoppelt (1–3 pt Abstand), Label immer `.secondary`.
- Kein Letter-Spacing-Tuning, keine `\n` in Texten (separate Views).

## 4. Component Stylings

### Cards (`.glassCard()` — Pflicht-Modifier für alle Cards)

Drei-Schichten-Rezept: (1) weiße Tönung 20 %/8 % (Light/Dark), (2) `thinMaterial`
bzw. `ultraThinMaterial` Blur, (3) weißer Highlight-Stroke 0.8 pt.
Corner-Radius **22 pt, continuous**; Innenpadding **16 pt**; Schatten schwarz
5 % / Radius 12 / y+6 (Light) bzw. 55 % / Radius 20 / y+6 (Dark).

### Buttons (`.glassButton(size:accentColor:)`)

Kreisrunde Glas-Buttons (Standard 60 pt FAB, 36–44 pt Toolbar): gleiche
Glas-Schichten wie Cards plus äußerer **Radial-Glow** in Akzentfarbe
(30 % → 10 % → transparent, 1.33× Button-Durchmesser). Icon als SF Symbol
im Zentrum, Tint meist System-Blau.

### Chips (`MCChip`)

Kapsel mit `ultraThinMaterial`-Füllung und 0.5-pt-Hairline (`primary` 8 %).
Inhalt: SF-Symbol-Icon (15 pt, Domänen-Tint) + Wert (`.subheadline .semibold`,
monospaced) über Label (`.caption2 .secondary`). Padding 12 H / 8 V.

### Ringe (`MCHeroRing`, `MCMiniRing`, `MuscleRecoveryDonut`)

Zentrales Datenvisual: Hero-Ring 170 pt / 13 pt Stroke, runde Linienenden,
Start oben (−90°). Hintergrundring Tint 20 %, Glow-Fill Tint 8 %, Wert in
Tint-Farbe (SF Rounded Bold). Einblendung animiert `.easeOut(0.9 s)`.

### Empty State (`EmptyState` — Pflicht-Komponente)

Glas-Panel (Radius 30, `ultraThinMaterial`, weißer Stroke 20 %) mit
Icon-Kreis 120 pt, SF-Symbol 50 pt in Blau, Titel `.title2.bold()`,
Message `.subheadline .secondary`, Padding 40.

### Navigation

5-Tab-`TabView` (Zusammenfassung, Workouts, Statistik, Körper, Training),
System-Tab-Bar über dem Gradient; Scroll-Inhalte enden 100 pt über der
Unterkante, damit Inhalt unter der schwebenden Tab-Bar ausläuft.

## 5. Layout Principles

### Grid & Structure

Einspaltige Card-Stacks in ScrollViews; Kennzahlen innerhalb von Cards als
HStack-Chips oder 2er-Grids. Keine Max-Width (natives iPhone-Layout).

### Whitespace Strategy

Einheitlicher Modifier `scrollViewContentPadding()`: **oben 22 pt,
horizontal 13 pt, unten 100 pt** (Tab-Bar-Freiraum). Card-Innenabstand 16 pt,
Element-Spacing typisch 8–20 pt, große Gesten (Empty State) 40 pt.

### Alignment & Visual Balance

Text links ausgerichtet, Hero-Visuals (Ringe, große Zahlen) zentriert.
Visuelle Hierarchie über Glas-Tiefe + Farbe, nicht über Linien.

### Responsive Behavior & Touch

Dynamic Type über System-Textstile; Touch-Targets ≥ 36 pt (Glass-Buttons),
FAB 60 pt. Light/Dark vollständig adaptiv über `AppTheme`
(System/Hell/Dunkel umschaltbar).

## 6. Design System Notes for Stitch Generation

### Language to Use

"Liquid-Glass-Fitness-Dashboard auf eisblauem (Light) bzw. nachtblauem (Dark)
Diagonal-Gradient; frosted-glass Cards mit 22-pt-Radius, hauchdünnem weißem
Highlight-Rand und weichem Schatten; große dünne gerundete Zahlen; farbcodierte
Domänen-Akzente."

### Color References

- Statistik-Blau `#2E6DF0` (Primärakzent), Energie-Gelb `#F5B400`,
  Vital-Grün `#5CC63F`, Streak-Koralle `#FF6B4A` — Soft-Variante = 18 % Opazität
  als Flächen-Tint, Vollton für Ringe/Icons/Werte.
- Hintergrund Light `#F0F7FF → #C9E6FF → #9BD2FF`, Dark `#050814 → #081024 → #0E1A36`.

### Component Prompts

1. "Frosted-glass card, 22 pt continuous corner radius, subtle white inner
   stroke, soft drop shadow, on an ice-blue diagonal gradient; inside: headline
   label, a large 170 pt progress ring in `#5CC63F` with bold rounded number 78
   centered, secondary caption below."
2. "Capsule stat chip with ultra-thin blur: small bolt icon in `#F5B400`,
   semibold monospaced value '78' above a tiny secondary label 'Bereitschaft'."
3. "Circular 60 pt floating glass action button with plus icon and a soft blue
   radial glow, bottom-right above a translucent tab bar with 5 items."

### Incremental Iteration

- Domänenfarbe pro Screen konstant halten (Readiness = Gelb, Erholung = Grün,
  Statistik = Blau, Streaks = Koralle); Soft-Stufe nur als Flächen-Tint.
- Nie opake weiße/graue Cards erzeugen — immer Blur + Tönung + Stroke.
- Zahlen zuerst: Werte groß, gerundet, monospaced; Labels klein und sekundär.
- Dark Mode nicht invertieren, sondern auf den Nachtblau-Gradient mit
  stärkeren Schatten (55 %) und schwächerer Glas-Tönung (8 %) wechseln.
