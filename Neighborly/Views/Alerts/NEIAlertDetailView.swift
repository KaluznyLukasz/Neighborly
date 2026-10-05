//
//  NEIAlertDetailView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import FirebaseAuth

struct NEIAlertDetailView: View {
    let alert: NeighborhoodAlert

    @EnvironmentObject var authService: NEIAuthService
    @Environment(LocationManager.self) private var locationManager
    @State private var threads: [AlertThread] = []
    @State private var errorMessage: String?
    @State private var showChat = false
    @State private var reportTarget: NEIReportTarget?

    private let alertService = NEIAlertService()
    private var uid: String { authService.currentUser?.uid ?? "" }
    private var userName: String { authService.currentUser?.displayName ?? "Neighbor" }
    private var alertId: String { alert.id ?? "" }
    private var isAuthor: Bool { alert.authorId == uid }

    private var photo: UIImage? {
        alert.imageBase64.flatMap { NEIBase64ImageCache.decodedImage(base64: $0) }
    }

    private var distanceText: String? {
        guard let origin = locationManager.userCoordinate else { return nil }
        let meters = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: alert.latitude, longitude: alert.longitude))
        return Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    var body: some View {
        List {
            if let photo {
                Section {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .background(.fill.tertiary)
                        .listRowInsets(EdgeInsets())
                        .accessibilityIgnoresInvertColors()
                        .accessibilityLabel("Alert photo")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(alert.kind.displayName, systemImage: alert.kind.systemImage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(alert.kind.color)
                    Text(alert.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    if !alert.details.isEmpty {
                        Text(alert.details)
                            .font(.body)
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                NavigationLink {
                    NEIUserProfileView(userId: alert.authorId)
                } label: {
                    LabeledContent("Posted by", value: alert.authorName)
                }
                LabeledContent("Posted") {
                    Text(alert.createdAt, format: .relative(presentation: .named, unitsStyle: .wide))
                }
                LabeledContent("Expires") {
                    Text(alert.expiresAt, format: .relative(presentation: .named, unitsStyle: .wide))
                }
                if let distanceText {
                    LabeledContent("Distance", value: distanceText)
                }
            }

            if isAuthor {
                repliesSection
            } else {
                Section {
                    Button("Report Alert", systemImage: "flag", role: .destructive) {
                        reportTarget = NEIReportTarget(
                            type: .alert,
                            targetId: alertId,
                            ownerId: alert.authorId,
                            ownerName: alert.authorName,
                            excerpt: "\(alert.title)\n\(alert.details)"
                        )
                    }
                    // Ikona w Form zostaje niebieska (docs/learnings/form-destructive-button-icon-stays-blue.md)
                    .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(alert.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isAuthor {
                NEIPrimaryButton("Message \(alert.authorName)") { showChat = true }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
        }
        .navigationDestination(isPresented: $showChat) {
            NEIAlertChatView(route: .toAuthor(of: alert, userId: uid, userName: userName))
        }
        .neiReportFlow(target: $reportTarget, reporterId: uid)
        .task { if isAuthor { await loadThreads() } }
        .refreshable { if isAuthor { await loadThreads() } }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var repliesSection: some View {
        Section("Replies") {
            if threads.isEmpty {
                Text("No one has replied yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(threads) { thread in
                    NavigationLink {
                        NEIAlertChatView(route: .toViewer(of: alert, thread: thread))
                    } label: {
                        HStack(spacing: 12) {
                            NEIAvatarView(url: nil, name: thread.viewerName, size: 40, base64: nil)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(thread.viewerName)
                                    .font(.headline)
                                Text(thread.lastMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(thread.updatedAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func loadThreads() async {
        do {
            threads = try await alertService.fetchThreads(alertId: alertId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
