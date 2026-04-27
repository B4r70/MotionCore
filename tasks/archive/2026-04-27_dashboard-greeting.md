# Tageszeit-Begrüßung im Dashboard-Header

**Komplexität:** Small  
**Status:** Done  
**Konzept:** `Documentation/Concepts/MotionCore_Greeting_Header_Instruction.md`

## Scope
- `AppSettings.userSurname` reaktivieren
- `UserSettingsView`: Vorname-TextField ergänzen
- `GreetingCalcEngine.swift` neu anlegen (pure struct, vollständig spezifiziert)
- `SummaryView`: `HeaderView` → `dashboardHeader` tauschen

## NICHT anfassen
- `HeaderView.swift` (andere Tabs nutzen es)
- `SummaryCommandHero` und alle anderen Cards
- BodyView, Statistik, Training, Watch, Widgets

## Steps

### Step 1 — `AppSettings.userSurname` reaktivieren [x]
**File:** `MotionCore/AppSettings.swift`
- `@Published var userSurname: String` mit `didSet { UserDefaults.standard.set(userSurname, forKey: "user.userSurname") }` einkommentieren/ergänzen
- `init()`: `userSurname = UserDefaults.standard.string(forKey: "user.userSurname") ?? ""`
- `userLastName` bleibt auskommentiert

### Step 2 — `UserSettingsView`: Vorname-TextField [x]
**File:** `MotionCore/Views/Settings/View/UserSettingsView.swift`
- Neues `TextField` ganz oben in der Sektion, vor "Geburtsdatum"
- Label "Vorname", Placeholder "Vorname", `keyboardType(.default)`, `textContentType(.givenName)`
- Binding: `$appSettings.userSurname`

### Step 3 — `GreetingCalcEngine.swift` anlegen [x]
**File:** `MotionCore/Services/Calculation/GreetingCalcEngine.swift`
- Vollständiger Code wie im Konzept §3
- `DaytimeBucket` enum (5 Buckets)
- `GreetingCalcEngine` struct mit `greeting(for:at:)`, `bucket(for:)`, `templates(for:)`
- `#Preview` mit allen 5 Buckets

### Step 4 — `SummaryView`: Header tauschen [x]
**File:** `MotionCore/Views/Summary/View/SummaryView.swift`
- `@State private var greetingText: String = ""` ergänzt
- `dashboardHeader`, `formattedDate` und `refreshGreeting()` als private Members ergänzt
- `HeaderView` war nach dem April-Redesign bereits entfernt — `dashboardHeader` direkt als erstes Element im ScrollView-VStack eingefügt
- Kein separater Settings-Button im View gefunden — kein HStack-Wrapper nötig
- `.onAppear { refreshGreeting() }` ergänzt (neben bestehendem `.task`)

## Manual Verification
- [ ] Build grün (`Cmd+B`)
- [ ] Header zeigt Begrüßung + Datum, keine Glass-Card
- [ ] Vorname in Settings → "..., Barto" im Header
- [ ] Vorname leer → nur Begrüßung ohne Komma
- [ ] Settings-Button oben rechts sichtbar
- [ ] Tab-Wechsel → Begrüßung ändert sich (manchmal)
- [ ] Datum deutsches Format: "Sonntag, 26. April"

---

## Fortschritt

**Datum:** 2026-04-26 16:19 Uhr  
**Abgeschlossene Steps:** 1, 2, 3, 4 (alle)  
**Geänderte Dateien:**
- `MotionCore/Models/Core/AppSettings.swift` — `userSurname` auskommentiert und reaktiviert, `userLastName` weiter auskommentiert, Init-Zeile ergänzt
- `MotionCore/Views/Settings/View/UserSettingsView.swift` — Vorname-TextField ganz oben in der Sektion ergänzt
- `MotionCore/Services/Calculation/GreetingCalcEngine.swift` — neu angelegt (pure struct, 5 Buckets × 5 Templates, Preview)
- `MotionCore/Views/Summary/View/SummaryView.swift` — `greetingText` State, `dashboardHeader`, `formattedDate`, `refreshGreeting()` ergänzt; Header als erstes VStack-Element eingefügt

**Hinweis:** `SummaryView` hatte nach dem April-Redesign keinen `HeaderView`-Aufruf mehr — `dashboardHeader` wurde direkt an die erste Position im Scroll-VStack gesetzt.
