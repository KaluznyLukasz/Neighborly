//
//  NEIAlertViewModel.swift
//  Neighborly
//

import Foundation
import CoreLocation
import UIKit
import FirebaseFirestore

@MainActor
@Observable
final class NEIAlertViewModel {
    var alerts: [NeighborhoodAlert] = []
    var isLoading = false
    var errorMessage: String?

    private let alertService = NEIAlertService()
    private let blockService = NEIBlockService()

    private var all: [NeighborhoodAlert] = []
    private var origin: CLLocationCoordinate2D?
    private var blocked: Set<String> = []
    private var listener: ListenerRegistration?

    // Wywołanie ponowne (zmiana lokalizacji, pull-to-refresh) odświeża tylko punkt odniesienia
    // i listę zablokowanych — nasłuch Firestore działa cały czas
    func load(near coordinate: CLLocationCoordinate2D, currentUserId: String) async {
        origin = coordinate
        blocked = Set((try? await blockService.fetchBlockedUserIds(userId: currentUserId)) ?? [])
        if listener == nil {
            isLoading = true
            errorMessage = nil
            listener = alertService.listenActive(
                onChange: { [weak self] alerts in
                    Task { @MainActor [weak self] in
                        self?.all = alerts
                        self?.isLoading = false
                        self?.refilter()
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor [weak self] in
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                    }
                }
            )
        }
        refilter()
    }

    private func refilter() {
        guard let origin else { return }
        let radiusKm = NEIUserPreferences.searchRadiusKm
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let now = Date()
        alerts = all
            .filter { $0.expiresAt > now && !blocked.contains($0.authorId) }
            .filter { alert in
                guard !radiusKm.isInfinite else { return true }
                return here.distance(from: CLLocation(latitude: alert.latitude, longitude: alert.longitude)) <= radiusKm * 1000
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func post(
        kind: AlertKind,
        title: String,
        details: String,
        image: UIImage?,
        author: (id: String, name: String),
        at coordinate: CLLocationCoordinate2D
    ) async -> Bool {
        errorMessage = nil
        let now = Date()
        let alert = NeighborhoodAlert(
            kind: kind,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            authorId: author.id,
            authorName: author.name,
            imageBase64: Self.compressedBase64(from: image),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            createdAt: now,
            expiresAt: now.addingTimeInterval(NeighborhoodAlert.lifetime)
        )
        do {
            try await alertService.create(alert)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(_ alert: NeighborhoodAlert) async {
        guard let id = alert.id else { return }
        errorMessage = nil
        let index = alerts.firstIndex { $0.id == id }
        if let index { alerts.remove(at: index) }
        do {
            try await alertService.delete(id: id)
        } catch {
            errorMessage = error.localizedDescription
            refilter()
        }
    }

    // Zdjęcie trzymamy jako base64 w dokumencie (jak w ofertach). Reguły odrzucają > 700 000 znaków,
    // a limit dokumentu to 1 MiB — dlatego skala 1x (domyślny renderer użyłby skali ekranu, 3x,
    // i 800 pt dałoby 2400 px) oraz obniżanie jakości, aż zdjęcie się zmieści
    static let maxBase64Length = 600_000

    private static func compressedBase64(from image: UIImage?) -> String? {
        guard let image else { return nil }
        let maxDimension: CGFloat = 800
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        for quality in [0.6, 0.45, 0.3, 0.2] as [CGFloat] {
            if let encoded = resized.jpegData(compressionQuality: quality)?.base64EncodedString(),
               encoded.count <= maxBase64Length {
                return encoded
            }
        }
        return nil
    }
}
