//
//  StoreManager.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 27/09/2025.
//

import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    private let premiumProductID = "com.yourcompany.snailmaze.premium"
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Request
    
    func requestProducts() async {
        do {
            products = try await Product.products(for: [premiumProductID])
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        default:
            return nil
        }
    }
    
    func purchasePremiumPack() async -> Bool {
        // Simulation d'achat réussi pour les tests
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "hasPremiumPack")
        purchasedProductIDs.insert(premiumProductID)
        return true
        #else
        guard let premiumProduct = products.first(where: { $0.id == premiumProductID }) else {
            return false
        }
        
        do {
            let transaction = try await purchase(premiumProduct)
            return transaction != nil
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
        #endif
    }
    
    // MARK: - Transaction Handling
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    func updateCustomerProductStatus() async {
        var purchasedIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                } else {
                    purchasedIDs.remove(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        purchasedProductIDs = purchasedIDs
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Public API
    
    var hasPremiumPack: Bool {
        return purchasedProductIDs.contains(premiumProductID)
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
    }
    
    // MARK: - Testing & Reset
    
    func resetPremiumForTesting() {
        purchasedProductIDs.remove(premiumProductID)
        print("🔄 Premium réinitialisé pour les tests")
    }
}

// MARK: - Error Handling

enum StoreError: Error {
    case failedVerification
}
