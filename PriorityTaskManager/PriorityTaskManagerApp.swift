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
    @StateObject private var taskManager = TaskManager()
    @StateObject private var taskGroupManager = TaskGroupManager()
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        NotificationManager.shared.requestPermission()
        setupNotificationObserver()
    }

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(taskManager)
                    .environmentObject(taskGroupManager)
                    .environmentObject(purchaseManager)
                    .onAppear {
                        taskGroupManager.rescheduleNotifications(tasks: taskManager.tasks)
                    }
                    .task {
                        await purchaseManager.checkPurchaseStatus()
                    }
            } else {
                OnboardingView()
                    .environmentObject(taskManager)
                    .environmentObject(taskGroupManager)
                    .environmentObject(purchaseManager)
            }
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .taskScheduleChanged,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let tasks = notification.object as? [Task] {
                taskGroupManager.rescheduleNotifications(tasks: tasks)
            }
        }
    }
}
