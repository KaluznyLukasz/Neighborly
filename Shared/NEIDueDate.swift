//
//  NEIDueDate.swift
//  Neighborly
//

import Foundation

// Wspólne formatowanie i logika terminu — lista, szczegóły, przypomnienia i widżet mówią to samo
enum NEIDueDate {
    // Termin bez godziny mija dopiero po końcu dnia
    static func isPast(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        hasTime ? date < now : date < calendar.startOfDay(for: now)
    }

    // "Today", "Tomorrow at 15:00", "Thursday, 3 October" — dzień tygodnia tylko w ciągu tygodnia
    static func dayText(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "Tomorrow"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            day = "Yesterday"
        } else if let days = daysBetween(now, date, calendar: calendar), (2...6).contains(days) {
            day = date.formatted(.dateTime.weekday(.wide))
        } else {
            day = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        }
        return hasTime ? "\(day) at \(timeText(date))" : day
    }

    // Krótka wersja do wiersza listy: "Today", "Tomorrow", "Thu, 3 Oct"
    static func shortDayText(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "tomorrow"
        } else {
            day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
        return hasTime ? "\(day) at \(timeText(date))" : day
    }

    // Linijka terminu w wierszu listy i w widżecie: "Due back tomorrow at 15:00",
    // "Planned for Thu, 3 Oct", "Was due back Mon, 30 Sep"
    static func rowText(_ date: Date, hasTime: Bool, isReturn: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let day = shortDayText(date, hasTime: hasTime, now: now, calendar: calendar)
        if isReturn && isPast(date, hasTime: hasTime, now: now, calendar: calendar) { return "Was due back \(day)" }
        return isReturn ? "Due back \(day)" : "Planned for \(day)"
    }

    static func timeText(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // Ile pełnych dni po terminie (0 = termin jest dziś lub później)
    static func daysOverdue(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        max(0, daysBetween(date, now, calendar: calendar) ?? 0)
    }

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int? {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day
    }
}
