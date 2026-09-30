//
//  NEIAlertService.swift
//  Neighborly
//

import Foundation
import CoreLocation
import FirebaseFirestore

final class NEIAlertService {
    private let db = Firestore.firestore()
    private let collection = "alerts"

    // Nasłuch na żywo: nowe ogłoszenia pojawiają się od razu, bez ponownego otwierania listy.
    // Jeden zakres na expiresAt — bez indeksu złożonego; odległość filtruje ViewModel po stronie klienta,
    // bo aktywnych (niewygasłych) ogłoszeń jest z natury niewiele
    func listenActive(
        onChange: @escaping @Sendable ([NeighborhoodAlert]) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) -> ListenerRegistration {
        db.collection(collection)
            .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                guard let snapshot else { return }
                // Nie gubimy po cichu dokumentów, których nie da się zdekodować
                let alerts = snapshot.documents.compactMap { doc -> NeighborhoodAlert? in
                    do {
                        return try doc.data(as: NeighborhoodAlert.self)
                    } catch {
                        NSLog("Alert \(doc.documentID) decode failed: \(error)")
                        return nil
                    }
                }
                onChange(alerts)
            }
    }

    func create(_ alert: NeighborhoodAlert) async throws {
        // setData(from:) bez completion gubi błędy reguł — opakowujemy w continuation
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try db.collection(collection).document().setData(from: alert) { error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume()
                    }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func delete(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    private func threads(alertId: String) -> CollectionReference {
        db.collection(collection).document(alertId).collection("threads")
    }

    func upsertThread(alertId: String, viewerId: String, viewerName: String, lastMessage: String) async throws {
        let thread = AlertThread(viewerName: viewerName, lastMessage: lastMessage, updatedAt: Date())
        let data = try Firestore.Encoder().encode(thread)
        try await threads(alertId: alertId).document(viewerId).setData(data, merge: true)
    }

    func fetchThreads(alertId: String) async throws -> [AlertThread] {
        let snapshot = try await threads(alertId: alertId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AlertThread.self) }
    }
}
