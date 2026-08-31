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
                if vm.searchText.isEmpty && vm.selectedCategory == nil {
                    ScrollView { categoryGrid }
                } else {
                    categoryChipRow
                    resultsList
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            locationManager.requestPermission()
            await vm.loadOffers(near: locationManager.userCoordinate ?? searchDefaultCenter)
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
            categoryTile(title: "All", systemImage: "square.grid.2x2.fill", color: .neiOnyx, isSelected: vm.selectedCategory == nil) {
                vm.selectedCategory = nil
            }
            ForEach(OfferCategory.allCases) { category in
                categoryTile(title: category.displayName, systemImage: category.systemImage, color: category.color, isSelected: vm.selectedCategory == category) {
                    vm.selectedCategory = category
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func categoryTile(title: String, systemImage: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .scaleEffect(isSelected ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .aspectRatio(1.8, contentMode: .fit)
        .buttonStyle(.plain)
    }

    private var categoryChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", color: .neiOnyx, isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(OfferCategory.allCases) { category in
                    categoryChip(title: category.displayName, color: category.color, isSelected: vm.selectedCategory == category) {
                        vm.selectedCategory = vm.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private func categoryChip(title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray4))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultsList: some View {
        if vm.filteredOffers.isEmpty {
            Text("No offers match your search")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(vm.filteredOffers) { offer in
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
                await vm.loadOffers(near: locationManager.userCoordinate ?? searchDefaultCenter)
            }
        }
    }
}

#Preview {
    NEISearchView()
        .environmentObject(NEIAuthService())
}
