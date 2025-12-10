//
//  ContentView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Main content view with tab navigation between different task views
//

import SwiftUI

struct ContentView: View {
    // Access the task manager from environment
    @EnvironmentObject var taskManager: TaskManager
    
    var body: some View {
        TabView {
            // Tab 1: ABCDE Priority List
            ABCDEListView()
                .tabItem {
                    Label("ABCDE", systemImage: "list.number")
                }
            
            // Tab 2: Covey Matrix
            CoveyMatrixView()
                .tabItem {
                    Label("Matrix", systemImage: "square.grid.2x2")
                }
            
            // Tab 3: All Tasks
            AllTasksView()
                .tabItem {
                    Label("All Tasks", systemImage: "checklist")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TaskManager())
    }
}
