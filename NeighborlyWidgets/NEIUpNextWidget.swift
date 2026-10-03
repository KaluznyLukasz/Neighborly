//
//  NEIUpNextWidget.swift
//  NeighborlyWidgets
//

import SwiftUI
import UIKit
import WidgetKit

// "Up Next": najbliższe terminy (zwroty i umówione dni) i ochotnicy czekający na odpowiedź
struct NEIUpNextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NEIWidgetKind.upNext, provider: NEIUpNextProvider()) { entry in
            NEIUpNextWidgetView(entry: entry)
                .neiWidgetBackground()
        }
        .configurationDisplayName("Up Next")
        .description("Your next agreed dates, and volunteers waiting for your answer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NEIUpNextEntry: TimelineEntry {
    let date: Date
    // nil = aplikacja jeszcze nic nie zapisała albo nikt nie jest zalogowany
    let snapshot: NEIUpNextSnapshot?

    // Umówiony dzień znika po swoim dniu; zwrot zostaje, póki transakcja jest otwarta
    var plans: [NEIUpNextSnapshot.Plan] {
        (snapshot?.plans ?? []).filter { $0.isReturn || !NEIDueDate.isPast($0.dueDate, hasTime: false, now: date) }
    }

    var waitingCount: Int { snapshot?.waitingCount ?? 0 }
}

struct NEIUpNextProvider: TimelineProvider {
    func placeholder(in context: Context) -> NEIUpNextEntry {
        NEIUpNextEntry(date: .now, snapshot: .preview)
    }

    // W galerii widżetów, zanim aplikacja coś zapisze, pokazujemy przykład
    func getSnapshot(in context: Context, completion: @escaping @Sendable (NEIUpNextEntry) -> Void) {
        let snapshot = NEIWidgetStore.upNext ?? (context.isPreview ? .preview : nil)
        completion(NEIUpNextEntry(date: .now, snapshot: snapshot))
    }

    // Teksty zmieniają się o północy ("tomorrow" → "today") i w chwili terminu z godziną
    // (zwrot przechodzi w "Was due back"). Wpisy na te chwile w ciągu dwóch dni, potem nowa oś.
    // Zmiany samych danych przeładowuje aplikacja (NEIWidgetSync).
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<NEIUpNextEntry>) -> Void) {
        let snapshot = NEIWidgetStore.upNext
        let now = Date()
        let horizon = now.addingTimeInterval(48 * 60 * 60)
        let calendar = Calendar.current

        var dates: Set<Date> = [now]
        var day = calendar.startOfDay(for: now)
        while let next = calendar.date(byAdding: .day, value: 1, to: day), next <= horizon {
            dates.insert(next)
            day = next
        }
        for plan in snapshot?.plans ?? [] where plan.hasTime && plan.dueDate > now && plan.dueDate <= horizon {
            dates.insert(plan.dueDate)
        }

        let entries = dates.sorted().map { NEIUpNextEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widok

struct NEIUpNextWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NEIUpNextEntry

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NEIWidgetHeader(title: "Up Next", systemImage: "calendar") {
                // Bez terminów liczba ochotników jest treścią widżetu, nie dopiskiem
                if entry.waitingCount > 0 && !entry.plans.isEmpty {
                    NEIWaitingBadge(count: entry.waitingCount, isCompact: isSmall)
                }
            }

            if !isSmall && !entry.plans.isEmpty {
                NEIPlanList(plans: entry.plans, now: entry.date)
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
        if entry.snapshot == nil {
            NEIWidgetMessage(title: "Open Neighborly", message: "Your agreed dates will show up here.")
        } else if let plan = entry.plans.first {
            NEIPlanSummary(plan: plan, now: entry.date, moreCount: entry.plans.count - 1)
        } else if entry.waitingCount > 0 {
            NEIWaitingSummary(count: entry.waitingCount)
        } else {
            NEIWidgetMessage(title: "Nothing Planned", message: "Dates you agree on with neighbors show up here.")
        }
    }

    // Mały widżet otwiera najbliższy termin; średni ma osobne linki w wierszach, a reszta
    // otwiera Activity
    private var defaultLink: NEIWidgetLink {
        if isSmall, let plan = entry.plans.first { return .transaction(id: plan.id) }
        return .activity
    }
}

// Mały widżet: najbliższy termin z kolorem kategorii, niżej "+2 more". Przy dużym tekście
// najpierw znika licznik, potem imię.
private struct NEIPlanSummary: View {
    let plan: NEIUpNextSnapshot.Plan
    let now: Date
    let moreCount: Int

    var body: some View {
        ViewThatFits(in: .vertical) {
            details(showSubtitle: true, showMore: true)
            details(showSubtitle: true, showMore: false)
            details(showSubtitle: false, showMore: false)
        }
    }

    private func details(showSubtitle: Bool, showMore: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                NEICategoryBar(color: plan.category.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.headline)
                        .lineLimit(2)
                    NEIPlanDueText(plan: plan, now: now)
                        .font(.caption.weight(.medium))
                        .lineLimit(2)
                    if showSubtitle {
                        Text(plan.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)

            if showMore && moreCount > 0 {
                Text("+\(moreCount) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(moreCount) more planned")
            }
        }
    }
}

// Średni widżet: do trzech terminów, każdy otwiera swoją transakcję. Ile się zmieści, zależy
// od wielkości telefonu i tekstu — najpierw znika "+2 more", potem kolejne wiersze.
private struct NEIPlanList: View {
    let plans: [NEIUpNextSnapshot.Plan]
    let now: Date

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach([3, 2, 1], id: \.self) { count in
                rows(count, showMore: true)
                rows(count, showMore: false)
            }
        }
    }

    private func rows(_ count: Int, showMore: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(plans.prefix(count)) { plan in
                Link(destination: NEIWidgetLink.transaction(id: plan.id).url) {
                    NEIPlanRow(plan: plan, now: now)
                }
            }
            if showMore && plans.count > count {
                Text("+\(plans.count - count) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)
                    .accessibilityLabel("\(plans.count - count) more planned")
            }
        }
    }
}

private struct NEIPlanRow: View {
    let plan: NEIUpNextSnapshot.Plan
    let now: Date

    var body: some View {
        HStack(spacing: 8) {
            NEICategoryBar(color: plan.category.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(plan.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    NEIPlanDueText(plan: plan, now: now)
                    Text("·")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    Text(plan.subtitle)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        // Link barwi treść kolorem akcentu — kolory tekstu ustawiamy sami
        .foregroundStyle(Color(.label))
        .accessibilityElement(children: .combine)
    }
}

// Pasek w kolorze kategorii, jak w Kalendarzu
private struct NEICategoryBar: View {
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 4)
            .widgetAccentable()
            .accessibilityHidden(true)
    }
}

// "Due back tomorrow at 15:00" — czerwony z wykrzyknikiem po terminie, pomarańczowy w dniu
// terminu, jak w liście Activity
private struct NEIPlanDueText: View {
    let plan: NEIUpNextSnapshot.Plan
    let now: Date

    private var isOverdue: Bool {
        plan.isReturn && NEIDueDate.isPast(plan.dueDate, hasTime: plan.hasTime, now: now)
    }

    private var style: AnyShapeStyle {
        if isOverdue { return AnyShapeStyle(.red) }
        if Calendar.current.isDate(plan.dueDate, inSameDayAs: now) { return AnyShapeStyle(.orange) }
        return AnyShapeStyle(.secondary)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .accessibilityHidden(true)
            }
            Text(NEIDueDate.rowText(plan.dueDate, hasTime: plan.hasTime, isReturn: plan.isReturn, now: now))
        }
        .foregroundStyle(style)
    }
}

// Ochotnicy czekający na decyzję — w nagłówku, gdy są też terminy
private struct NEIWaitingBadge: View {
    let count: Int
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "person.badge.clock.fill")
                .foregroundStyle(.orange)
                .widgetAccentable()
            Text(isCompact ? "\(count)" : "\(count) waiting")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(NEIWaitingSummary.text(count: count))
    }
}

// Bez terminów: sama liczba ochotników na środku uwagi
private struct NEIWaitingSummary: View {
    let count: Int

    static func text(count: Int) -> String {
        count == 1 ? "1 volunteer waiting for your answer" : "\(count) volunteers waiting for your answer"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(count)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .widgetAccentable()
            Text(count == 1 ? "volunteer waiting for your answer" : "volunteers waiting for your answer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.text(count: count))
    }
}

extension NEIUpNextSnapshot.Plan {
    // Kto po drugiej stronie; ochotnik nie zna imienia autora, więc widzi kategorię
    var subtitle: String {
        volunteerName.map { "with \($0)" } ?? category.displayName
    }
}

// MARK: - Przykładowe dane (galeria widżetów, podglądy)

extension NEIUpNextSnapshot {
    static var preview: NEIUpNextSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func day(_ offset: Int, hour: Int = 0) -> Date {
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        }
        return NEIUpNextSnapshot(
            plans: [
                Plan(id: "preview-1", title: "Fix the kitchen tap", category: .tools, isReturn: false,
                     volunteerName: "Anna", dueDate: day(1, hour: 17), hasTime: true),
                Plan(id: "preview-2", title: "Ladder", category: .items, isReturn: true,
                     volunteerName: "Tomek", dueDate: day(3), hasTime: false),
                Plan(id: "preview-3", title: "Weekly shopping", category: .food, isReturn: false,
                     volunteerName: nil, dueDate: day(5), hasTime: false)
            ],
            waitingCount: 2
        )
    }
}

#Preview("Small", as: .systemSmall) {
    NEIUpNextWidget()
} timeline: {
    NEIUpNextEntry(date: .now, snapshot: .preview)
    NEIUpNextEntry(date: .now, snapshot: NEIUpNextSnapshot(plans: [], waitingCount: 2))
    NEIUpNextEntry(date: .now, snapshot: NEIUpNextSnapshot(plans: [], waitingCount: 0))
    NEIUpNextEntry(date: .now, snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    NEIUpNextWidget()
} timeline: {
    NEIUpNextEntry(date: .now, snapshot: .preview)
    NEIUpNextEntry(date: .now, snapshot: NEIUpNextSnapshot(plans: [], waitingCount: 1))
    NEIUpNextEntry(date: .now, snapshot: NEIUpNextSnapshot(plans: [], waitingCount: 0))
}
