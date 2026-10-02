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
        NEIUserPreferences.lastKnownLocation = (location.coordinate.latitude, location.coordinate.longitude)
        manager.stopUpdatingLocation()
    }
}

struct NEIMapView: View {
    @EnvironmentObject var authService: NEIAuthService
    @Environment(LocationManager.self) private var locationManager
    @State private var mapVM = NEIMapViewModel()
    @State private var selectedOffer: Offer?
    @State private var showCreateOffer = false
    @State private var alertVM = NEIAlertViewModel()
    @State private var showAlerts = false
    @State private var alertsPath = NavigationPath()
    private let notificationRouter = NEINotificationRouter.shared
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: defaultCenter, span: defaultSpan)
    )
    @State private var visibleSpan: MKCoordinateSpan = defaultSpan
    @State private var expandedStackId: String?
    @State private var groupedItems: [NEIMapItem] = []
    @State private var lastLoadedCenter: CLLocationCoordinate2D?

    // Pokaż tytuły tylko po dość mocnym przybliżeniu — inaczej etykiety się zlewają
    private var showLabels: Bool { visibleSpan.longitudeDelta < 0.02 }

    // Powyżej tylu ofert kwiat zacząłby nachodzić płatkami na siebie — zamiast tego
    // dotknięcie bąbla przybliża mapę do tej grupy (jak Apple/Google Maps)
    private let maxFlowerCount = 6

    private func zoomToFit(_ offers: [Offer]) {
        let lats = offers.map(\.latitude)
        let lons = offers.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 2.2, 0.01),
            longitudeDelta: max((maxLon - minLon) * 2.2, 0.01)
        )
        withAnimation(.smooth(duration: 0.6)) {
            mapPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    // Tapnięte powiadomienie: arkusz ogłoszeń z otwartym ogłoszeniem (albo od razu rozmową).
    // Ogłoszenie, które zdążyło wygasnąć, zostawia samą listę.
    private func openAlert(_ route: NEIAlertRoute) async {
        var path = NavigationPath()
        if !route.alertId.isEmpty,
           let alert = try? await NEIAlertService().fetch(id: route.alertId),
           alert.expiresAt > Date() {
            path.append(alert)
            if let viewerId = route.viewerId, let uid = authService.currentUser?.uid {
                if viewerId == uid {
                    let name = authService.currentUser?.displayName ?? "Neighbor"
                    path.append(NEIAlertChatRoute.toAuthor(of: alert, userId: uid, userName: name))
                } else if !viewerId.isEmpty,
                          let thread = try? await NEIAlertService().fetchThread(alertId: route.alertId, viewerId: viewerId) {
                    path.append(NEIAlertChatRoute.toViewer(of: alert, thread: thread))
                }
            }
        }
        alertsPath = path
        // Inny arkusz (oferta, nowa oferta) blokowałby pokazanie ogłoszeń — najpierw go zamykamy
        if selectedOffer != nil || showCreateOffer {
            selectedOffer = nil
            showCreateOffer = false
            try? await Task.sleep(for: .milliseconds(450))
        }
        showAlerts = true
    }

    private var alertsButton: some View {
        Button {
            showAlerts = true
        } label: {
            Image(systemName: "bell.fill")
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
                .overlay(alignment: .topTrailing) {
                    if !alertVM.alerts.isEmpty {
                        Text("\(alertVM.alerts.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.neiRed, in: Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
        }
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Neighborhood alerts")
        .accessibilityValue(alertVM.alerts.isEmpty ? "None" : "\(alertVM.alerts.count) active")
    }

    var body: some View {
        Map(position: $mapPosition) {
            UserAnnotation()

            ForEach(groupedItems) { item in
                switch item {
                case .offer(let offer):
                    Annotation("", coordinate: offer.coordinate) {
                        NEIOfferAnnotationView(offer: offer, showLabel: showLabels)
                            .onTapGesture {
                                selectedOffer = offer
                            }
                    }
                case .stack(let id, let coord, let offers):
                    Annotation("", coordinate: coord) {
                        if expandedStackId == id {
                            NEIStackFlower(
                                offers: offers,
                                onSelect: { selectedOffer = $0 },
                                onCollapse: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expandedStackId = nil
                                    }
                                }
                            )
                        } else {
                            NEIClusterAnnotationView(count: offers.count)
                                .onTapGesture {
                                    if offers.count > maxFlowerCount {
                                        zoomToFit(offers)
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            expandedStackId = id
                                        }
                                    }
                                }
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .onMapCameraChange(frequency: .onEnd) { ctx in
            let new = ctx.region.span
            withAnimation(.smooth(duration: 0.5)) {
                visibleSpan = new
                let regrouped = neiGroupOffers(mapVM.offers, span: new)
                groupedItems = regrouped
                let currentStackIds = Set(regrouped.compactMap { item -> String? in
                    if case .stack(let id, _, _) = item { return id }
                    return nil
                })
                if let expanded = expandedStackId, !currentStackIds.contains(expanded) {
                    expandedStackId = nil
                }
            }
        }
        .onChange(of: mapVM.offers.count, initial: true) { _, _ in
            expandedStackId = nil
            groupedItems = neiGroupOffers(mapVM.offers, span: visibleSpan)
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
                GlassEffectContainer(spacing: 10) {
                    VStack(spacing: 10) {
                        if locationManager.authorizationStatus == .denied ||
                           locationManager.authorizationStatus == .restricted {
                            locationDeniedBanner
                        }
                        if mapVM.isLoading {
                            ProgressView()
                                .padding(10)
                                .glassEffect(.regular, in: .circle)
                        }
                        fab
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 8)
            .background(.clear)
        }
        .overlay(alignment: .topLeading) { alertsButton }
        .sheet(isPresented: $showAlerts, onDismiss: { alertsPath = NavigationPath() }) {
            NEIAlertsView(vm: alertVM, path: $alertsPath)
        }
        .onChange(of: notificationRouter.pendingAlert, initial: true) { _, route in
            guard let route else { return }
            notificationRouter.pendingAlert = nil
            Task { await openAlert(route) }
        }
        .task(id: locationManager.userCoordinate) {
            guard let coord = locationManager.userCoordinate else { return }
            await alertVM.load(near: coord, currentUserId: authService.currentUser?.uid ?? "")
        }
        .onAppear {
            locationManager.requestPermission()
            let coord = locationManager.userCoordinate ?? defaultCenter
            lastLoadedCenter = coord
            Task { await mapVM.loadOffers(near: coord, currentUserId: authService.currentUser?.uid ?? "") }
        }
        .onChange(of: locationManager.userCoordinate) { _, coord in
            guard let coord else { return }
            mapPosition = .region(MKCoordinateRegion(center: coord, span: defaultSpan))
            // Pomiń przeładowanie, gdy nowa lokalizacja mieści się w promieniu ostatniego zapytania —
            // wynik i tak by się nie zmienił, a to oszczędza zbędny round-trip przy każdym uruchomieniu
            let radiusKm = NEIUserPreferences.searchRadiusKm
            if let last = lastLoadedCenter, !radiusKm.isInfinite {
                let distanceKm = CLLocation(latitude: last.latitude, longitude: last.longitude)
                    .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) / 1000
                if distanceKm < radiusKm { return }
            }
            lastLoadedCenter = coord
            Task { await mapVM.loadOffers(near: coord, currentUserId: authService.currentUser?.uid ?? "") }
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
                },
                onActiveChanged: { newValue in
                    if let id = offer.id { mapVM.setOfferActive(id: id, isActive: newValue) }
                }
            )
            .id(offer.id)
        }
        .alert("Error", isPresented: Binding(
            get: { mapVM.errorMessage != nil },
            set: { if !$0 { mapVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mapVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showCreateOffer) {
            if let uid = authService.currentUser?.uid {
                let coord = locationManager.userCoordinate ?? defaultCenter
                NEICreateOfferView(
                    ownerId: uid,
                    coordinate: coord,
                    onSaved: {
                        Task { await mapVM.loadOffers(near: coord, currentUserId: authService.currentUser?.uid ?? "") }
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
                .glassEffect(.regular.tint(.neiGreen).interactive(), in: .circle)
        }
    }

    private var locationDeniedBanner: some View {
        Text("Location access denied. Enable in Settings.")
            .font(.caption)
            .padding(10)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}

// Pinezka jako jeden kształt (głowa + ogon) — dzięki temu obrys jest ciągły
private struct NEIPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.width / 2
        let center = CGPoint(x: rect.midX, y: r)
        let tailTip = CGPoint(x: rect.midX, y: rect.maxY)
        let a = Angle.radians(asin(0.5))        // kąt styku ogona z okręgiem (~30°)

        var p = Path()
        // łuk głowy: od lewego punktu styku, górą, do prawego punktu styku
        p.addArc(center: center, radius: r,
                 startAngle: .radians(Double.pi / 2) + a,
                 endAngle: .radians(Double.pi / 2) - a,
                 clockwise: false)
        // ogon: prawy punkt styku -> czubek -> (closeSubpath) lewy punkt styku
        p.addLine(to: tailTip)
        p.closeSubpath()
        return p
    }
}

struct NEIOfferAnnotationView: View {
    let offer: Offer
    var showLabel: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    private var contrastColor: Color { colorScheme == .dark ? .white : .black }

    @State private var appeared = false

    // Deterministyczne opóźnienie z id oferty — pinezki pojawiają się kaskadą
    private var spawnDelay: Double {
        Double(abs((offer.id ?? offer.title).hashValue) % 7) * 0.05
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                NEIPinShape()
                    .fill(Color.neiGreen)
                    .overlay(NEIPinShape().stroke(contrastColor, lineWidth: 2))
                    .frame(width: 36, height: 46)
                Image(systemName: offer.category.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(contrastColor)
                    .offset(y: -5)
            }
            if showLabel {
                Text(offer.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth(duration: 0.2), value: showLabel)
        // MapKit nie animuje wstawiania/usuwania anotacji — robimy to w widoku
        .scaleEffect(appeared ? 1 : 0.1, anchor: .bottom)
        .offset(y: appeared ? 0 : 12)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.75).delay(spawnDelay)) {
                appeared = true
            }
        }
    }
}

// MARK: - Grupowanie ofert (clustering)

enum NEIMapItem: Identifiable {
    case offer(Offer)
    case stack(id: String, coordinate: CLLocationCoordinate2D, offers: [Offer])

    var id: String {
        switch self {
        case .offer(let o):          return "offer-\(o.id ?? "\(o.latitude),\(o.longitude)")"
        case .stack(let id, _, _):   return id
        }
    }
}

/// Grupuje oferty metodą zachłannego grupowania po odległości (nie po sztywnej siatce) —
/// oferta dołącza do najbliższego istniejącego skupienia, jeśli mieści się w progu
/// proporcjonalnym do aktualnego przybliżenia, inaczej zaczyna nowe. Dzięki temu pinezki
/// wizualnie blisko siebie zawsze się łączą — siatka miała artefakt granic komórek, przez
/// który sąsiadujące na ekranie pinezki czasem trafiały do różnych komórek i zostawały
/// nierozłączone. Dolny próg ~1 m zachowuje grupowanie "ten sam adres" przy max zoomie.
func neiGroupOffers(_ offers: [Offer], span: MKCoordinateSpan) -> [NEIMapItem] {
    let latThreshold = max(span.latitudeDelta * 0.07, 1e-5)
    let lonThreshold = max(span.longitudeDelta * 0.07, 1e-5)

    var clusters: [(lat: Double, lon: Double, members: [Offer])] = []
    for offer in offers {
        if let idx = clusters.firstIndex(where: {
            abs($0.lat - offer.latitude) < latThreshold && abs($0.lon - offer.longitude) < lonThreshold
        }) {
            clusters[idx].members.append(offer)
            let n = Double(clusters[idx].members.count)
            clusters[idx].lat += (offer.latitude - clusters[idx].lat) / n
            clusters[idx].lon += (offer.longitude - clusters[idx].lon) / n
        } else {
            clusters.append((lat: offer.latitude, lon: offer.longitude, members: [offer]))
        }
    }

    return clusters.map { c in
        if c.members.count == 1 { return .offer(c.members[0]) }
        let key = c.members.compactMap(\.id).joined(separator: "-")
        return .stack(
            id: "stack-\(key)",
            coordinate: CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon),
            offers: c.members
        )
    }
}

struct NEIClusterAnnotationView: View {
    let count: Int

    @Environment(\.colorScheme) private var colorScheme
    private var contrastColor: Color { colorScheme == .dark ? .white : .black }

    private var diameter: CGFloat {
        switch count {
        case ..<10:  return 34
        case ..<50:  return 42
        default:     return 50
        }
    }

    @State private var shown = false

    var body: some View {
        Text("\(count)")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(contrastColor)
            .contentTransition(.numericText(value: Double(count)))
            .frame(width: diameter, height: diameter)
            .background(Color.neiGreen)
            .clipShape(Circle())
            .overlay(Circle().stroke(contrastColor, lineWidth: 2))
            .shadow(radius: 2, y: 1)
            .scaleEffect(shown ? 1 : 0.2)
            .opacity(shown ? 1 : 0)
            .animation(.snappy, value: count)
            .animation(.snappy, value: diameter)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { shown = true }
            }
    }
}

// MARK: - Kwiat (oferty pod jednym adresem — jedna anotacja, rozwija się w wachlarz pinezek)

struct NEIMiniPin: View {
    let icon: String
    let contrast: Color

    var body: some View {
        ZStack {
            NEIPinShape()
                .fill(Color.neiGreen)
                .overlay(NEIPinShape().stroke(contrast, lineWidth: 1.5))
                .frame(width: 30, height: 38)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(contrast)
                .offset(y: -5)
        }
        .frame(width: 30, height: 38)
        .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
    }
}

struct NEIStackFlower: View {
    let offers: [Offer]
    let onSelect: (Offer) -> Void
    let onCollapse: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var bloomed = false

    private var contrast: Color { colorScheme == .dark ? .white : .black }
    private let radius: CGFloat = 44

    // Wachlarz w górnym łuku; kąt pinezki i względem środka (kropki)
    private func petalAngle(_ i: Int) -> Double {
        let n = offers.count
        let spread = min(Double(n - 1) * 80, 300)
        return n <= 1 ? 0 : -spread / 2 + spread * Double(i) / Double(n - 1)
    }

    private func petalOffset(_ i: Int) -> CGSize {
        let a = petalAngle(i) * .pi / 180
        return CGSize(width: radius * sin(a), height: -radius * cos(a) - 10)
    }

    var body: some View {
        ZStack {
            ForEach(Array(offers.enumerated()), id: \.element.id) { i, offer in
                NEIMiniPin(icon: offer.category.systemImage, contrast: contrast)
                    .offset(bloomed ? petalOffset(i) : .zero)
                    .rotationEffect(.degrees(bloomed ? petalAngle(i) * 0.35 : 0), anchor: .bottom)
                    .scaleEffect(bloomed ? 1 : 0.2)
                    .opacity(bloomed ? 1 : 0)
                    .onTapGesture { onSelect(offer) }
                    .animation(.spring(response: 0.42, dampingFraction: 0.72)
                        .delay(Double(i) * 0.04), value: bloomed)
            }

            Text("\(offers.count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.neiGreen)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .onTapGesture { onCollapse() }
        }
        .frame(width: radius * 2 + 60, height: radius * 2 + 70)
        .onAppear { bloomed = true }
    }
}

#Preview {
    NEIMapView()
        .environmentObject(NEIAuthService())
        .environment(LocationManager())
}
