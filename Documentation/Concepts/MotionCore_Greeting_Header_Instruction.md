# MotionCore — Tageszeit-Begrüßung im Dashboard-Header

**Scope: Klein bis mittel. 1 neue Engine, 1 Settings-Erweiterung, 1 View-Anpassung.**
**Workflow: Standard mit STOPP-Gates nach jedem Step.**

---

## 1. Ziel

Der bisherige Header der `SummaryView` zeigt "MotionCore" + "Übersicht" als generischen `HeaderView`. Stattdessen soll dort eine personalisierte, tageszeit-abhängige und bei jedem View-Open zufällig wechselnde Begrüßung stehen, mit Datum darunter.

**Optisch wie Screenshot 3** ("Hallo, Bartosz" oben groß, kleines Sub-Label darunter), aber mit:
- Tageszeit-spezifischer Anrede ("Guten Morgen, Barto" / "Guten Abend, Barto" etc.)
- Datum als Sub-Label ("Sonntag, 26. April")
- Zufalls-Variation (4–5 Varianten pro Tageszeit, neuer Wechsel bei jedem View-Open)
- Freistehend, **nicht** in einer Glass-Card

**Wichtig**: Der `HeaderView` (generisch, anderswo genutzt) bleibt unverändert. Die `SummaryView` bekommt einen eigenen, neuen Header-Block, der den `HeaderView`-Aufruf ersetzt. Andere Tabs (Body, Statistik, Workouts, Training) bleiben wie sie sind.

---

## 2. Phase 1 — Vornamen-Feld in `AppSettings`

In `AppSettings.swift` ist `userSurname` aktuell auskommentiert. Reaktivieren:

1. `@Published var userSurname: String` mit `didSet`-UserDefaults-Bindung wieder einkommentieren (Key `"user.userSurname"`).
2. Default-Wert in `init()`: `UserDefaults.standard.string(forKey: "user.userSurname") ?? ""`.
3. `userLastName` **bleibt auskommentiert** — wird für die Begrüßung nicht gebraucht.

In `UserSettingsView.swift`:
1. Neues `TextField` für den Vornamen ergänzen (analog zu den bestehenden numerischen Feldern, aber mit `keyboardType(.default)` und `textContentType(.givenName)`).
2. Position: ganz oben in der Sektion, vor "Geburtsdatum".
3. Label "Vorname", Placeholder "Wie sollen wir dich nennen?" oder "Vorname".

**STOPP nach Phase 1.**

---

## 3. Phase 2 — `GreetingCalcEngine`

Neue Datei: `MotionCore/CalcEngines/GreetingCalcEngine.swift`

Pure Struct, keine SwiftUI-Imports, keine Side-Effects. Liefert eine Begrüßungs-Zeichenkette für eine gegebene Uhrzeit und einen Vornamen.

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : GreetingCalcEngine.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : <DATUM>                                                          /
// Beschreibung  : Erzeugt tageszeit-abhängige, zufällige Begrüßungen               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import Foundation

enum DaytimeBucket {
    case earlyMorning   //  4:00 – 09:59
    case morning        // 10:00 – 11:59
    case afternoon      // 12:00 – 17:59
    case evening        // 18:00 – 22:59
    case night          // 23:00 – 03:59
}

struct GreetingCalcEngine {

    /// Liefert eine zufällige Begrüßung passend zur aktuellen Uhrzeit.
    /// - Parameters:
    ///   - name: Vorname. Wenn leer, wird die Begrüßung ohne Namen formatiert.
    ///   - date: Referenzzeit (Default: jetzt).
    /// - Returns: Fertig formatierter String, z.B. "Guten Abend, Barto".
    static func greeting(for name: String, at date: Date = Date()) -> String {
        let bucket = bucket(for: date)
        let template = templates(for: bucket).randomElement() ?? "Hallo"
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return template
        }
        return "\(template), \(trimmed)"
    }

    static func bucket(for date: Date) -> DaytimeBucket {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<10:   return .earlyMorning
        case 10..<12:  return .morning
        case 12..<18:  return .afternoon
        case 18..<23:  return .evening
        default:       return .night
        }
    }

    private static func templates(for bucket: DaytimeBucket) -> [String] {
        switch bucket {
        case .earlyMorning:
            return [
                "Guten Morgen",
                "Moin",
                "Hey, schon wach",
                "Schönen Morgen",
                "Frischer Tag"
            ]
        case .morning:
            return [
                "Guten Morgen",
                "Hallo",
                "Hey",
                "Schön, dich zu sehen",
                "Bereit für heute"
            ]
        case .afternoon:
            return [
                "Hallo",
                "Hey",
                "Guten Tag",
                "Schön, dich zu sehen",
                "Mittendrin"
            ]
        case .evening:
            return [
                "Guten Abend",
                "Hey",
                "Hallo",
                "Feierabend",
                "Schön, dich zu sehen"
            ]
        case .night:
            return [
                "Noch wach",
                "Späte Stunde",
                "Hallo",
                "Hey",
                "Eine ruhige Nacht"
            ]
        }
    }
}
```

**Hinweise:**
- `randomElement()` reicht völlig — keine Persistenz, keine "nicht zweimal hintereinander dasselbe"-Logik. Bei View-Open neu würfeln ist genau das gewünschte Verhalten.
- Die Templates können wir später anpassen — Barto darf hier gerne eigene Vorschläge nachreichen.
- **`#Preview`** mit allen 5 Buckets am Ende der Datei (zeigt jede Bucket einmal mit Demo-Namen).

**STOPP nach Phase 2.**

---

## 4. Phase 3 — Header-Block in `SummaryView`

In `SummaryView.swift`:

### 4.1 State für Begrüßung

Neuer `@State`:
```swift
@State private var greetingText: String = ""
```

Begründung: Wir berechnen die Begrüßung **einmal beim Erscheinen der View** und halten sie, damit sie nicht bei jedem Re-Render flackert. Beim nächsten View-Open (Tab-Wechsel raus und wieder rein) wird sie neu erzeugt → erfüllt "Wechsel bei jedem View-Open".

### 4.2 Neuer Header-Block

In `SummaryView.swift` einen neuen privaten Sub-View ergänzen (innerhalb des Structs, oben nach State / unten vor `body` — Style-Konsistenz beachten):

```swift
// MARK: - Header

private var dashboardHeader: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(greetingText)
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .accessibilityAddTraits(.isHeader)

        Text(formattedDate)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
    .padding(.top, 12)
    .padding(.bottom, 8)
}

private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "de_DE")
    formatter.dateFormat = "EEEE, d. MMMM"
    return formatter.string(from: Date())
}
```

### 4.3 `HeaderView`-Aufruf ersetzen

Den bestehenden `HeaderView(title: "MotionCore", subtitle: "Übersicht")` in der `SummaryView` **entfernen** und durch `dashboardHeader` ersetzen, an gleicher Position. **Vorher prüfen**, ob `HeaderView` woanders in `SummaryView` noch genutzt wird — falls ja, nur den einen ersetzen.

### 4.4 Begrüßung initialisieren

Beim Erscheinen der View:

```swift
.onAppear {
    refreshGreeting()
}
```

Falls `.onAppear` schon existiert: dort `refreshGreeting()` ergänzen, bestehenden Code nicht löschen.

```swift
private func refreshGreeting() {
    greetingText = GreetingCalcEngine.greeting(for: appSettings.userSurname)
}
```

### 4.5 Settings-Button beibehalten

Der Settings-Button rechts (zahnrad in einer pillenförmigen Glass-Pille — sichtbar in Screenshot 1) **bleibt unverändert**. Wenn er aktuell Teil eines Toolbar-Items oder einer separaten Card ist: unverändert lassen. Falls er bisher visuell mit dem `HeaderView` verbunden war, sicherstellen dass er weiterhin oben rechts erscheint.

**Falls der Settings-Button aktuell als rechtes Element neben dem `HeaderView` liegt** und durch das Entfernen des `HeaderView` mit verschwindet: Dann den Header-Block als `HStack` aufbauen, mit `dashboardHeader` links und Settings-Button rechts (so wie er aktuell positioniert ist). Layout-Treue zum Screenshot 1 hat Vorrang.

**STOPP nach Phase 3.**

---

## 5. Verifikation

Nach Build:

1. **Visuell:** Header sieht aus wie Screenshot 3 (Begrüßung links groß, Datum klein darunter, freistehend ohne Card-Background).
2. **Inhaltlich:**
   - Vorname in Settings setzen → Header zeigt "..., Barto"
   - Vorname leeren → Header zeigt nur Begrüßung ohne Komma/Namen
3. **Tageszeit-Test** (Datum/Uhrzeit am Simulator umstellen oder via Schema-Argumente):
   - Morgens (8:00) → "Guten Morgen / Moin / Hey, schon wach / Schönen Morgen / Frischer Tag"
   - Mittags (14:00) → "Hallo / Hey / Guten Tag / ..."
   - Abends (20:00) → "Guten Abend / Feierabend / ..."
   - Nachts (1:00) → "Noch wach / Späte Stunde / ..."
4. **Wechsel-Test:** Tab wechseln (z.B. zu Body, dann zurück zu Übersicht) → Begrüßung sollte sich (häufig, nicht garantiert) ändern. Bei nur 5 Varianten kann zufällig dasselbe rauskommen — das ist okay.
5. **Datum:** "Sonntag, 26. April" — deutsches Locale, Wochentag ausgeschrieben, Tag ohne führende Null, Monat ausgeschrieben.

---

## 6. Definition of Done

- ✅ `AppSettings.userSurname` reaktiviert, persistiert in UserDefaults
- ✅ Vornamen-Feld in `UserSettingsView` ergänzt
- ✅ `GreetingCalcEngine` als pure Struct mit 5 Buckets × 5 Templates, `#Preview` vorhanden
- ✅ `SummaryView`-Header zeigt Begrüßung + Datum, nicht in Card
- ✅ Begrüßung wechselt bei jedem View-Open (via `.onAppear`)
- ✅ Andere Tabs / `HeaderView` unangetastet
- ✅ Build green, keine neuen Warnings
- ✅ Settings-Button oben rechts weiterhin korrekt positioniert

---

## 7. Out of Scope / nicht anfassen

- `HeaderView.swift` selbst (wird von anderen Tabs genutzt)
- Andere `HeaderView`-Aufrufe in der App
- Bestehende Hero-Card `SummaryCommandHero` und alle anderen Cards der `SummaryView`
- BodyView, Statistik, Records, Training, Watch-App, Widgets
- Persistenz der Begrüßung über App-Lifecycle hinaus (jeder View-Open = neuer Würfel)
