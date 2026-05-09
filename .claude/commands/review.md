---
description: "Startet einen Codereview eines bestimmten Layers (L1–L5) durch motioncore-reviewer. Erzeugt eine strukturierte Markdown-Datei in .claude/reviews/."
argument-hint: "<L1|L2|L3|L4|L5|all> [optionaler Scope-Hinweis]"
---

# /review {{args}}

Du startest jetzt einen Codereview des MotionCore-Codes über den
`motioncore-reviewer`-Agent.

## Argument-Parsing

Erstes Argument: Layer-Auswahl. Erlaubt: `L1`, `L2`, `L3`, `L4`, `L5`, `all`.
Falls ungültig oder leer: Frage Bartosz, welcher Layer gemeint ist, und
breche ab. Starte den Agent NICHT mit unklarem Scope.

Alle weiteren Argumente: optionaler Scope-Hinweis (z.B. "ohne Watch-Companion",
"nur Workouts-Bereich"), wird wörtlich an den Agent durchgereicht.

## Layer-Definitionen

| Layer | Fokus | Zu untersuchende Bereiche |
|---|---|---|
| **L1** | Architektur | Module-Grenzen, SwiftData→CloudKit→Supabase-Prinzip, CoreSession-Protokoll-Konsistenz, Cross-Layer-Abhängigkeiten, God-Objects |
| **L2** | Models & Persistenz | `@Model`-Klassen, Relationships, Default-Werte, CloudKit-Tauglichkeit, Supabase-Sync-Konsistenz, Migrations-Risiken |
| **L3** | CalcEngines & Services | Pure-Struct-Disziplin, Side-Effect-Freiheit, Edge-Cases, Service-Singletons, Async-Hygiene |
| **L4** | Views & State | SwiftUI-State-Management, `@Published`-Hygiene, Re-Render-Fallen, Performance, `.sheet(item:)`-Konvention |
| **L5** | Cross-Cutting | Error-Handling, Logging, File-Size-Compliance (400/600/800), Dead Code, Naming, TODOs |

## Ablauf

1. **Pre-Flight-Check** — bestätige diese Punkte, bevor du den Agent startest:
   - Liegt `~/developments/MotionCore/.claude/review-schema.md` vor?
     (Wenn nein: Bartosz informieren und abbrechen)
   - Existiert das Verzeichnis `~/developments/MotionCore/.claude/reviews/`?
     (Wenn nein: anlegen)

2. **Datum bestimmen** — `YYYY-MM-DD` für den Dateinamen.

3. **Bei `all`** — verarbeite L1, L2, L3, L4, L5 sequenziell. Vor dem Start
   von L2 (und jedem weiteren Layer) explizit bei Bartosz nachfragen, ob
   der nächste Layer wirklich starten soll, oder ob er die L1-Datei erst
   reviewen will. Dies ist ein STOPP-Gate.

4. **Agent starten** — übergib dem `motioncore-reviewer` exakt diesen
   Auftrag (Werte einsetzen):

   ```
   Layer: {gewählter Layer}
   Datum: {YYYY-MM-DD}
   Output-Datei: ~/developments/MotionCore/.claude/reviews/review-L{n}-{YYYY-MM-DD}.md
   Schema: ~/developments/MotionCore/.claude/review-schema.md

   Zusätzlicher Scope-Hinweis von Bartosz: {weitere Argumente, oder "(keiner)"}

   Halte dich strikt an dein System-Prompt und das Schema.
   Schreibe NICHTS außerhalb der Output-Datei.
   Wenn unklar ist, ob etwas in den Layer gehört, im Zweifel
   weglassen und unter "Beobachtungen für andere Layer" am
   Ende der Datei kurz notieren.
   ```

5. **Nach Agent-Ende** — gib Bartosz folgende Zusammenfassung im Chat aus:
   - Pfad zur erstellten Datei
   - Severity-Verteilung (aus dem Executive Summary lesen)
   - Anzahl Findings mit "Diskussion erwünscht: Ja"
   - Hinweis: "Du kannst die Datei jetzt im Chat reinposten, oder mit
     `/fix-review {IDs}` einzelne Findings an motioncore-developer geben."

## Wichtig

- Du selbst (Claude Code Hauptkonversation) reviewst NICHT.
  Du orchestrierst nur den Agent.
- Du modifizierst KEINE Source-Files in diesem Command.
- Wenn der Agent zwischendurch unsicher ist und nachfragt: leite die
  Frage an Bartosz weiter, antworte nicht selbst.
- Bei `all` niemals ohne STOPP-Gate von Layer zu Layer springen.