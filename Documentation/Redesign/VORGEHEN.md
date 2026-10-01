# Vorgehensweise für Claude Code — MotionCore Redesign

> **Diese Datei ins Repo-Root legen** (neben `CLAUDE.md`). Sie beschreibt, *wie*
> Claude Code das Redesign Schritt für Schritt umsetzt. Die *Inhalte* stehen in
> `DESIGN-SwiftUI.md` (Regelwerk) und `REDESIGN-PLAN.md` (Arbeitspakete).

---

## 0 · Einmalig: Kontext laden (vor der ersten Zeile Code)

Claude Code soll **zuerst** diese Dateien lesen und nichts davon raten:

1. `DESIGN-SwiftUI.md` — verbindliches Regelwerk (Farben, Typo, `.card()`, Motion, SF Symbols).
2. `REDESIGN-PLAN.md` — die 12 Arbeitspakete (AP 0–11) + Auftragstexte.
3. `design_handoff_active_workout/README.md` — die detaillierte Screen-Spec (für AP 3).
4. Die Prototypen als **visuelle Wahrheit** (im Browser öffnen):
   `MotionCore App.html`, `MotionCore ActiveWorkout.html`.

**Feste Entscheidungen** (nicht neu verhandeln):
- App-weiter Akzent: **Tiefblau `#2C6BCB`**.
- Satz-Karte: **Variante A „Stacked"**. Pausen-Timer: **`inline`**.
- Übungsliste: **aufklappbar**.

---

## 1 · Arbeitsweise (für jedes Arbeitspaket gleich)

> **Eine Regel über allem:** Erst `DESIGN-SwiftUI.md`, dann Code. Keine neuen
> Farben, keine zweite Akzentfarbe, kein Glas, keine Blobs, keine
> Farbverlauf-Fortschritte. Geschäftslogik/Datenflüsse **nicht** anfassen — es ist
> ein reines UI-/Style-Redesign.

Pro AP diese Schleife:

1. **Branch anlegen** — `redesign/ap<NN>-<kurzname>` (z. B. `redesign/ap0-theme`).
2. **Auftragstext** aus `REDESIGN-PLAN.md` (Anhang) als Aufgabe nehmen.
3. **Betroffene Dateien finden** — die im AP genannten `Views/…`-Pfade öffnen,
   *vorhandene* Struktur verstehen, nicht neu erfinden.
4. **Umsetzen** — nur `Theme.*`, `AppFont.*`, `Space/Radius`, `.card()` verwenden;
   gegen den Prototyp als Referenz arbeiten.
5. **Previews** — für jede geänderte View eine SwiftUI-`#Preview` im neuen Stil;
   visuell mit dem Prototyp vergleichen.
6. **Selbstcheck** (Checkliste unten) durchgehen.
7. **Commit + PR** — kleiner, fokussierter PR; im Text auf das AP und den
   Referenz-Prototyp verweisen. **Ein AP = ein PR.**

---

## 2 · Reihenfolge (Abhängigkeiten beachten)

```
Phase 0  AP 0 Theme  →  AP 1 Bausteine        (ZUERST, zusammen mergen)
Phase 1  AP 2 Home  →  AP 3 ActiveWorkout  →  AP 6 Body  →
         AP 5 Statistik  →  AP 4 Workouts  →  AP 7 Training
Phase 2  AP 8 Settings  →  AP 9 Readiness/Shared  →
         AP 10 Watch  →  AP 11 QA & Politur
```

**Wichtig:** AP 0 + 1 **vor allem anderen** und gemeinsam mergen — sonst
kollidieren parallele Screen-PRs ständig an den Tokens. Erst danach dürfen
Screen-APs (auch parallel) starten.

---

## 3 · Selbstcheck vor jedem PR (Definition of Done)

- [ ] Nur `Theme.*`-Farben — **kein** rohes `Color(hex:)`/`.blue/.green/.red` im View-Code.
- [ ] Texte über `AppFont.*`; große Zahlen `.monospacedDigit()`.
- [ ] Flächen über `.card()` (weiß, Hairline) — kein `.glassCard()`/Material mehr (außer TabBar/Sheet).
- [ ] Abstände/Radien aus `Space`/`Radius` (8pt-Raster).
- [ ] Akzent ausschließlich Tiefblau; höchstens 1–2 gesättigte Akzente pro Screen.
- [ ] Keine Blobs/`AnimatedBackground`, keine Farbverlauf-Fortschritte.
- [ ] Icons = SF Symbols, keine Emoji.
- [ ] Reduced Motion respektiert; Hit-Targets ≥ 44pt.
- [ ] Screen entspricht dem Prototyp (Layout, Hierarchie, Abstände).
- [ ] Keine Änderung an Logik/Datenmodell/SwiftData.

---

## 4 · Startbefehl für Claude Code (zum Kopieren)

```
Lies in dieser Reihenfolge: DESIGN-SwiftUI.md, REDESIGN-PLAN.md,
design_handoff_active_workout/README.md. Öffne MotionCore App.html und
MotionCore ActiveWorkout.html als visuelle Referenz. Halte dich strikt an
DESIGN-SwiftUI.md. Beginne mit AP 0 (Theme & Foundations) gemäß dem Auftragstext
in REDESIGN-PLAN.md: lege Theme.swift, AppFont, Space/Radius und den
.card()-Modifier an, ersetze .glassCard() und entferne AnimatedBackground/Blobs,
migriere verstreute Farbwerte auf Theme.* (Checkliste §10 dort). Ändere keine
Geschäftslogik. Lege einen Branch redesign/ap0-theme an und öffne am Ende einen
PR. Arbeite die Selbstcheck-Liste aus VORGEHEN.md ab, bevor du den PR erstellst.
Danach stoppst du und wartest auf mein Review, bevor AP 1 beginnt.
```

Für die folgenden Pakete jeweils denselben Block, aber **„Beginne mit AP n"** und
den passenden Auftragstext/Referenz-Prototyp aus `REDESIGN-PLAN.md` einsetzen.

---

## 5 · Tipps für saubere PRs

- **Klein halten:** lieber AP 2 in „Layout" und „Feinschliff" splitten als einen Riesen-PR.
- **Screenshots in den PR:** Simulator-Screenshot neben den Prototyp legen.
- **Nicht vorgreifen:** ein AP berührt nur seine genannten Pfade; alles andere bleibt.
- **Bei Unklarheit fragen**, statt zu erfinden — besonders wo der Prototyp etwas
  nicht zeigt (dann bewusst leer lassen + Notiz).
