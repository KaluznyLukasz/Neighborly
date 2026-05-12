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

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    var userCoordinate: CLLocationCoordinate2D?
    var mapCenter = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)
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
        mapCenter = location.coordinate
        position = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        manager.stopUpdatingLocation()
    }
}

struct NEIMapView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var locationManager = LocationManager()
    @State private var mapVM = NEIMapViewModel()
    @State private var showCreateOffer = false

    var body: some View {
        Map(position: $locationManager.position) {
            UserAnnotation()

            ForEach(mapVM.offers) { offer in
                Annotation(offer.title, coordinate: offer.coordinate) {
                    NEIOfferAnnotationView(offer: offer)
                        .onTapGesture {
                            mapVM.selectedOffer = offer
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
                            .background(.regularMaterial)
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
            // Load immediately with best-available coord — onChange misses values set before view appears
            Task { await mapVM.loadOffers(near: locationManager.userCoordinate ?? locationManager.mapCenter) }
        }
        .onChange(of: locationManager.userCoordinate) { _, coord in
            guard let coord else { return }
            Task { await mapVM.loadOffers(near: coord) }
        }
        .sheet(item: $mapVM.selectedOffer) { offer in
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
                let coord = locationManager.userCoordinate ?? locationManager.mapCenter
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
                .background(Color.green)
                .clipShape(Circle())
                .shadow(radius: 4, y: 2)
        }
    }

    private var locationDeniedBanner: some View {
        Text("Location access denied. Enable in Settings.")
            .font(.caption)
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct NEIOfferAnnotationView: View {
    let offer: Offer

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2, y: 1)
                Image(systemName: offer.category.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.green)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }
}

#Preview {
    NEIMapView()
        .environmentObject(NEIAuthService())
}
