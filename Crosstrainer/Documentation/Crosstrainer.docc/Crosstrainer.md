# ``MotionCore``

## Beschreibung
Die persönliche App "MotionCore" dient zum Tracken meiner Leistungswerte im Fitnessstudio am Crosstrainer "Life Fitness". 
Hierbei geht es darum, dass ich bereits bei der Aufwärmphase (meist 15 Minuten) eine Verbesserung meines Trainings tracke und jederzeit einsehen kann.
Wichtig hierbei ist, dass ich innerhalb von 12 Minuten Power und 3 Minuten Cooldown immer wieder längere Strecken zurücklege. Darüber hinaus berechnet
die App Pace-Werte um auch hier eiunsehen zu können, ob sich meine Leistung auf verschiedenen Ebenen verbessert hat.

## Trainingsgeräte-Anzeige (Life Fitness)

### Übersicht
Das Display des Life-Fitness-Crosstrainers zeigt während des Trainings verschiedene Leistungs- und Statuswerte an.  
Diese Werte können im `WorkoutSession`-Modell gespeichert werden, um Trainingseinheiten später auszuwerten und zu vergleichen.

### Anzeigen und empfohlene Zuordnung

| Anzeige auf dem Gerät | Bedeutung | Zugeordnetes Feld im Modell | Datentyp | Hinweise |
|------------------------|------------|------------------------------|-----------|-----------|
| **Herzfrequenz** | Puls, gemessen über Handsensor oder Brustgurt | `heartRate` | `Int?` | Optional; erscheint nur, wenn ein Sensor aktiv ist. |
| **Kalorien** | Geschätzter Energieverbrauch in Kilokalorien | `calories` | `Double` | Näherungswert des Geräts; reicht für Trendvergleiche aus. |
| **Entfernung** | Zurückgelegte Strecke | `distance` | `Double` | In Kilometern; zentrale Kennzahl für Leistungsvergleich. |
| **Zeit** | Laufzeit der Trainingseinheit | `duration` | `Int` oder `Double` | In Minuten und Sekunden; am besten in Gesamtminuten umrechnen. |
| **Tempo** | Aktuelle oder durchschnittliche Geschwindigkeit | `speed` | `Double` | In km/h; optional, aber nützlich für Diagramme. |
| **Watt** | Mechanische Leistung | `watts` | `Int?` | Optional; hilfreich zur Intensitätsanalyse. |
| **Stufe** | Widerstands- oder Schwierigkeitsgrad | `difficulty` | `Int` | Gerätespezifischer Bereich (typisch 0 – 20). |
| **Programm** | Gewähltes Trainingsprofil | `program` | `Program` (Enum) | z. B. `.fatBurn`, `.cardio`, `.hill`, `.random`, `.fitTest`, `.manual`. |
| **Cool Down** | Abkühl- bzw. Nachlaufphase | `cooldown` | `Int?` oder `Bool` | Optional; im Studio meist 3 Minuten. |

### Hinweise
Durch die Abbildung dieser Anzeigen im Datenmodell können Trainingseinheiten strukturiert erfasst und miteinander verglichen werden.  
Optionale Felder wie `watts` oder `heartRate` dürfen fehlen, ohne dass die Datenspeicherung beeinträchtigt wird.  
Abgeleitete Kennzahlen – z. B. *Tempo pro Minute*, *Kilokalorien pro Minute* oder *Durchschnittspuls* – lassen sich über berechnete Eigenschaften ergänzen.

## Data Model der MotionCore-App
### Persistierte Eigenschaften (SwiftData)

| Feldname | Typ | Einheit/Format | Beschreibung | Validierung / Bereich | Standardwert |
|---|---|---|---|---|---|
| `date` | `Date` | Datum/Zeit | Zeitpunkt der Trainingseinheit. | – | wird im Initializer gesetzt (Standard: `.now`) |
| `duration` | `Int` | Minuten | Gesamtdauer der Einheit. | `> 0` empfohlen | – |
| `distance` | `Double` | Kilometer | Zurückgelegte Strecke. | `didSet`: `>= 0` | – |
| `calories` | `Int` | kcal | Geschätzter Energieverbrauch. | `didSet`: `>= 0` | – |
| `difficulty` | `Int` | Stufe | Gerätestufe/Widerstand. | `didSet`: geklemmt auf `1…25` | `1` |
| `heartRate` | `Int` | bpm | Durchschnittspuls (Apple Watch). | sinnvoller Bereich z. B. `40…220` | – |
| `bodyWeight` | `Int` | kg | Am Gerät eingestelltes Körpergewicht. | `> 0` empfohlen | – |
| `intensityRaw` | `Int` | Enum-RawValue | Persistente Speicherung von `Intensity`. | indirekt über `var intensity` gesetzt | `Intensity.none.rawValue` |
| `trainingProgramRaw` | `String` | Enum-RawValue | Persistente Speicherung von `TrainingProgram`. | indirekt über `var trainingProgram` gesetzt | `TrainingProgram.random.rawValue` |

> **Hinweis:** `intensityRaw` und `trainingProgramRaw` sind die **speicherbaren** Backing-Felder für die typsicheren Eigenschaften `intensity` bzw. `trainingProgram`. So bleibt das Modell migrationsstabil, obwohl Enums in SwiftData als Primitive persistiert werden.

---

### Nicht persistierte, abgeleitete Eigenschaften (zur Anzeige/Auswertung)

| Eigenschaft | Typ | Einheit/Format | Quelle | Beschreibung |
|---|---|---|---|---|
| `intensity` | `Intensity` | – | `intensityRaw` | Typsichere API für die Belastungsintensität. |
| `trainingProgram` | `TrainingProgram` | – | `trainingProgramRaw` | Typsichere API für das Trainingsprogramm. |
| `mets` | `Double` | METs | `calories`, `duration`, `bodyWeight` | Stoffwechseläquivalent: \(\text{METs} = \frac{\text{kcal/h}}{\text{kg}}\). |
| `averageSpeed` | `Double` | m/min | `distance`, `duration` | Durchschnittstempo: \( \frac{\text{km} \times 1000}{\text{min}} \). |

> Diese Werte werden **nicht** gespeichert, sondern bei jedem Zugriff **neu berechnet** (computed properties). Keine Migration nötig, stets konsistent mit den Basisdaten.

### Formatierte UI-Werte (nicht persistiert)

| Eigenschaft | Typ | Ausgabeformat | Quelle | Beschreibung / Zweck |
|---|---|---|---|---|
| `distanceFormatted` | `String` | `"2.98 km"` | `distance` | Formatiert die Distanz auf zwei Nachkommastellen mit Einheit. |
| `durationFormatted` | `String` | `"15 min"` | `duration` | Gibt die Trainingsdauer mit Minuten-Suffix zurück. |
| `caloriesFormatted` | `String` | `"120 kcal"` | `calories` | Zeigt den Energieverbrauch inklusive Einheit an. |
| `heartRateFormatted` | `String` | `"132 bpm"` | `heartRate` | Einheitliche Formatierung der durchschnittlichen Herzfrequenz. |
| `bodyWeightFormatted` | `String` | `"82 kg"` | `bodyWeight` | Anzeige des eingestellten Körpergewichts mit Einheit. |
| `metsFormatted` | `String` | `"8.6 METs"` | `mets` | Formatiert den berechneten MET-Wert auf eine Dezimalstelle. |
| `averageSpeedFormatted` | `String` | `"198 m/min"` | `averageSpeed` | Gibt die durchschnittliche Geschwindigkeit in Metern pro Minute zurück. |
| `summaryLine` | `String` | `"2.98 km • 15 min • 120 kcal"` | Kombination mehrerer Felder | Kompakte, standardisierte Zusammenfassung für Listen- oder Card-Darstellung. |
| `extendesSummaryLine` | `String` | `"2.98 km • 15 min • 120 kcal • 198 m/min • 8.6 METS"` | Kombination mehrerer Felder | Kompakte, standardisierte Zusammenfassung für Listen- oder Card-Darstellung. |

---

> **Hinweis:**  
> Diese formatierten Werte gehören zur Datei `WorkoutSession+UI.swift` und dienen der **Darstellungsschicht (UI)**.  
> Sie greifen auf die gespeicherten oder berechneten Basiswerte der `WorkoutSession` zu,  
> ohne zusätzliche Logik oder Persistenz einzuführen.

---

### 💡 Architekturhinweis
| Ebene | Datei | Verantwortung |
|--------|--------|----------------|
| **Model** | `WorkoutSession.swift` | Datenstruktur, Validierung, Berechnungen |
| **UI-Extension** | `WorkoutSession+UI.swift` | Einheitliche Formatierung für Anzeige |
| **Enums** | `WorkoutTypes.swift` / `WorkoutTypes+UI.swift` | Definition & Darstellung fester Auswahlwerte |

So bleibt deine Architektur **sauber getrennt**:  
Die Logik bleibt im Model, die Präsentation in der Extension — das ist genau die Balance, die man in professionellen Swift-Projekten anstrebt.
