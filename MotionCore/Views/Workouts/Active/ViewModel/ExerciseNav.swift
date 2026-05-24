//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / ViewModel                                      /
// Datei . . . . : ExerciseNav.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Verwaltet Exercise-Selektion, Reordering und Superset-Rotation   /
//                 im aktiven Training. Enthält keine SwiftData-Writes (kein save). /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation
import SwiftUI

// MARK: - ExerciseNav

/// Verwaltet die Übungsnavigation während eines aktiven Trainings.
/// Property-Mutationen auf @Model-Objekten (sortOrder) sind erlaubt.
/// context.save() MUSS in der View bleiben.
@MainActor
@Observable
final class ExerciseNav {

    // MARK: - State

    var selectedExerciseKey: String?

    // MARK: - Private

    @ObservationIgnored private var session: StrengthSession?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {}

    // MARK: - Configure

    /// Verdrahtet ExerciseNav mit der Session und dem Superset-Publisher.
    /// supersetKeyChanged: Publisher aus SetManager.exerciseKeyChanged
    func configure(session: StrengthSession, supersetKeyChanged: AnyPublisher<String, Never>) {
        self.session = session
        cancellables.removeAll()

        supersetKeyChanged
            .sink { [weak self] key in
                withAnimation(.easeInOut) {
                    self?.selectedExerciseKey = key
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - API

    func selectExercise(key: String) {
        withAnimation(.easeInOut) {
            selectedExerciseKey = key
        }
    }

    /// Berechnet neue sortOrder-Werte für Reordering — mutiert nur Properties, kein context.save.
    /// Die View ist verantwortlich für context.save() nach diesem Aufruf.
    func reorderExercise(from: Int, to: Int, in groupedSets: [[ExerciseSet]]) {
        guard from != to,
              from >= 0, to >= 0,
              from < groupedSets.count,
              to < groupedSets.count else { return }

        var groups = groupedSets

        // Element aus der alten Position entfernen und an neuer einfügen
        let element = groups.remove(at: from)
        groups.insert(element, at: to)

        // Neue sortOrder-Werte vergeben: Index als neuer sortOrder für alle Sets der Gruppe
        for (newOrder, groupSets) in groups.enumerated() {
            for set in groupSets {
                set.sortOrder = newOrder
            }
        }
    }

    /// Prüft ob der aktuell gewählte Key noch in groupedSets existiert.
    /// Setzt ihn auf nil wenn er nicht mehr vorhanden ist.
    func validateSelectedKey(against groupedSets: [[ExerciseSet]]) {
        guard !groupedSets.isEmpty else { return }

        if let key = selectedExerciseKey,
           !groupedSets.contains(where: { $0.first?.groupKey == key }) {
            selectedExerciseKey = nil
        }
    }

    /// Räumt selectedExerciseKey auf nachdem eine Übung gelöscht wurde.
    func handleDeleted(groupKey: String) {
        if selectedExerciseKey == groupKey {
            selectedExerciseKey = nil
        }
    }
}
