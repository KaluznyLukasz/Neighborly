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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionLabel("Offer")
                    offerSummary

                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Message to the owner (optional)")

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
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    NEIPrimaryButton("Send Request", isLoading: isLoading) {
                        Task { await sendRequest() }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Offer to Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
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
