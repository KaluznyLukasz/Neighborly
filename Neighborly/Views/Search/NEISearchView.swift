//
//  NEISearchView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import FirebaseAuth

struct NEISearchView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEISearchViewModel()
    @State private var locationManager = LocationManager()
    @State private var selectedOffer: Offer?

    private let searchDefaultCenter = CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                if vm.searchText.isEmpty {
                    ScrollView { categoryGrid }
                } else {
                    resultsList(vm.filteredOffers)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: SearchDestination.self) { destination in
                categoryResultsView(for: destination)
            }
        }
        .task {
            locationManager.requestPermission()
            await vm.loadOffers(near: locationManager.userCoordinate ?? searchDefaultCenter, currentUserId: authService.currentUser?.uid ?? "")
        }
        .sheet(item: $selectedOffer) { offer in
            NEIOfferDetailView(
                offer: offer,
                currentUserId: authService.currentUser?.uid ?? "",
                currentUserName: authService.currentUser?.displayName ?? "User",
                onDelete: nil
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search offers", text: $vm.searchText)
                .textFieldStyle(.plain)
            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.neiSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            NavigationLink(value: SearchDestination.all) {
                categoryTile(title: "All", systemImage: "square.grid.2x2.fill", color: .neiOnyx)
            }
            .buttonStyle(.plain)

            ForEach(OfferCategory.allCases) { category in
                NavigationLink(value: SearchDestination.category(category)) {
                    categoryTile(title: category.displayName, systemImage: category.systemImage, color: category.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func categoryTile(title: String, systemImage: String, color: Color) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.gradient)

            Image(systemName: systemImage)
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white.opacity(0.22))
                .rotationEffect(.degrees(-12))
                .offset(x: 22, y: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .clipped()

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .aspectRatio(1.8, contentMode: .fit)
    }

    @ViewBuilder
    private func categoryResultsView(for destination: SearchDestination) -> some View {
        let offers = switch destination {
        case .all: vm.offers
        case .category(let category): vm.offers.filter { $0.category == category }
        }
        resultsList(offers)
            .navigationTitle(destination.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func resultsList(_ offers: [Offer]) -> some View {
        if offers.isEmpty {
            Text("No offers match your search")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(offers) { offer in
                    Button {
                        selectedOffer = offer
                    } label: {
                        OfferRow(offer: offer)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await vm.loadOffers(near: locationManager.userCoordinate ?? searchDefaultCenter, currentUserId: authService.currentUser?.uid ?? "")
            }
        }
    }
}

private enum SearchDestination: Hashable {
    case all
    case category(OfferCategory)

    var title: String {
        switch self {
        case .all: return "All Offers"
        case .category(let category): return category.displayName
        }
    }
}

#Preview {
    NEISearchView()
        .environmentObject(NEIAuthService())
}
