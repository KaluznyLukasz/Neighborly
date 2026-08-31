//
//  NEIMapView.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseAuth

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

private let defaultCenter = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
private let defaultSpan   = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var userCoordinate: CLLocationCoordinate2D?
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
        userCoordinate = location.coordinate
        manager.stopUpdatingLocation()
    }
}

struct NEIMapView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var locationManager = LocationManager()
    @State private var mapVM = NEIMapViewModel()
    @State private var selectedOffer: Offer?
    @State private var showCreateOffer = false
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: defaultCenter, span: defaultSpan)
    )

    var body: some View {
        Map(position: $mapPosition) {
            UserAnnotation()

            ForEach(mapVM.offers) { offer in
                Annotation("", coordinate: offer.coordinate) {
                    NEIOfferAnnotationView(offer: offer)
                        .onTapGesture {
                            selectedOffer = offer
                        }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    if locationManager.authorizationStatus == .denied ||
                       locationManager.authorizationStatus == .restricted {
                        locationDeniedBanner
                    }
                    if mapVM.isLoading {
                        ProgressView()
                            .padding(10)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                    }
                    fab
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 8)
            .background(.clear)
        }
        .onAppear {
            locationManager.requestPermission()
            let coord = locationManager.userCoordinate ?? defaultCenter
            Task { await mapVM.loadOffers(near: coord) }
        }
        .onChange(of: locationManager.userCoordinate) { _, coord in
            guard let coord else { return }
            mapPosition = .region(MKCoordinateRegion(center: coord, span: defaultSpan))
            Task { await mapVM.loadOffers(near: coord) }
        }
        .sheet(item: $selectedOffer) { offer in
            NEIOfferDetailView(
                offer: offer,
                currentUserId: authService.currentUser?.uid ?? "",
                currentUserName: authService.currentUser?.displayName ?? "User",
                onDelete: {
                    if let id = offer.id {
                        Task { await mapVM.deleteOffer(id: id) }
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCreateOffer) {
            if let uid = authService.currentUser?.uid {
                let coord = locationManager.userCoordinate ?? defaultCenter
                NEICreateOfferView(
                    ownerId: uid,
                    coordinate: coord,
                    onSaved: {
                        Task { await mapVM.loadOffers(near: coord) }
                    }
                )
            }
        }
    }

    private var fab: some View {
        Button {
            showCreateOffer = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.neiGreen)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
    }

    private var locationDeniedBanner: some View {
        Text("Location access denied. Enable in Settings.")
            .font(.caption)
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.08), lineWidth: 1))
    }
}

struct NEIOfferAnnotationView: View {
    let offer: Offer

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.neiGreen)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Image(systemName: offer.category.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.neiGreen)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
            Text(offer.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.top, 2)
        }
    }
}

#Preview {
    NEIMapView()
        .environmentObject(NEIAuthService())
}
