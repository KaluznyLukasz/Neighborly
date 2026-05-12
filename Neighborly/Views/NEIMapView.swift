//
//  NEIMapView.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI
import MapKit
import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        position = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        manager.stopUpdatingLocation()
    }
}

struct NEIMapView: View {
    @State private var locationManager = LocationManager()
    var offers: [Offer] = []
    @State private var selectedOffer: Offer?

    var body: some View {
        Map(position: $locationManager.position) {
            UserAnnotation()

            ForEach(offers) { offer in
                Annotation(offer.title, coordinate: offer.coordinate) {
                    NEIOfferAnnotationView(offer: offer)
                        .onTapGesture { selectedOffer = offer }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
        .onAppear {
            locationManager.requestPermission()
        }
        .overlay(alignment: .bottomTrailing) {
            if locationManager.authorizationStatus == .denied ||
               locationManager.authorizationStatus == .restricted {
                locationDeniedBanner
            }
        }
        .sheet(item: $selectedOffer) { offer in
            NEIOfferDetailStub(offer: offer)
                .presentationDetents([.medium])
        }
    }

    private var locationDeniedBanner: some View {
        Text("Location access denied. Enable in Settings.")
            .font(.caption)
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
    }
}

struct NEIOfferAnnotationView: View {
    let offer: Offer

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 36, height: 36)
                Image(systemName: offer.category.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.green)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }
}

// Stub — replace with real NEIOfferDetailView in Phase 2
private struct NEIOfferDetailStub: View {
    let offer: Offer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(offer.title)
                .font(.headline)
            Text(offer.description)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(offer.category.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview {
    NEIMapView(offers: [
        Offer(
            id: "1",
            title: "Power Drill",
            description: "Bosch 18V, available weekends",
            category: .tools,
            ownerId: "user1",
            latitude: 52.2297,
            longitude: 21.0122,
            imageURLs: [],
            isActive: true,
            createdAt: .now
        )
    ])
}
