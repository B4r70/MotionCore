//
//  ListViewWrapper.swift
//  MotionCore
//
//  Created by Barto on 09.12.25.
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
