import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var product: Product?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoadingProduct = true
    @State private var productLoadFailed = false

    private let features: [(icon: String, color: Color, title: String, description: String)] = [
        ("calendar", .orange, "Schedule & Timeline", "View your day as a visual timeline with all your groups and tasks"),
        ("rectangle.3.group", .blue, "Task Groups", "Organize recurring tasks into groups with custom schedules"),
        ("square.grid.2x2", .purple, "Covey Matrix", "Visualize tasks by urgency and importance in four quadrants"),
        ("wind", .teal, "Breathing Exercises", "Guided breathing to help you reset and stay focused"),
        ("bell.fill", .red, "Notifications", "Get reminded when scheduled tasks and groups are starting")
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                            .padding(.top, 48)

                        Text("Your Free Trial Has Ended")
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Unlock full access to continue using all features of Priority Task Manager.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 32)

                    // Features list
                    VStack(spacing: 0) {
                        ForEach(features, id: \.title) { feature in
                            HStack(spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(feature.color)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.headline)
                                    Text(feature.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            if feature.title != features.last?.title {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)

                    // Purchase button
                    VStack(spacing: 12) {
                        if productLoadFailed {
                            VStack(spacing: 12) {
                                Text("Unable to load product")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button {
                                    _Concurrency.Task { await loadProduct() }
                                } label: {
                                    HStack {
                                        if isLoadingProduct {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Retry")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                                .disabled(isLoadingProduct)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                        } else {
                            Button {
                                _Concurrency.Task { await handlePurchase() }
                            } label: {
                                HStack {
                                    if purchaseManager.isLoading || isLoadingProduct {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Unlock Forever — \(priceString)")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                            .disabled(purchaseManager.isLoading || isLoadingProduct || product == nil)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                        }

                        Button {
                            _Concurrency.Task { await purchaseManager.restorePurchases() }
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(purchaseManager.isLoading)

                        Text("One-time purchase • No subscription • No hidden fees")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 40)
                    }
                }
            }
        }
        .task {
            await loadProduct()
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var priceString: String {
        product?.displayPrice ?? "$4.99"
    }

    private func loadProduct() async {
        isLoadingProduct = true
        productLoadFailed = false

        do {
            product = await purchaseManager.fetchProduct()

            if product == nil {
                productLoadFailed = true
                print("⚠️ Failed to load product: Product is nil")
            } else {
                print("✅ Product loaded successfully: \(product?.displayName ?? "Unknown")")
            }
        }

        isLoadingProduct = false
    }

    private func handlePurchase() async {
        // Double-check product is loaded before attempting purchase
        guard product != nil else {
            errorMessage = "Product not loaded. Please try again or check your internet connection."
            showError = true
            await loadProduct()
            return
        }

        do {
            try await purchaseManager.purchase()
        } catch let error as StoreError {
            // Don't show alert for user cancellation
            if case .userCancelled = error {
                return
            }
            errorMessage = error.localizedDescription ?? "An unexpected error occurred."
            showError = true
            print("⚠️ Purchase error: \(error)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("⚠️ Purchase error: \(error)")
        }
    }
}
