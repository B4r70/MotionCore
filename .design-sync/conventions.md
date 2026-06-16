# MotionCore Design Conventions

## App Context
MotionCore is a dark-native iOS fitness app (SwiftUI, iOS 17+). All designs must use a dark background (`#1C1C1E`). The app has 5 tabs: Summary, Workouts, Stats, Body, Training.

## Color System
MotionCore uses a 4-color semantic palette. Never pick colors arbitrarily — each color carries a fixed meaning:

| Token        | Hex       | Semantic role                     |
|-------------|-----------|-----------------------------------|
| mcEnergy    | #F5B400   | Readiness score, energy level     |
| mcBody      | #5CC63F   | Muscle recovery, body status      |
| mcStat      | #2E6DF0   | Statistics, training volume       |
| mcStreak    | #FF6B4A   | Workout streaks, motivation       |

Soft variants (18% opacity) are used as glow backgrounds. Ink variants (85% opacity) for text.

## Typography
- System font: `-apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui`
- Hero numbers (rings): `font-size: 48px; font-weight: 700; font-variant-numeric: tabular-nums`
- Card values: `font-size: 15px; font-weight: 600; font-variant-numeric: tabular-nums`
- Labels: `font-size: 12px; color: rgba(255,255,255,0.55)`
- Captions: `font-size: 10px; color: rgba(255,255,255,0.45)`

## Surfaces & Cards
- App background: `#1C1C1E`
- Material surface (chips, cards): `background: rgba(255,255,255,0.08); backdrop-filter: blur(20px)`
- Border: `0.5px solid rgba(255,255,255,0.08)`
- Card radius: `16px`; Chip/pill radius: `9999px` (Capsule)

## Spacing
8pt grid: `4px / 8px / 12px / 16px / 24px`

## Component Patterns

### MCChip — metric pill
```html
<div style="display:inline-flex;align-items:center;gap:8px;padding:8px 12px;
  background:rgba(255,255,255,0.08);border-radius:9999px;
  border:0.5px solid rgba(255,255,255,0.08)">
  <span style="color:#F5B400;font-size:15px">⚡</span>
  <div>
    <div style="font-size:15px;font-weight:600;color:#fff">78</div>
    <div style="font-size:10px;color:rgba(255,255,255,0.55)">Bereitschaft</div>
  </div>
</div>
```

### MCHeroRing — large SVG progress ring
```html
<svg width="170" height="170" viewBox="0 0 170 170">
  <circle cx="85" cy="85" r="85" fill="rgba(92,198,63,0.08)"/>
  <circle cx="85" cy="85" r="72" fill="none" stroke="rgba(92,198,63,0.2)" stroke-width="13"/>
  <!-- C=452.4; filled=C×(value/100); rotate -90° to start at top -->
  <circle cx="85" cy="85" r="72" fill="none" stroke="#5CC63F" stroke-width="13"
    stroke-dasharray="352.9 99.5" stroke-linecap="round" transform="rotate(-90 85 85)"/>
  <text x="85" y="80" text-anchor="middle" dominant-baseline="middle"
    font-size="48" font-weight="700" fill="#5CC63F">78</text>
  <text x="85" y="102" text-anchor="middle" font-size="17" fill="rgba(255,255,255,0.55)">Bereit</text>
</svg>
```

### MCMiniRing — small recovery ring (62×62)
SVG circle ring, r=25, stroke=6, C=157.1. Color by recovery: low→#FF6B4A, mid→#F5B400, high→#5CC63F.

### MCFactorBar — horizontal progress bar
```html
<div style="display:flex;flex-direction:column;gap:4px">
  <div style="display:flex;justify-content:space-between">
    <span style="font-size:12px;font-weight:500;color:#fff">HRV</span>
    <span style="font-size:12px;color:rgba(255,255,255,0.55)">Mittel</span>
  </div>
  <div style="height:6px;border-radius:9999px;background:rgba(255,255,255,0.18);overflow:hidden">
    <div style="height:100%;width:55%;background:#F5B400;border-radius:9999px"></div>
  </div>
</div>
```

### MCSparkline — mini trend chart
SVG polyline + filled polygon, stroke 1.5px, fill at 18% opacity. Use for 7-point data trends.
