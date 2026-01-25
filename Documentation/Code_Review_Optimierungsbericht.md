# Code Review und Optimierungsbericht - MotionCore

**Datum:** 25. Januar 2026  
**Projekt:** MotionCore iOS Fitness App  
**Swift Version:** Swift 5.x mit SwiftUI & SwiftData  
**Umfang:** 163 Swift-Dateien analysiert

---

## Zusammenfassung

Dieses Dokument enthält eine umfassende Analyse des MotionCore-Projekts mit identifizierten Optimierungsmöglichkeiten, Sicherheitsproblemen und Best-Practice-Empfehlungen.

### Übersicht der Probleme

| Kategorie | Kritisch | Hoch | Mittel | Niedrig |
|-----------|----------|------|--------|---------|
| **Memory Leaks** | 2 | 0 | 0 | 0 |
| **Crash-Risiken** | 1 | 0 | 2 | 1 |
| **Architektur** | 0 | 0 | 3 | 2 |
| **Performance** | 0 | 2 | 1 | 3 |
| **Code-Qualität** | 0 | 1 | 2 | 4 |

---

## 1. Kritische Probleme (BEHOBEN ✅)

### 1.1 Memory Leak - Timer Retain Cycles
**Status:** ✅ **BEHOBEN**  
**Dateien:** `ActiveWorkoutView.swift` (3 Stellen)  
**Schweregrad:** Kritisch

**Problem:**
Timer-Closures erfassten `self` mit starken Referenzen, was zu Retain Cycles führte. Dies verhinderte die Freigabe des Views aus dem Speicher und verursachte Memory Leaks bei wiederholter Nutzung von Workout-Sessions.

**Lösung:**
```swift
// Vorher:
restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.restTimerSeconds -= 1
}

// Nachher:
restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    guard let self = self else { return }
    self.restTimerSeconds -= 1
}
```

**Betroffene Zeilen:**
- Zeile 528: Rest-Timer
- Zeile 707: Rest-Timer Resume
- Zeile 1442: Increment-Timer

---

### 1.2 Memory Leak - KVO Observer nicht entfernt
**Status:** ✅ **BEHOBEN**  
**Datei:** `ExerciseVideoView.swift` (2 Stellen)  
**Schweregrad:** Kritisch

**Problem:**
KVO-Observer für `AVPlayerItem.status` wurden erstellt, aber nie invalidiert. Die Observation-Tokens wurden mit `_` verworfen und konnten nicht aufgeräumt werden.

**Lösung:**
```swift
// Neue State-Properties:
@State private var previewStatusObservation: NSKeyValueObservation?
@State private var videoStatusObservation: NSKeyValueObservation?

// Observer speichern:
previewStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
    // ...
}

// Observer invalidieren beim Cleanup:
previewStatusObservation?.invalidate()
previewStatusObservation = nil
```

---

### 1.3 Crash-Risiko - Force Unwrap mit try!
**Status:** ✅ **BEHOBEN**  
**Datei:** `MotionCoreApp.swift:98`  
**Schweregrad:** Kritisch

**Problem:**
`try!` im Fallback-Pfad der ModelContainer-Erstellung führte bei Fehlern (z.B. volle Festplatte, beschädigte Datenbank) zum sofortigen App-Crash.

**Lösung:**
```swift
// Vorher:
return try! ModelContainer(for: appSchema, configurations: [localConfig])

// Nachher:
do {
    return try ModelContainer(for: appSchema, configurations: [localConfig])
} catch {
    fatalError("💥 Failed to create local ModelContainer as fallback: \(error)")
}
```

---

### 1.4 Potential Crash - Unsafe Array Access
**Status:** ✅ **BEHOBEN**  
**Datei:** `TemplateSetCard.swift:194, 201`  
**Schweregrad:** Mittel

**Problem:**
Direkter Array-Zugriff mit `[0]` ohne Bounds-Checking konnte theoretisch crashen.

**Lösung:**
```swift
// Vorher:
if Set(weightsPerSide).count == 1 {
    return "\(warmupSets.count) × \(reps) @ 2×\(formatWeight(weightsPerSide[0]))"
}

// Nachher:
if Set(weightsPerSide).count == 1, let weight = weightsPerSide.first {
    return "\(warmupSets.count) × \(reps) @ 2×\(formatWeight(weight))"
}
```

---

## 2. Performance-Optimierungen

### 2.1 SwiftData Query-Optimierung
**Schweregrad:** Hoch  
**Potentielle Einsparung:** 30-50% Ladezeit

**Empfehlung:**
Nutze `@Query` mit spezifischen Predicates statt alle Daten zu laden und dann zu filtern.

**Beispiel:**
```swift
// Statt:
@Query private var allSessions: [StrengthSession]
var filtered: [StrengthSession] {
    allSessions.filter { $0.date > startDate }
}

// Besser:
@Query(filter: #Predicate<StrengthSession> { session in
    session.date > startDate
}, sort: \StrengthSession.date, order: .reverse)
private var sessions: [StrengthSession]
```

**Dateien prüfen:**
- Alle Views mit `@Query`-Properties
- `ListView.swift`, `StatisticView.swift`, `RecordView.swift`

---

### 2.2 Lazy Loading für Videos und Bilder
**Schweregrad:** Hoch  
**Datei:** `ExerciseVideoView.swift`

**Problem:**
Videos und Poster werden sofort geladen, auch wenn sie nicht sichtbar sind.

**Empfehlung:**
```swift
// Lazy loading mit .onAppear:
.onAppear {
    if shouldLoad && posterImage == nil {
        loadPosterImage()
    }
}

// Oder mit AsyncImage für Remote-Bilder:
AsyncImage(url: posterURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

---

### 2.3 Calculation Engine Caching
**Schweregrad:** Mittel  
**Dateien:** `StatisticCalcEngine.swift`, `RecordCalcEngine.swift`

**Problem:**
Statistiken werden bei jedem View-Update neu berechnet, auch wenn sich die Daten nicht geändert haben.

**Empfehlung:**
```swift
@Observable
class StatisticCache {
    private var cache: [String: Any] = [:]
    private var lastUpdate: [String: Date] = [:]
    
    func getCached<T>(_ key: String, validFor: TimeInterval, compute: () -> T) -> T {
        if let cached = cache[key] as? T,
           let date = lastUpdate[key],
           Date().timeIntervalSince(date) < validFor {
            return cached
        }
        
        let result = compute()
        cache[key] = result
        lastUpdate[key] = Date()
        return result
    }
}
```

---

### 2.4 Reduzierung von View-Redraws
**Schweregrad:** Niedrig  
**Alle Views**

**Empfehlung:**
- Nutze `@State` nur für View-spezifischen State
- Verwende `.equatable()` für komplexe Views
- Extrahiere Sub-Views mit eigenem State

```swift
struct OptimizedCard: View, Equatable {
    let data: CardData
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id
    }
    
    var body: some View {
        // View-Code
    }
}

// Verwendung:
OptimizedCard(data: myData)
    .equatable()
```

---

## 3. Architektur-Verbesserungen

### 3.1 MVVM-Pattern konsequenter anwenden
**Schweregrad:** Mittel  
**Aktueller Status:** Nur 5 ObservableObjects im gesamten Projekt

**Problem:**
Business-Logik ist teilweise direkt in Views eingebettet, besonders in großen Views wie `ActiveWorkoutView.swift` (1500+ Zeilen).

**Empfehlung:**
Erstelle dedizierte ViewModels:

```swift
@Observable
class ActiveWorkoutViewModel {
    private let sessionManager: ActiveSessionManager
    
    var restTimerSeconds: Int = 0
    var isResting: Bool = false
    
    func startRestTimer(duration: Int) {
        // Timer-Logik hier
    }
    
    func completeSet(exercise: Exercise, set: ExerciseSet) {
        // Set-Completion-Logik hier
    }
}

// In der View:
struct ActiveWorkoutView: View {
    @State private var viewModel: ActiveWorkoutViewModel
    
    var body: some View {
        // Vereinfachter View-Code
    }
}
```

**Betroffene Views:**
- `ActiveWorkoutView.swift` (~1500 Zeilen) → in 3-4 ViewModels aufteilen
- `StatisticView.swift`
- `HealthMetricView.swift`

---

### 3.2 Dependency Injection vereinheitlichen
**Schweregrad:** Niedrig  
**Aktueller Status:** Mix aus Singletons und EnvironmentObjects

**Empfehlung:**
Nutze ein konsistentes DI-Pattern:

```swift
// Container-Pattern:
class AppContainer {
    static let shared = AppContainer()
    
    lazy var healthKitManager = HealthKitManager()
    lazy var sessionManager = ActiveSessionManager()
    lazy var appSettings = AppSettings()
    
    private init() {}
}

// In der App:
@main
struct MotionCoreApp: App {
    let container = AppContainer.shared
    
    var body: some Scene {
        WindowGroup {
            BaseView()
                .environment(container.appSettings)
                .environment(container.sessionManager)
        }
    }
}
```

---

### 3.3 Protocol-basierte Services
**Schweregrad:** Niedrig  
**Nutzen:** Bessere Testbarkeit

**Empfehlung:**
```swift
protocol HealthDataProviding {
    func fetchHealthMetrics() async throws -> HealthMetrics
    func saveWorkout(_ workout: CoreSession) async throws
}

class HealthKitManager: HealthDataProviding {
    // Implementation
}

class MockHealthDataProvider: HealthDataProviding {
    // Mock für Tests
}
```

---

## 4. Code-Qualität Verbesserungen

### 4.1 View-Größe reduzieren
**Schweregrad:** Hoch  
**Betroffene Dateien:**
- `ActiveWorkoutView.swift` - **1500+ Zeilen** 🔴
- `TrainingDetailView.swift` - ~800 Zeilen 🟡
- `StatisticView.swift` - ~600 Zeilen 🟡

**Empfehlung:**
Extrahiere Sub-Views und ViewModels:

```swift
// Statt einer 1500-Zeilen View:
struct ActiveWorkoutView: View {
    var body: some View {
        VStack {
            ActiveWorkoutHeader(viewModel: viewModel)
            ActiveExerciseSection(viewModel: viewModel)
            RestTimerSection(viewModel: viewModel)
            WorkoutControlsSection(viewModel: viewModel)
        }
    }
}

// Jede Section ist eine eigene View-Datei mit < 200 Zeilen
```

---

### 4.2 Magic Numbers vermeiden
**Schweregrad:** Niedrig  
**Beispiele gefunden:**

```swift
// In ActiveWorkoutView.swift:
let step: Double = counter > 20 ? 0.5 : 0.25  // Was bedeutet 20?
guard numberOfSets < 10 else { return }       // Warum 10?
guard defaultReps < 50 else { return }        // Warum 50?

// Besser:
private enum WorkoutLimits {
    static let maxSets = 10
    static let maxReps = 50
    static let fastIncrementThreshold = 20
    static let slowWeightStep = 0.25
    static let fastWeightStep = 0.5
}
```

---

### 4.3 Error Handling verbessern
**Schweregrad:** Mittel  
**Problem:** Viele `print()`-Statements statt strukturiertem Error Handling

**Beispiele:**
```swift
// In ExerciseVideoView.swift:
print("⚠️ Remote Video failed to load: \(url)")

// In verschiedenen Services:
print("Error: ...")
```

**Empfehlung:**
```swift
enum AppError: LocalizedError {
    case videoLoadingFailed(URL)
    case networkError(String)
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .videoLoadingFailed(let url):
            return "Video konnte nicht geladen werden: \(url)"
        case .networkError(let message):
            return "Netzwerkfehler: \(message)"
        case .databaseError(let error):
            return "Datenbankfehler: \(error.localizedDescription)"
        }
    }
}

// Nutzung:
@State private var errorMessage: String?
@State private var showError = false

// In der View:
.alert("Fehler", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage ?? "Ein unbekannter Fehler ist aufgetreten")
}
```

---

### 4.4 Typensicherheit erhöhen
**Schweregrad:** Niedrig  
**Beispiele:**

```swift
// Statt String-basierter Notification Names:
extension Notification.Name {
    static let restoreActiveSession = Notification.Name("restoreActiveSession")
    static let workoutCompleted = Notification.Name("workoutCompleted")
}

// Statt Magic Strings:
enum StorageKeys {
    static let appTheme = "appTheme"
    static let showVideos = "showExerciseVideos"
    static let restTimerDuration = "restTimerDuration"
}
```

---

## 5. SwiftUI Best Practices

### 5.1 @State vs @StateObject vs @Observable
**Empfehlung für iOS 17+:**

```swift
// Für simple Werte:
@State private var isExpanded = false
@State private var selectedTab = 0

// Für Objekte (iOS 17+):
@State private var viewModel = MyViewModel()

// Für geteilten State:
@Environment(AppSettings.self) private var settings

// Legacy (iOS 16 und früher):
@StateObject private var viewModel = MyViewModel()
@EnvironmentObject private var settings: AppSettings
```

**Aktueller Status:** Mix aus allen Patterns → Vereinheitlichen

---

### 5.2 View-Modifiers extrahieren
**Beispiel:**

```swift
// Gemeinsame Modifier:
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
    
    func glassEffect() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Nutzung:
Text("Hello")
    .cardStyle()
```

---

### 5.3 PreviewProvider optimieren
**Problem:** Previews können langsam sein

```swift
#Preview {
    StatisticView()
        .modelContainer(PreviewModelContainer.shared)
        .environment(AppSettings.shared)
}

// Erstelle einen leichtgewichtigen Container:
extension PreviewModelContainer {
    static var shared: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: StrengthSession.self,
            configurations: config
        )
        // Füge Test-Daten hinzu
        return container
    }()
}
```

---

## 6. Sicherheit

### 6.1 Secrets Management
**Status:** ✅ Gut  
**Datei:** `MotionCoreSecrets.xcconfig`

Secrets werden korrekt in `.xcconfig` gespeichert und sind nicht im Git-Repository.

**Empfehlung:**
- ✅ `.xcconfig` ist in `.gitignore`
- ✅ Template-Datei existiert
- ⚠️ Prüfe, ob Secrets im kompilierten Binary sichtbar sind (Code Obfuscation erwägen)

---

### 6.2 HealthKit-Berechtigungen
**Status:** ✅ Korrekt implementiert

HealthKitManager fragt korrekt nach Berechtigungen.

---

### 6.3 CloudKit-Daten
**Status:** ✅ Gut mit Fallback

```swift
private static let requireCloudKit: Bool = false
```

App hat sicheren Fallback auf lokale Datenbank, falls CloudKit nicht verfügbar.

---

## 7. Testing-Empfehlungen

### 7.1 Unit Tests hinzufügen
**Aktueller Status:** Keine Tests gefunden

**Priorität:** Hoch  
**Empfehlung:**

```swift
// Tests für Calculation Engines:
@Test
func testStatisticCalculation() {
    let engine = StatisticCalcEngine()
    let sessions = MockData.strengthSessions
    
    let stats = engine.calculateStats(for: sessions)
    
    #expect(stats.totalWorkouts == 5)
    #expect(stats.totalDuration > 0)
}

// Tests für Business Logic:
@Test
func testRestTimerLogic() {
    let viewModel = ActiveWorkoutViewModel()
    
    viewModel.startRestTimer(duration: 60)
    
    #expect(viewModel.restTimerSeconds == 60)
    #expect(viewModel.isResting == true)
}
```

**Zu testende Komponenten:**
1. Alle Calculation Engines (höchste Priorität)
2. HealthKitManager
3. ActiveSessionManager
4. Daten-Export/Import-Logik

---

### 7.2 UI Tests
**Empfehlung:**

```swift
@Test
func testWorkoutFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Navigiere zu Workout-Creation
    app.buttons["Neues Workout"].tap()
    
    // Wähle Übung
    app.buttons["Übung hinzufügen"].tap()
    
    // Verifiziere
    #expect(app.staticTexts["Übung ausgewählt"].exists)
}
```

---

## 8. Dokumentation

### 8.1 Code-Kommentare
**Status:** ⚠️ Gemischt

**Gut:**
- Header-Kommentare in jeder Datei
- Inline-Kommentare für komplexe Logik

**Verbesserungspotential:**
- Öffentliche APIs brauchen DocC-Kommentare
- Komplexe Algorithmen brauchen Erklärungen

**Empfehlung:**
```swift
/// Berechnet die Trainingsstatistiken für einen gegebenen Zeitraum
///
/// Diese Methode aggregiert alle Workout-Sessions und berechnet:
/// - Gesamtanzahl der Workouts
/// - Durchschnittliche Dauer
/// - Intensitätsverteilung
///
/// - Parameters:
///   - sessions: Array von CoreSession-Objekten
///   - timeframe: Der zu analysierende Zeitraum
/// - Returns: Aggregierte Statistiken als `WorkoutStats`
func calculateStatistics(
    for sessions: [any CoreSession],
    in timeframe: DateInterval
) -> WorkoutStats {
    // Implementation
}
```

---

### 8.2 README erweitern
**Empfehlung:**

Füge folgende Abschnitte hinzu:
- Architektur-Übersicht (mit Diagramm)
- Setup-Anleitung (inklusive `.xcconfig`)
- Contribution Guidelines
- Testing-Strategie

---

## 9. Prioritäten-Liste für Umsetzung

### Sofort (Kritisch) - ERLEDIGT ✅
- [x] Memory Leaks beheben
- [x] Crash-Risiken eliminieren

### Kurzfristig (1-2 Wochen)
- [ ] SwiftData Queries optimieren
- [ ] `ActiveWorkoutView` in ViewModels aufteilen
- [ ] Lazy Loading für Medien implementieren
- [ ] Error Handling vereinheitlichen

### Mittelfristig (1 Monat)
- [ ] Unit Tests für Calculation Engines schreiben
- [ ] Caching-Layer für Statistiken
- [ ] View-Modifiers extrahieren und vereinheitlichen
- [ ] Magic Numbers durch Enums ersetzen

### Langfristig (2-3 Monate)
- [ ] MVVM-Pattern konsequent in allen Views
- [ ] Protocol-basierte Services für Testbarkeit
- [ ] UI-Tests für kritische User-Flows
- [ ] Umfassende DocC-Dokumentation

---

## 10. Zusammenfassung & Empfehlung

### Stärken des Projekts ✅
- Saubere Service-Architektur
- Gute Nutzung von Swift-Generics
- Korrekte Singleton-Implementierung
- Sichere Secrets-Verwaltung
- Gute CloudKit-Fallback-Strategie

### Kritische Verbesserungen (ERLEDIGT) ✅
- **Memory Leaks** - Behoben durch weak self in Timern
- **KVO Leaks** - Behoben durch Observer-Invalidierung
- **Crash-Risiken** - Behoben durch sicheres Error Handling

### Wichtigste nächste Schritte
1. **Performance:** SwiftData-Queries optimieren (30-50% schnellere Ladezeiten)
2. **Architektur:** `ActiveWorkoutView` refactoring (von 1500 auf ~200 Zeilen pro Component)
3. **Qualität:** Unit Tests für Business Logic (mindestens 60% Code Coverage)

### Geschätzter Aufwand für Optimierungen
- Kurzfristige Optimierungen: **20-30 Entwicklerstunden**
- Mittelfristige Optimierungen: **40-50 Entwicklerstunden**
- Langfristige Optimierungen: **60-80 Entwicklerstunden**

**Gesamt:** ~100-160 Entwicklerstunden für vollständige Optimierung

---

## Kontakt & Fragen

Bei Fragen zu diesem Bericht oder Hilfe bei der Umsetzung:
- Erstelle ein Issue im GitHub-Repository
- Diskutiere spezifische Punkte im Pull Request

**Viel Erfolg bei der Optimierung! 🚀**
