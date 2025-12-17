//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Extensions Daten-Modell                                          /
// Datei . . . . : CompareableExtension.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Begrenzt universell einen Wert auf einen bestimmten Bereich      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis:                                                                         /
// - Parameter range: Der erlaubte Wertebereich (z.B. 1...25)                       /
// - Returns: Der eingegrenzte Wert                                                 /
//                                                                                  /
// Beispiel:                                                                        /
// let difficulty = 30                                                              /
// let clamped = difficulty.clamped(to: 1...25)                                     /
// Ergebnis: 25                                                                     /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Comparable Extension

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
