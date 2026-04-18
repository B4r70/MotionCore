//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : EquipmentWeightRounding.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Equipment-aware Gewichts-Rundung für ProgressionCalcEngine       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Equipment-aware Gewichts-Rundung

enum EquipmentWeightRounding {

    /// Rundet ein Gewicht auf einen gültigen Wert basierend auf dem Studio-Equipment-Profil.
    /// - Parameter weight: Zielgewicht (kann zwischen Sprüngen liegen)
    /// - Parameter equipment: Studio-Gerät mit increment/startWeight/minWeight/maxWeight — nil = generischer Fallback
    /// - Parameter fallbackStep: Sprunggröße wenn kein Equipment zugewiesen (Default aus Exercise.progressionStep)
    /// - Parameter rule: Rundungsrichtung (.nearest für Progression, .floor für Entlastung)
    /// - Returns: Gewicht auf gültigem Sprung, clampt auf minWeight/maxWeight
    ///
    /// Hinweis: intermediateIncrements werden NICHT verwendet — reserviert für Feintuning-Chips in Schritt 1.17.
    static func roundToValidWeight(
        _ weight: Double,
        equipment: StudioEquipment?,
        fallbackStep: Double,
        rule: RoundingRule = .nearest
    ) -> Double {
        let step: Double
        let base: Double
        let minClamp: Double
        let maxClamp: Double?

        if let eq = equipment {
            // Div-by-Zero-Guard: increment 0 würde Division durch Null erzeugen
            step = max(eq.increment, 0.0001)
            base = eq.startWeight
            minClamp = eq.minWeight
            maxClamp = eq.maxWeight
        } else {
            // Kein Equipment: auf Vielfache des fallbackStep runden (Guard: > 0, sonst 2.5)
            step = fallbackStep > 0 ? fallbackStep : 2.5
            base = 0.0
            minClamp = 0.0
            maxClamp = nil
        }

        // Anzahl der Sprünge vom Basisgewicht berechnen
        let stepsRaw = (weight - base) / step
        let stepsRounded: Double
        switch rule {
        case .nearest: stepsRounded = stepsRaw.rounded()
        case .floor:   stepsRounded = stepsRaw.rounded(.down)
        }

        // Kandidaten-Gewicht berechnen und auf gültigen Bereich clampen
        var candidate = base + stepsRounded * step
        candidate = max(candidate, minClamp)
        if let maxW = maxClamp {
            candidate = min(candidate, maxW)
        }
        return candidate
    }

    // MARK: - Rundungsrichtung

    enum RoundingRule {
        /// Nächster gültiger Sprung (für Progressions-Steps)
        case nearest
        /// Nächster niedrigerer gültiger Sprung (für Entlastung bei reduzierter Readiness)
        case floor
    }
}
