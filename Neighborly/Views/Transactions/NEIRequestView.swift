//
//  NEIRequestView.swift
//  Neighborly
//

import SwiftUI

struct NEIRequestView: View {
    let offer: Offer
    let requesterId: String
    let requesterName: String
    let onSent: () -> Void

    @State private var message = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let transactionService = NEITransactionService()

    // Widok jest pushowany na stosie nawigacji szczegółów oferty (bez własnego
    // NavigationStack i bez sheeta) — wstecz wraca przycisk systemowy.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NEISectionLabel("Offer")
                offerSummary

                VStack(alignment: .leading, spacing: 6) {
                    NEISectionLabel("Message to the owner (optional)")

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)

                        if message.isEmpty {
                            Text("Let them know how you'd like to help…")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .cardStyle(cornerRadius: 10)
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        // Przycisk przypięty na dole jak w szczegółach oferty — widoczny przy każdym detentcie arkusza
        .safeAreaInset(edge: .bottom) { sendBar }
        .navigationTitle("Offer to Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sendBar: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 10) {
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                NEIPrimaryButton("Send Request", isLoading: isLoading) {
                    Task { await sendRequest() }
                }
            }
            .padding(20)
        }
        .background(.regularMaterial)
    }

    private var offerSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            NEICategoryBadge(category: offer.category)
            Text(offer.title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(offer.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func sendRequest() async {
        isLoading = true
        errorMessage = nil
        // Zamyka wyścig: sprawdź, czy już zaaplikowano, zanim utworzysz transakcję
        if let existing = try? await transactionService.existingTransaction(
            offerId: offer.id ?? "", requesterId: requesterId
        ), existing.id != nil {
            isLoading = false
            errorMessage = "You already applied to this offer."
            onSent()
            dismiss()
            return
        }
        let transaction = Transaction(
            offerId: offer.id ?? "",
            offerTitle: offer.title,
            requesterId: requesterId,
            requesterName: requesterName,
            ownerId: offer.ownerId,
            offerCategory: offer.category,
            status: .pending,
            message: message.trimmingCharacters(in: .whitespaces).isEmpty ? nil : message,
            createdAt: Date(),
            updatedAt: Date()
        )
        do {
            _ = try await transactionService.createTransaction(transaction)
            onSent()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
