//
//  PremiumSheetView.swift
//  Retro Maze
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct PremiumSheetView: View {
    let premiumManager: PremiumManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: premiumManager.hasPremiumAccess ? "crown.fill" : "crown")
                                .font(.largeTitle)
                                .foregroundStyle(.yellow, .orange)

                            Spacer()

                            if premiumManager.hasPremiumAccess {
                                Text("Actif")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(premiumManager.productDisplayName)
                            .font(.title2.bold())

                        Text(premiumManager.productDescription)
                            .foregroundColor(.secondary)

                        Text(premiumManager.productPrice)
                            .font(.title3.weight(.semibold))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Le pack premium débloque :")
                            .font(.headline)

                        featureRow("Solution automatique pendant 15 secondes après un échec")
                        featureRow("15 secondes supplémentaires sur le chrono")
                        featureRow("Suppression des bannières et interstitielles")
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await premiumManager.purchasePremium()
                            }
                        } label: {
                            Text(premiumManager.hasPremiumAccess ? "Premium déjà actif" : "Acheter")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            premiumManager.hasPremiumAccess ||
                            premiumManager.isPurchasing ||
                            premiumManager.isRestoring ||
                            premiumManager.isLoadingProduct ||
                            premiumManager.premiumProduct == nil
                        )

                        Button {
                            Task {
                                await premiumManager.restorePurchases()
                            }
                        } label: {
                            Text("Restaurer les achats")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(premiumManager.isPurchasing || premiumManager.isRestoring)
                    }

                    if premiumManager.isLoadingProduct || premiumManager.isPurchasing || premiumManager.isRestoring {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(progressMessage)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let statusMessage = premiumManager.statusMessage {
                        messageCard(statusMessage, color: .green)
                    }

                    if let errorMessage = premiumManager.errorMessage {
                        messageCard(errorMessage, color: .red)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                if premiumManager.premiumProduct == nil || !premiumManager.hasLoadedEntitlements {
                    await premiumManager.refreshStoreState()
                }
            }
        }
    }

    private var progressMessage: String {
        if premiumManager.isPurchasing {
            return "Achat en cours…"
        }

        if premiumManager.isRestoring {
            return "Restauration en cours…"
        }

        return "Chargement du produit…"
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .padding(.top, 2)

            Text(text)
        }
    }

    private func messageCard(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
