//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / Components                                     /
// Datei . . . . : SupersetSelectionHelper.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.05.2026                                                       /
// Beschreibung  : Reine Berechnungs-Helper für In-Session-Superset-Auswahl.        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Pure Struct für Eligibility- und Kontiguität-Checks bei der Superset-Auswahl
/// im aktiven Workout. Stateless — wird bei Bedarf frisch aus cachedGroupedSets erstellt.
struct SupersetSelectionHelper {
    let groupedSets: [[ExerciseSet]]

    /// Gibt true zurück wenn die Übung am Index keine abgeschlossenen Sätze hat.
    func isEligible(at index: Int) -> Bool {
        guard index >= 0, index < groupedSets.count else { return false }
        return groupedSets[index].allSatisfy { !$0.isCompleted }
    }

    /// Gibt true zurück wenn die Übung am Index bereits Teil eines Supersets ist.
    func isInOtherSuperset(at index: Int) -> Bool {
        guard index >= 0, index < groupedSets.count,
              let id = groupedSets[index].first?.supersetGroupId,
              !id.isEmpty else { return false }
        return true
    }

    /// Anzahl der Übungen die theoretisch in ein Superset überführt werden könnten.
    var eligibleCount: Int {
        (0..<groupedSets.count).filter { isEligible(at: $0) }.count
    }

    /// Gibt true zurück wenn die übergebenen Indizes lückenlos aufeinanderfolgen.
    func isContiguous(_ indices: Set<Int>) -> Bool {
        guard indices.count >= 2 else { return false }
        let sorted = indices.sorted()
        return zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
    }

    /// Gibt true zurück wenn aus der aktuellen Auswahl ein Superset erstellt werden darf.
    func canCreateSuperset(from indices: Set<Int>) -> Bool {
        guard indices.count >= 2, indices.count <= 5 else { return false }
        guard isContiguous(indices) else { return false }
        return indices.allSatisfy { isEligible(at: $0) }
    }
}
