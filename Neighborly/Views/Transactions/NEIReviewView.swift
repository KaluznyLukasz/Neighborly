//
//  NEIReviewView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

struct NEIReviewView: View {
    let transaction: Transaction
    let reviewerId: String
    let revieweeId: String
    let onDone: () -> Void

    @State private var rating = 5
    @State private var comment = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let reviewService = NEIReviewService()
    private let authService = Auth.auth()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("How did it go?")
                        .font(.title2)
                        .fontWeight(.bold)

                    starPicker

                    presetChips

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Comment (optional)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $comment)
                            .frame(minHeight: 80)
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

                    NEIPrimaryButton("Submit Review", isLoading: isLoading) {
                        Task { await submit() }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }

    private var presetChips: some View {
        NEIFlowLayout(spacing: 8) {
            ForEach(ReviewPresets.texts, id: \.self) { preset in
                let isSelected = comment == preset
                Text(preset)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.green : Color(.systemGray6))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(Capsule())
                    .onTapGesture {
                        comment = isSelected ? "" : preset
                    }
            }
        }
    }

    private var starPicker: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(star <= rating ? .yellow : Color(.systemGray4))
                    .onTapGesture { rating = star }
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        let trimmedComment = comment.trimmingCharacters(in: .whitespaces)
        let finalComment = trimmedComment.isEmpty ? ReviewPresets.texts.randomElement() : trimmedComment
        let review = Review(
            transactionId: transaction.id ?? "",
            reviewerId: reviewerId,
            reviewerName: authService.currentUser?.displayName ?? "User",
            revieweeId: revieweeId,
            rating: rating,
            comment: finalComment,
            createdAt: Date()
        )
        do {
            try await reviewService.submitReview(review)
            onDone()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
