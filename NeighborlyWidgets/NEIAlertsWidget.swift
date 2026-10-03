//
//  NEIAlertsWidget.swift
//  NeighborlyWidgets
//

import SwiftUI
import UIKit
import WidgetKit

// "Alerts": najnowsze ogłoszenia sąsiadów w promieniu wyszukiwania (zaginione zwierzęta,
// bezpieczeństwo, awarie)
struct NEIAlertsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NEIWidgetKind.alerts, provider: NEIAlertsProvider()) { entry in
            NEIAlertsWidgetView(entry: entry)
                .neiWidgetBackground()
        }
        .configurationDisplayName("Alerts")
        .description("The latest lost pets, safety notices and outages from neighbors nearby.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NEIAlertsEntry: TimelineEntry {
    let date: Date
    // nil = aplikacja jeszcze nic nie zapisała albo nikt nie jest zalogowany
    let snapshot: NEIAlertsSnapshot?

    var alerts: [NEIAlertsSnapshot.Alert] {
        (snapshot?.alerts ?? []).filter { $0.expiresAt > date }
    }
}

struct NEIAlertsProvider: TimelineProvider {
    func placeholder(in context: Context) -> NEIAlertsEntry {
        NEIAlertsEntry(date: .now, snapshot: .preview)
    }

    // W galerii widżetów, zanim aplikacja coś zapisze, pokazujemy przykład
    func getSnapshot(in context: Context, completion: @escaping @Sendable (NEIAlertsEntry) -> Void) {
        let snapshot = NEIWidgetStore.alerts ?? (context.isPreview ? .preview : nil)
        completion(NEIAlertsEntry(date: .now, snapshot: snapshot))
    }

    // "40 minutes ago" odświeża się samo (Text z .currentDate), więc wpisy potrzebne są tylko
    // o północy (godzina → "Yesterday" w średnim widżecie) i gdy ogłoszenie wygasa.
    // Nowe ogłoszenia przeładowuje aplikacja (NEIWidgetSync).
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<NEIAlertsEntry>) -> Void) {
        let snapshot = NEIWidgetStore.alerts
        let now = Date()
        let calendar = Calendar.current
        let expiries = (snapshot?.alerts ?? []).map(\.expiresAt).filter { $0 > now }
        // Ogłoszenie żyje 48 h, więc dalej niż ostatnie wygaśnięcie nie trzeba patrzeć
        var midnights: [Date] = []
        var day = calendar.startOfDay(for: now)
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next < (expiries.max() ?? now) {
            midnights.append(next)
            day = next
        }
        let dates = Set([now] + expiries + midnights).sorted()
        let entries = dates.map { NEIAlertsEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: expiries.isEmpty ? .never : .atEnd))
    }
}

// MARK: - Widok

struct NEIAlertsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NEIAlertsEntry

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NEIWidgetHeader(title: "Alerts", systemImage: "bell.fill") {
                if !entry.alerts.isEmpty {
                    Text("\(entry.alerts.count)")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(entry.alerts.count == 1 ? "1 active alert" : "\(entry.alerts.count) active alerts")
                }
            }

            if !isSmall && !entry.alerts.isEmpty {
                NEIAlertList(alerts: entry.alerts, now: entry.date)
                    .padding(.top, 8)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 8)
                content
            }
        }
        .widgetURL(defaultLink.url)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            if !snapshot.hasLocation {
                NEIWidgetMessage(title: "Location Off", message: "Allow location access to see alerts from neighbors nearby.")
            } else if let alert = entry.alerts.first {
                NEIAlertSummary(alert: alert)
            } else {
                NEIWidgetMessage(title: "All Quiet", message: Self.quietMessage(radiusKm: snapshot.radiusKm))
            }
        } else {
            NEIWidgetMessage(title: "Open Neighborly", message: "Alerts from neighbors nearby will show up here.")
        }
    }

    private static func quietMessage(radiusKm: Double?) -> String {
        guard let radiusKm else { return "No alerts right now." }
        let radius = Measurement(value: radiusKm, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
        return "No alerts within \(radius) right now."
    }

    // Mały widżet otwiera najnowsze ogłoszenie; średni ma osobne linki w wierszach, a reszta
    // otwiera listę ogłoszeń
    private var defaultLink: NEIWidgetLink {
        if isSmall, let alert = entry.alerts.first { return .alert(id: alert.id) }
        return .alerts
    }
}

// Mały widżet: najnowsze ogłoszenie. Przy dużym tekście najpierw znika czas.
private struct NEIAlertSummary: View {
    let alert: NEIAlertsSnapshot.Alert

    var body: some View {
        ViewThatFits(in: .vertical) {
            details(showTime: true)
            details(showTime: false)
        }
    }

    private func details(showTime: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            NEIWidgetIconTile(systemImage: alert.kind.systemImage, color: alert.kind.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(alert.kindAndDistance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if showTime {
                    NEIAlertAge(alert: alert)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// Średni widżet: do trzech ogłoszeń, każde otwiera swoje szczegóły. Ile się zmieści, zależy
// od wielkości telefonu i tekstu.
private struct NEIAlertList: View {
    let alerts: [NEIAlertsSnapshot.Alert]
    let now: Date

    var body: some View {
        ViewThatFits(in: .vertical) {
            rows(3)
            rows(2)
            rows(1)
        }
    }

    private func rows(_ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(alerts.prefix(count)) { alert in
                Link(destination: NEIWidgetLink.alert(id: alert.id).url) {
                    NEIAlertRow(alert: alert, now: now)
                }
            }
        }
    }
}

private struct NEIAlertRow: View {
    let alert: NEIAlertsSnapshot.Alert
    let now: Date

    var body: some View {
        HStack(spacing: 10) {
            NEIWidgetIconTile(systemImage: alert.kind.systemImage, color: alert.kind.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(alert.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(alert.kindAndDistance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(alert.postedText(now: now))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        // Link barwi treść kolorem akcentu — kolory tekstu ustawiamy sami
        .foregroundStyle(Color(.label))
        .accessibilityElement(children: .combine)
    }
}

// "40 min ago", "3 hr ago" — odświeża się samo, bez nowych wpisów osi czasu
private struct NEIAlertAge: View {
    let alert: NEIAlertsSnapshot.Alert

    var body: some View {
        Text(.currentDate, format: .reference(to: alert.createdAt, allowedFields: [.day, .hour, .minute], maxFieldCount: 1))
            .lineLimit(1)
    }
}

extension NEIAlertsSnapshot.Alert {
    // "Lost Pet · 350 m" — jak w powiadomieniu o nowym ogłoszeniu
    var kindAndDistance: String {
        let distance = Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
        return "\(kind.displayName) · \(distance)"
    }

    // Jak w Wiadomościach: "14:24" dziś, "Yesterday", dalej dzień tygodnia
    func postedText(now: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(createdAt, inSameDayAs: now) { return NEIDueDate.timeText(createdAt) }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(createdAt, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return createdAt.formatted(.dateTime.weekday(.abbreviated))
    }
}

// MARK: - Przykładowe dane (galeria widżetów, podglądy)

extension NEIAlertsSnapshot {
    static var preview: NEIAlertsSnapshot {
        let now = Date()
        func alert(_ id: String, _ kind: AlertKind, _ title: String, meters: Double, minutesAgo: Double) -> Alert {
            let created = now.addingTimeInterval(-minutesAgo * 60)
            return Alert(id: id, kind: kind, title: title, meters: meters,
                         createdAt: created, expiresAt: created.addingTimeInterval(48 * 60 * 60))
        }
        return NEIAlertsSnapshot(
            alerts: [
                alert("preview-1", .lostPet, "Grey cat missing near the park", meters: 350, minutesAgo: 40),
                alert("preview-2", .utilities, "No water until 6 pm", meters: 1_200, minutesAgo: 190),
                alert("preview-3", .safety, "Bike thefts on Lipowa Street", meters: 800, minutesAgo: 26 * 60)
            ],
            radiusKm: 10,
            hasLocation: true
        )
    }
}

#Preview("Small", as: .systemSmall) {
    NEIAlertsWidget()
} timeline: {
    NEIAlertsEntry(date: .now, snapshot: .preview)
    NEIAlertsEntry(date: .now, snapshot: NEIAlertsSnapshot(alerts: [], radiusKm: 10, hasLocation: true))
    NEIAlertsEntry(date: .now, snapshot: NEIAlertsSnapshot(alerts: [], radiusKm: nil, hasLocation: false))
    NEIAlertsEntry(date: .now, snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    NEIAlertsWidget()
} timeline: {
    NEIAlertsEntry(date: .now, snapshot: .preview)
    NEIAlertsEntry(date: .now, snapshot: NEIAlertsSnapshot(alerts: [], radiusKm: 10, hasLocation: true))
}
