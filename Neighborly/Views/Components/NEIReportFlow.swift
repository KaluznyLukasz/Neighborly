//
//  NEIReportFlow.swift
//  Neighborly
//

import SwiftUI

// Wspólny przebieg zgłoszenia: wybór powodu (confirmationDialog) → zapis → podziękowanie
// z propozycją zablokowania autora. Widok ustawia tylko `target`, resztę robi modyfikator.
private struct NEIReportFlowModifier: ViewModifier {
    @Binding var target: NEIReportTarget?
    let reporterId: String
    let onBlocked: (() -> Void)?

    @State private var submitted: NEIReportTarget?
    @State private var failure: Failure?

    private let reportService = NEIReportService()

    private struct Failure {
        let title: String
        let message: String
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Why are you reporting this \(target?.type.noun ?? "")?",
                isPresented: Binding(
                    get: { target != nil },
                    set: { if !$0 { target = nil } }
                ),
                titleVisibility: .visible,
                presenting: target
            ) { target in
                ForEach(NEIReportReason.allCases) { reason in
                    Button(reason.title) {
                        Task { await submit(target, reason: reason) }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { target in
                Text("\(target.ownerName) won't know it was you.")
            }
            .alert(
                "Thanks for Reporting",
                isPresented: Binding(
                    get: { submitted != nil },
                    set: { if !$0 { submitted = nil } }
                ),
                presenting: submitted
            ) { target in
                if target.ownerId != reporterId {
                    Button("Block \(target.ownerName)", role: .destructive) {
                        Task { await block(target) }
                    }
                }
                Button("Done", role: .cancel) {}
            } message: { _ in
                Text("Neighborly reviews every report within 24 hours and removes anything that breaks the Community Guidelines.")
            }
            .alert(
                failure?.title ?? "",
                isPresented: Binding(
                    get: { failure != nil },
                    set: { if !$0 { failure = nil } }
                ),
                presenting: failure
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { failure in
                Text(failure.message)
            }
    }

    private func submit(_ target: NEIReportTarget, reason: NEIReportReason) async {
        do {
            try await reportService.submit(target, reason: reason, reporterId: reporterId)
            submitted = target
        } catch {
            failure = Failure(title: "Couldn't Send Report", message: "Check your connection and try again.")
        }
    }

    private func block(_ target: NEIReportTarget) async {
        do {
            try await NEIBlockService().addBlock(
                userId: reporterId,
                blockedUserId: target.ownerId,
                blockedDisplayName: target.ownerName
            )
            onBlocked?()
        } catch {
            failure = Failure(title: "Couldn't Block \(target.ownerName)", message: "Check your connection and try again.")
        }
    }
}

extension View {
    /// Pokazuje przebieg zgłoszenia, gdy `target` dostanie wartość.
    func neiReportFlow(
        target: Binding<NEIReportTarget?>,
        reporterId: String,
        onBlocked: (() -> Void)? = nil
    ) -> some View {
        modifier(NEIReportFlowModifier(target: target, reporterId: reporterId, onBlocked: onBlocked))
    }
}
