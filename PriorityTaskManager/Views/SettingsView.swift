import SwiftUI
import UserNotifications
import UIKit
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var groupManager: TaskGroupManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    @State private var notificationsEnabled = false
    @State private var showClearAlert = false
    @State private var dataCleared = false
    @State private var showDeleteModelAlert = false
    #if os(iOS)
    @StateObject private var aiAssistant = TaskAIAssistant()
    #endif
    @State private var showOnboardingReplay = false
    @State private var showMailComposer = false
    @State private var mailSubject = ""
    @State private var showNoMailAlert = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""

    var body: some View {
        NavigationView {
            List {
                // MARK: - Premium
                Section {
                    if purchaseManager.hasPurchased {
                        HStack {
                            Label("Full Access", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Spacer()
                            Text("Unlocked")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    } else if purchaseManager.isTrialActive {
                        HStack {
                            Label("Free Trial", systemImage: "clock.fill")
                            Spacer()
                            Text("\(purchaseManager.trialDaysRemaining) days left")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        Button {
                            _Concurrency.Task { await triggerPurchase() }
                        } label: {
                            HStack {
                                Label("Unlock Forever", systemImage: "lock.open.fill")
                                Spacer()
                                if purchaseManager.isLoading {
                                    ProgressView()
                                } else {
                                    Text("$4.99")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(purchaseManager.isLoading)
                    } else {
                        Button {
                            _Concurrency.Task { await triggerPurchase() }
                        } label: {
                            HStack {
                                Label("Unlock Forever", systemImage: "lock.open.fill")
                                Spacer()
                                if purchaseManager.isLoading {
                                    ProgressView()
                                } else {
                                    Text("$4.99")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(purchaseManager.isLoading)
                    }

                    Button {
                        _Concurrency.Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Label("Restore Purchase", systemImage: "arrow.clockwise")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Premium")
                }

                // MARK: - Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    .onChange(of: notificationsEnabled) { enabled in
                        if enabled {
                            NotificationManager.shared.requestPermission()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                checkNotificationStatus()
                            }
                        } else {
                            openAppSettings()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                checkNotificationStatus()
                            }
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(notificationsEnabled
                        ? "Notifications are enabled. Toggle off to manage in iOS Settings."
                        : "Enable notifications to be reminded when scheduled tasks and groups are starting.")
                }

                // MARK: - General
                Section("General") {
                    Button {
                        showOnboardingReplay = true
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                    }
                }

                // MARK: - Feedback
                Section {
                    Button {
                        presentMailComposer(subject: "Feedback: Priority Task Manager")
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    Button {
                        presentMailComposer(subject: "Bug Report: Priority Task Manager")
                    } label: {
                        Label("Report a Bug", systemImage: "ladybug")
                    }
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("Your feedback helps us improve the app.")
                }

                // MARK: - AI Model
                #if os(iOS)
                Section {
                    HStack {
                        Label("On-Device AI", systemImage: "cpu")
                        Spacer()
                        Text(aiAssistant.isLocalModelReady ? "Loaded" :
                             aiAssistant.isModelDownloaded ? "Downloaded" : "Not downloaded")
                            .font(.subheadline)
                            .foregroundColor(aiAssistant.isLocalModelReady ? .green : .secondary)
                    }

                    if aiAssistant.isModelDownloaded {
                        Button(role: .destructive) {
                            showDeleteModelAlert = true
                        } label: {
                            Label("Delete AI Model (~900 MB)", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("The AI model is stored on your device for offline use. Delete it to free up ~900 MB of storage. It will re-download next time you use the AI.")
                }
                #endif

                // MARK: - Data
                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }

                    if dataCleared {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("All data cleared.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This permanently deletes all tasks, groups, and schedules.")
                }

                // MARK: - Debug (Only in Debug builds)
                #if DEBUG
                Section {
                    Button {
                        purchaseManager.resetPurchaseForTesting()
                    } label: {
                        Label("Reset Purchase State", systemImage: "arrow.counterclockwise.circle")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Debug Tools")
                } footer: {
                    Text("⚠️ Debug only: Resets purchase and trial period for testing. This button won't appear in production builds.")
                }
                #endif

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }

            }
            .navigationTitle("Settings")
            .onAppear {
                checkNotificationStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                checkNotificationStatus()
            }
            .alert("Delete AI Model?", isPresented: $showDeleteModelAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    #if os(iOS)
                    aiAssistant.coreMLModel.deleteModel()
                    #endif
                }
            } message: {
                Text("This frees ~900 MB of storage. The model will re-download next time you use the AI assistant.")
            }
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear Everything", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will delete all tasks, groups, schedules, and instances. This cannot be undone.")
            }
            .fullScreenCover(isPresented: $showOnboardingReplay) {
                OnboardingReplayWrapper {
                    showOnboardingReplay = false
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    subject: mailSubject,
                    body: feedbackBody,
                    recipient: "alonsobardales.apps@gmail.com"
                )
            }
            .alert("Purchase Failed", isPresented: $showPurchaseError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseErrorMessage)
            }
            .alert("Mail Not Available", isPresented: $showNoMailAlert) {
                Button("Copy Email Address") {
                    UIPasteboard.general.string = "alonsobardales.apps@gmail.com"
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("No mail account is configured on this device. Please email us at alonsobardales.apps@gmail.com")
            }
        }
        .navigationViewStyle(.stack)
    }

    private func triggerPurchase() async {
        do {
            try await purchaseManager.purchase()
        } catch let error as StoreError {
            // Don't show alert for user cancellation
            if case .userCancelled = error {
                return
            }
            purchaseErrorMessage = error.localizedDescription ?? "An unexpected error occurred."
            showPurchaseError = true
        } catch {
            purchaseErrorMessage = error.localizedDescription
            showPurchaseError = true
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func clearAllData() {
        groupManager.clearAll()
        taskManager.clearAll()
        dataCleared = true
    }

    private var feedbackBody: String {
        let device = UIDevice.current
        return """


        ---
        App Version: \(appVersion)
        Device: \(device.model)
        iOS: \(device.systemVersion)
        """
    }

    private func presentMailComposer(subject: String) {
        if MFMailComposeViewController.canSendMail() {
            mailSubject = subject
            showMailComposer = true
        } else {
            showNoMailAlert = true
        }
    }
}

/// UIViewControllerRepresentable wrapper for MFMailComposeViewController
private struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipient: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

/// Wraps OnboardingView for replay without modifying the hasSeenOnboarding flag
private struct OnboardingReplayWrapper: View {
    let onDismiss: () -> Void
    @State private var currentPage = 0

    private let pages: [ReplayPage] = [
        ReplayPage(icon: "list.number", iconColor: .blue, title: "ABCDE Priority Method", subtitle: "Know What Matters Most", description: "Assign every task a priority from A (must do) to E (eliminate). Stop guessing what to work on — your highest-impact tasks always rise to the top."),
        ReplayPage(icon: "square.grid.2x2", iconColor: .purple, title: "Covey's Matrix", subtitle: "Urgent vs. Important", description: "Visualize your tasks on the Urgent/Important grid. Spend more time in Quadrant 2 — important but not urgent — where real progress happens."),
        ReplayPage(icon: "calendar", iconColor: .orange, title: "Schedule & Groups", subtitle: "Structure Your Day", description: "Organize tasks into groups with recurring schedules. See your day laid out on a timeline so nothing falls through the cracks."),
        ReplayPage(icon: "wind", iconColor: .teal, title: "Breathing Exercises", subtitle: "Stay Calm Under Pressure", description: "Built-in guided breathing helps you reset when stress builds up. Take a moment to recenter, then get back to what matters.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") {
                    onDismiss()
                }
                .padding()
            }

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 70))
                            .foregroundColor(pages[index].iconColor)
                        Text(pages[index].title)
                            .font(.system(size: 28, weight: .bold))
                        Text(pages[index].subtitle)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text(pages[index].description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct ReplayPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}
