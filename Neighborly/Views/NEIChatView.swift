//
//  NEIChatView.swift
//  Neighborly
//

import SwiftUI

struct NEIChatView: View {
    let transaction: Transaction
    let currentUserId: String
    let currentUserName: String

    @State private var vm = NEIMessageViewModel()
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { message in
                            MessageBubble(
                                message: message,
                                isMe: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    if let last = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }

            Divider()

            HStack(spacing: 10) {
                TextField("Message...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))

                Button {
                    Task {
                        let text = inputText
                        inputText = ""
                        await vm.send(
                            transactionId: transaction.id ?? "",
                            senderId: currentUserId,
                            senderName: currentUserName,
                            text: text
                        )
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.systemGray4) : Color.green)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(transaction.offerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.startListening(transactionId: transaction.id ?? "")
        }
        .onDisappear {
            vm.stopListening()
        }
    }
}

private struct MessageBubble: View {
    let message: Message
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isMe ? Color.green : Color(.secondarySystemBackground))
                    .foregroundStyle(isMe ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color(.separator).opacity(isMe ? 0 : 0.5), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }
}
