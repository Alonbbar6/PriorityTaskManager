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
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var taskGroupManager: TaskGroupManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("hasSeenTrialWelcome") private var hasSeenTrialWelcome = false
    @State private var showTrialWelcome = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                ScheduleView()
                    .tabItem { Label("Schedule", systemImage: "calendar") }

                GroupsView()
                    .tabItem { Label("Groups", systemImage: "rectangle.3.group") }

                ABCDEListView()
                    .tabItem { Label("ABCDE", systemImage: "list.number") }

                CoveyMatrixView()
                    .tabItem { Label("Matrix", systemImage: "square.grid.2x2") }

                AllTasksView()
                    .tabItem { Label("All Tasks", systemImage: "checklist") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }

            // Trial expiry warning banner (shows when ≤7 days remain)
            if !purchaseManager.hasPurchased && purchaseManager.isTrialActive && purchaseManager.trialDaysRemaining <= 7 {
                TrialBanner(daysRemaining: purchaseManager.trialDaysRemaining)
            }
        }
        .fullScreenCover(isPresented: .constant(!purchaseManager.hasFullAccess)) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showTrialWelcome) {
            TrialWelcomeSheet {
                showTrialWelcome = false
                hasSeenTrialWelcome = true
            }
        }
        .onAppear {
            if !hasSeenTrialWelcome && !purchaseManager.hasPurchased {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTrialWelcome = true
                }
            }
        }
    }
}

private struct TrialBanner: View {
    let daysRemaining: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.caption)
            Text(daysRemaining == 1
                 ? "1 day left in your free trial"
                 : "\(daysRemaining) days left in your free trial")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange)
        .foregroundColor(.white)
    }
}

private struct TrialWelcomeSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "gift.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
                .padding(.bottom, 20)

            Text("Welcome! You're on a Free Trial")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Enjoy full access to every feature for 30 days — completely free.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            VStack(spacing: 10) {
                TrialFeatureRow(icon: "calendar", color: .orange, text: "Schedule & Timeline")
                TrialFeatureRow(icon: "rectangle.3.group", color: .blue, text: "Task Groups")
                TrialFeatureRow(icon: "square.grid.2x2", color: .purple, text: "Covey Matrix")
                TrialFeatureRow(icon: "wind", color: .teal, text: "Breathing Exercises")
                TrialFeatureRow(icon: "bell.fill", color: .red, text: "Notifications")
            }
            .padding(.top, 28)
            .padding(.horizontal, 40)

            Text("After 30 days, unlock forever for just $4.99.\nNo subscription. No hidden fees.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 24)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Start My Free Trial")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct TrialFeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.subheadline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TaskManager())
            .environmentObject(TaskGroupManager())
    }
}
