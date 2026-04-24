//
//  PremiumManager.swift
//  Retro Maze
//
//  Created by Codex on 21/04/2026.
//

import Foundation
import StoreKit

@MainActor
final class PremiumManager: ObservableObject {
    //TODO: Remplacer par la bonne donnée une fois l'achat intégré créé dans App Store Connect
    static let productID = "APP_STORE_CONNECT_PRODUCT_ID_PLACEHOLDER"

    @Published private(set) var premiumProduct: Product?
    @Published private(set) var hasPremiumAccess = false
    @Published private(set) var isLoadingProduct = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasLoadedEntitlements = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = observeTransactionUpdates()

        Task {
            await refreshStoreState()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var productDisplayName: String {
        premiumProduct?.displayName ?? "Pack Premium"
    }

    var productDescription: String {
        premiumProduct?.description ?? "Débloque les fonctionnalités premium de Retro Maze."
    }

    var productPrice: String {
        //TODO: Remplacer par la bon prix
        premiumProduct?.displayPrice ?? "Prix à définir dans App Store Connect"
    }

    func refreshStoreState() async {
        await requestProduct()
        await refreshEntitlements()
    }

    func requestProduct() async {
        errorMessage = nil
        isLoadingProduct = true

        defer {
            isLoadingProduct = false
        }

        do {
            let products = try await Product.products(for: [Self.productID])
            premiumProduct = products.first

            if premiumProduct == nil {
                statusMessage = "Produit premium introuvable. Vérifiez la configuration StoreKit/App Store Connect."
            } else {
                statusMessage = nil
            }
        } catch {
            premiumProduct = nil
            errorMessage = "Chargement du produit impossible: \(error.localizedDescription)"
        }
    }

    func purchasePremium() async {
        clearMessages()

        if premiumProduct == nil {
            await requestProduct()
        }

        guard let premiumProduct else {
            errorMessage = "Produit premium indisponible."
            return
        }

        isPurchasing = true

        defer {
            isPurchasing = false
        }

        do {
            let result = try await premiumProduct.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                statusMessage = hasPremiumAccess ? "Premium activé." : "Transaction reçue, statut en cours d’actualisation."

            case .userCancelled:
                statusMessage = "Achat annulé."

            case .pending:
                statusMessage = "Achat en attente de validation."

            @unknown default:
                errorMessage = "Résultat d’achat inconnu."
            }
        } catch {
            errorMessage = "Achat impossible: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        clearMessages()
        isRestoring = true

        defer {
            isRestoring = false
        }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = hasPremiumAccess ? "Achats restaurés." : "Aucun achat premium restauré."
        } catch {
            errorMessage = "Restauration impossible: \(error.localizedDescription)"
        }
    }

    private func refreshEntitlements() async {
        var premiumUnlocked = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == Self.productID, transaction.revocationDate == nil {
                    premiumUnlocked = true
                }
            } catch {
                errorMessage = "Vérification des transactions impossible: \(error.localizedDescription)"
            }
        }

        if premiumUnlocked {
            errorMessage = nil
        }

        hasPremiumAccess = premiumUnlocked
        hasLoadedEntitlements = true
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }

                do {
                    let transaction = try self.checkVerified(result)
                    await self.refreshEntitlements()
                    await transaction.finish()
                    await MainActor.run {
                        self.statusMessage = self.hasPremiumAccess ? "Statut premium mis à jour." : self.statusMessage
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Mise à jour de transaction invalide: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func clearMessages() {
        statusMessage = nil
        errorMessage = nil
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PremiumError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum PremiumError: Error {
    case failedVerification
}
