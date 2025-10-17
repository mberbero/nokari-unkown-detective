//
//  StoreKitManager.swift
//  Unknown Detective
//
//  StoreKit 2 helper for loading products and making purchases.
//

import Foundation
import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product identifiers (must match App Store Connect)
    enum ProductID: String, CaseIterable {
        case packSmall = "pack.small"
        case packMedium = "pack.medium"
        case packLarge = "pack.large"
        case detectivePlusMonthly = "sub.plus.month"
        case detectivePlusYearly = "sub.plus.year"
    }

    @Published private(set) var products: [ProductID: Product] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private init() { }

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        do {
            let ids = Set(ProductID.allCases.map { $0.rawValue })
            let fetched = try await Product.products(for: Array(ids))
            var map: [ProductID: Product] = [:]
            for product in fetched {
                if let id = ProductID(rawValue: product.id) { map[id] = product }
            }
            products = map
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(_ id: ProductID) async -> Bool {
        guard let product = products[id] else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func hasActiveDetectivePlus() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, let product = products[.detectivePlusMonthly], t.productID == product.id { return true }
            if case .verified(let t2) = result, let product2 = products[.detectivePlusYearly], t2.productID == product2.id { return true }
        }
        return false
    }

    func observeTransactionUpdates(handler: @escaping (Transaction) -> Void) {
        Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let tx) = update else { continue }
                handler(tx)
                await tx.finish()
                await self?.refreshProductsIfNeeded(for: tx.productID)
            }
        }
    }

    private func refreshProductsIfNeeded(for productID: String) async {
        if ProductID(rawValue: productID) != nil {
            await loadProducts()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKitManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transaction unverified"])
        case .verified(let safe):
            return safe
        }
    }
}
