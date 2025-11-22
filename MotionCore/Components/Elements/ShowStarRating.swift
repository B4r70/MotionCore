//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Element                                                       /
// Datei . . . . : IntensityStarView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Ausgabe der Intensität in Sternen                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Display View für Durchschnittsintensität
struct ShowStarRating: View {
    let starRating: Double 
    let starMaxRating: Int
    let starColor: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...starMaxRating, id: \.self) { index in
                Image(systemName: iconName(for: index))
                    .foregroundStyle(starColor)
            }
        }
        .font(.system(size: 20)) // Schriftgröße für die Sterne
    }

    // Bestimmt den SF-Symbol-Namen basierend auf dem Double-Rating
    func iconName(for index: Int) -> String {
        let starValue = Double(index)
        
        // VOLLE STERNE: Wenn das Rating größer oder gleich dem aktuellen Stern-Index ist
        if starRating >= starValue {
            return "star.fill"
            
        // HALBE STERNE: Wenn der Stern-Index genau ein Punkt über dem abgerundeten Rating liegt
        } else if starRating > starValue - 1.0 && starRating < starValue {
            return "star.leadinghalf.fill"
        } else {
            return "star"
        }
    }
}
