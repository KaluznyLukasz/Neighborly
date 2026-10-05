//
//  NEIChatView.swift
//  Neighborly
//

import SwiftUI

struct NEIChatView: View {
    let title: String
    let conversationPath: String
    let currentUserId: String
    let currentUserName: String
    // Wywoływane po udanym wysłaniu — np. odświeżenie wątku ogłoszenia
    var onSent: ((String) async -> Void)?

    init(transaction: Transaction, currentUserId: String, currentUserName: String) {
        self.title = transaction.offerTitle
        self.conversationPath = NEIMessageService.path(transactionId: transaction.id ?? "")
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
    }

    init(title: String, conversationPath: String, currentUserId: String, currentUserName: String, onSent: ((String) async -> Void)? = nil) {
        self.title = title
        self.conversationPath = conversationPath
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.onSent = onSent
    }

    @State private var vm = NEIMessageViewModel()
    @State private var inputText = ""
    @State private var reportTarget: NEIReportTarget?

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
                            .contextMenu { messageMenu(message) }
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
                        let sent = await vm.send(
                            path: conversationPath,
                            senderId: currentUserId,
                            senderName: currentUserName,
                            text: text
                        )
                        // Odrzucona (filtr, sieć) wraca do pola, żeby jej nie przepisywać
                        if sent { await onSent?(text) } else if inputText.isEmpty { inputText = text }
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .neiReportFlow(target: $reportTarget, reporterId: currentUserId)
        .task {
            vm.startListening(path: conversationPath)
        }
        .onDisappear {
            vm.stopListening()
        }
    }
}

extension NEIChatView {
    @ViewBuilder
    private func messageMenu(_ message: Message) -> some View {
        Button("Copy", systemImage: "doc.on.doc") {
            UIPasteboard.general.string = message.text
        }
        if message.senderId != currentUserId, let id = message.id {
            Button("Report Message", systemImage: "flag", role: .destructive) {
                reportTarget = NEIReportTarget(
                    type: .message,
                    targetId: "\(conversationPath)/\(id)",
                    ownerId: message.senderId,
                    ownerName: message.senderName,
                    excerpt: message.text
                )
            }
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
