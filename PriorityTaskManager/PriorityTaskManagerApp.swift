//
//  PriorityTaskManagerApp.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Main app entry point for Priority Task Manager
//  This app helps users manage tasks using ABCDE Method and Covey Matrix
//

import SwiftUI

@main
struct PriorityTaskManagerApp: App {
    // StateObject to manage tasks throughout the app lifecycle
    @StateObject private var taskManager = TaskManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskManager)
        }
    }
}
