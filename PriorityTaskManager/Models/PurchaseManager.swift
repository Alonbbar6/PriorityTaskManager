import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {

    static let productID = "com.alonsobardales.PriorityTaskManager.fullaccess"
    private let trialDays = 30
    private let installDateKey = "installDate"

    @Published var hasPurchased: Bool = UserDefaults.standard.bool(forKey: "hasPurchased")
    @Published var isLoading = false

    private var transactionUpdateTask: _Concurrency.Task<Void, Never>?

    init() {
        transactionUpdateTask = _Concurrency.Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID {
                    await transaction.finish()
                    self.hasPurchased = true
                    UserDefaults.standard.set(true, forKey: "hasPurchased")
                }
            }
        }
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Trial

    var installDate: Date {
        if let stored = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: installDateKey)
        return now
    }

    var trialDaysRemaining: Int {
        let elapsed = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, trialDays - elapsed)
    }

    var isTrialActive: Bool {
        trialDaysRemaining > 0
    }

    var hasFullAccess: Bool {
        isTrialActive || hasPurchased
    }

    // MARK: - Purchase

    func purchase() async throws {
        isLoading = true
        defer { isLoading = false }

        print("🛒 Starting purchase flow...")

        do {
            print("🔍 Fetching products for purchase...")
            let products = try await Product.products(for: [Self.productID])
            print("📦 Fetched \(products.count) products")

            guard let product = products.first else {
                print("❌ Product not found in StoreKit")
                throw StoreError.productNotFound
            }

            print("💳 Attempting purchase of: \(product.displayName)")
            let result = try await product.purchase()

            print("📬 Purchase result received")
            switch result {
            case .success(let verification):
                print("✅ Purchase successful, verifying...")
                let transaction = try checkVerified(verification)
                print("✅ Transaction verified, finishing...")
                await transaction.finish()
                hasPurchased = true
                UserDefaults.standard.set(true, forKey: "hasPurchased")
                print("✅ Purchase completed successfully!")
            case .userCancelled:
                print("🚫 User cancelled purchase")
                throw StoreError.userCancelled
            case .pending:
                print("⏳ Purchase pending")
                throw StoreError.purchasePending
            @unknown default:
                print("⚠️ Unknown purchase result")
                throw StoreError.unknown
            }
        } catch let error as StoreError {
            print("❌ StoreError occurred: \(error)")
            throw error
        } catch {
            // Handle StoreKit errors
            print("❌ System error occurred: \(error)")
            print("   Error details: \(error.localizedDescription)")
            throw StoreError.systemError(error)
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                hasPurchased = true
                UserDefaults.standard.set(true, forKey: "hasPurchased")
                return
            }
        }
    }

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                hasPurchased = true
                UserDefaults.standard.set(true, forKey: "hasPurchased")
                return
            }
        }
    }

    // MARK: - Debug Helper

    #if DEBUG
    /// Reset purchase state for testing. Only available in debug builds.
    func resetPurchaseForTesting() {
        UserDefaults.standard.set(false, forKey: "hasPurchased")
        UserDefaults.standard.removeObject(forKey: installDateKey)
        hasPurchased = false
        print("⚠️ DEBUG: Purchase state and trial period reset")
    }
    #endif

    // MARK: - Helpers

    func fetchProduct() async -> Product? {
        do {
            print("🔍 Fetching product with ID: \(Self.productID)")
            let products = try await Product.products(for: [Self.productID])
            print("📦 Received \(products.count) products from StoreKit")

            if let product = products.first {
                print("✅ Product found: \(product.displayName) - \(product.displayPrice)")
                return product
            } else {
                print("⚠️ No product found for ID: \(Self.productID)")
                print("💡 Make sure:")
                print("   1. StoreKitConfig.storekit is included in the project")
                print("   2. The product ID matches exactly: \(Self.productID)")
                print("   3. The StoreKit configuration file is set in scheme settings")
                return nil
            }
        } catch {
            print("❌ Error fetching product: \(error.localizedDescription)")
            print("   Error details: \(error)")
            return nil
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case userCancelled
    case purchasePending
    case unknown
    case systemError(Error)
}

extension StoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please try again."
        case .productNotFound:
            return "Product not found. Make sure you are connected to the internet and try again."
        case .userCancelled:
            return nil // Don't show error for user cancellation
        case .purchasePending:
            return "Your purchase is pending approval. Please check back later."
        case .unknown:
            return "An unknown error occurred. Please try again."
        case .systemError(let error):
            return "Purchase failed: \(error.localizedDescription)"
        }
    }

    var failureReason: String? {
        switch self {
        case .productNotFound:
            return "The product could not be loaded from the App Store."
        case .failedVerification:
            return "The purchase could not be verified."
        case .purchasePending:
            return "Your purchase requires additional approval."
        default:
            return nil
        }
    }
}
