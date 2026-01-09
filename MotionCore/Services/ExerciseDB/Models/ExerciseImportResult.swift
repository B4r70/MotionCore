//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : API                                                              /
// Datei . . . . : ExerciseImportResult.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.01.2026                                                       /
// Beschreibung  : Ergebnis-Modell für ExerciseDB API-Batch-Imports                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Dieses Modell wird vom ExerciseImportManager zurückgegeben,      /
//                um das Ergebnis eines Batch-Imports zu dokumentieren.             /
//                Enthält Statistiken über importierte, übersprungene und           /
//                fehlerhafte Übungen.                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Ergebnis-Modell für Batch-Imports von der ExerciseDB API
struct ExerciseImportResult {
    let totalFetched: Int              // Anzahl geladener IDs von API
    let imported: Int                  // Anzahl erfolgreich importierter Übungen
    let skipped: Int                   // Anzahl übersprungener Übungen (bereits vorhanden)
    let errors: [String]               // Array von Fehlermeldungen
}
