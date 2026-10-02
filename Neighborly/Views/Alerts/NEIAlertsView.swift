//
//  NEIAlertsView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import FirebaseAuth

struct NEIAlertsView: View {
    @EnvironmentObject var authService: NEIAuthService
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    let vm: NEIAlertViewModel
    // Ścieżka z zewnątrz — tapnięte powiadomienie otwiera od razu ogłoszenie albo rozmowę
    @Binding var path: NavigationPath
    @State private var showCreate = false

    private var uid: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Alerts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showCreate = true
                        } label: {
                            Label("New Alert", systemImage: "plus")
                        }
                        .disabled(locationManager.userCoordinate == nil)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done").fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.neiGreen)
                        .controlSize(.small)
                    }
                }
                .navigationDestination(for: NeighborhoodAlert.self) { alert in
                    NEIAlertDetailView(alert: alert)
                }
                .navigationDestination(for: NEIAlertChatRoute.self) { route in
                    NEIAlertChatView(route: route)
                }
                .sheet(isPresented: $showCreate) {
                    NEICreateAlertView(vm: vm) { await reload() }
                }
                // Przy otwartej liście nowe ogłoszenia widać od razu — bez powiadomień
                .onAppear { NEINotificationRouter.shared.isViewingAlerts = true }
                .onDisappear { NEINotificationRouter.shared.isViewingAlerts = false }
                .onAppear {
                    // Pierwsze otwarcie: od razu systemowy monit o zgodę na lokalizację
                    if locationManager.authorizationStatus == .notDetermined {
                        locationManager.requestPermission()
                    }
                }
                .task(id: locationManager.userCoordinate) { await reload() }
                .refreshable { await reload() }
                .alert("Error", isPresented: Binding(
                    get: { vm.errorMessage != nil },
                    set: { if !$0 { vm.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(vm.errorMessage ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if locationManager.userCoordinate == nil {
            ContentUnavailableView {
                Label("Location Needed", systemImage: "location.slash")
            } description: {
                Text("Allow location access to see alerts from neighbors nearby.")
            } actions: {
                Button(locationManager.authorizationStatus == .notDetermined ? "Allow Location" : "Open Settings") {
                    allowLocation()
                }
                .buttonStyle(.borderedProminent)
            }
        } else if vm.isLoading && vm.alerts.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.alerts.isEmpty {
            ContentUnavailableView(
                "All Quiet",
                systemImage: "bell.slash",
                description: Text("No alerts nearby right now. Alerts disappear after 48 hours.")
            )
        } else {
            List(vm.alerts) { alert in
                NavigationLink(value: alert) {
                    NEIAlertRow(alert: alert, origin: locationManager.userCoordinate)
                }
                .listRowSeparator(.hidden)
                // Każde ogłoszenie to osobna karta z odstępem, nie ciągły wiersz listy
                .listRowInsets(EdgeInsets(top: 12, leading: 28, bottom: 12, trailing: 28))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if alert.authorId == uid {
                            Button(role: .destructive) {
                                Task { await vm.delete(alert) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
    }

    // Po odmowie system nie pokaże monitu ponownie — jedyna droga to Ustawienia
    private func allowLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func reload() async {
        guard let coordinate = locationManager.userCoordinate else { return }
        await vm.load(near: coordinate, currentUserId: uid)
    }
}

private struct NEIAlertRow: View {
    let alert: NeighborhoodAlert
    let origin: CLLocationCoordinate2D?

    private var distanceText: String? {
        guard let origin else { return nil }
        let meters = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: alert.latitude, longitude: alert.longitude))
        return Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    private var photo: UIImage? {
        alert.imageBase64.flatMap { NEIBase64ImageCache.decodedImage(base64: $0) }
    }

    // Typ jako kolorowa etykieta w linii meta (jak tag/lista w Przypomnieniach), reszta w szarości
    private var metaLine: some View {
        HStack(spacing: 4) {
            Text(alert.kind.displayName)
                .fontWeight(.semibold)
                .foregroundStyle(alert.kind.color)
            Text("·")
            Text(alert.createdAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
            if let distanceText {
                Text("·")
                Text(distanceText)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    // Wszystkie wiersze mają ten sam rozmiar: miniatura/ikona 60 pt + tytuł, opis (1 linia,
    // miejsce zarezerwowane także, gdy opisu brak) i linia meta
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            leading

            VStack(alignment: .leading, spacing: 3) {
                Text(alert.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(alert.details.isEmpty ? " " : alert.details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1, reservesSpace: true)
                metaLine
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // Zdjęcie zastępuje kafelek z ikoną; typ ogłoszenia zostaje jako mała plakietka w rogu
    @ViewBuilder
    private var leading: some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: alert.kind.systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(alert.kind.color, in: Circle())
                        .overlay(Circle().strokeBorder(Color(.secondarySystemGroupedBackground), lineWidth: 2))
                        .offset(x: 6, y: 6)
                }
                .accessibilityLabel("Photo")
        } else {
            Image(systemName: alert.kind.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(alert.kind.color.gradient, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
        }
    }
}
