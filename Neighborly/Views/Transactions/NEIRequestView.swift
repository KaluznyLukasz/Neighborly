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
                    offerSummary

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Message to owner (optional)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .padding(10)
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
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Request Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sendRequest() async {
        isLoading = true
        errorMessage = nil
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
