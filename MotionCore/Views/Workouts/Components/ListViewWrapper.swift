//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : ListViewWrapper.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.12.2025                                                       /
// Beschreibung  : Wrapper für ListView mit Bindings für Filter                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Wrapper für ListView mit Bindings
struct ListViewWrapper: View {
    @Binding var selectedDeviceFilter: WorkoutDevice
    @Binding var selectedTimeFilter: TimeFilter
    
    var body: some View {
        ListView(
            selectedDeviceFilter: $selectedDeviceFilter,
            selectedTimeFilter: $selectedTimeFilter
        )
    }
}
