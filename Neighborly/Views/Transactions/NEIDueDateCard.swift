//
//  NEIDueDateCard.swift
//  Neighborly
//

import SwiftUI
import UserNotifications

// Termin transakcji w szczegółach: zwrot rzeczy albo umówiony dzień. Właściciel ustawia go jak
// w aplikacji Przypomnienia — przełącznik daty z kalendarzem i opcjonalna godzina. Druga strona
// widzi termin tylko do odczytu. Pod kartą: kiedy przyjdą przypomnienia i co zrobić, gdy
// powiadomienia są wyłączone.
struct NEIDueDateCard: View {
    let dateKind: TransactionDateKind
    let isOwner: Bool
    let userId: String
    let dueDate: Date?
    let hasTime: Bool
    let onChange: (_ dueDate: Date?, _ hasTime: Bool) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @AppStorage(NEIUserPreferences.remindersKey) private var remindersOn = true
    @State private var expanded: Field?
    @State private var notificationStatus: UNAuthorizationStatus?

    private enum Field { case date, time }

    private var isReturn: Bool { dateKind == .returnDate }
    private var calendar: Calendar { .current }
    private var today: Date { calendar.startOfDay(for: Date()) }

    private var isOverdue: Bool {
        guard isReturn, let dueDate else { return false }
        return NEIDueDate.isPast(dueDate, hasTime: hasTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if isOwner {
                    editor
                } else {
                    summary
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))

            footer
                .padding(.horizontal, 4)
        }
        .task { await refreshNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
    }

    // MARK: - Właściciel: edycja

    private var editor: some View {
        VStack(spacing: 0) {
            toggleRow(
                title: isReturn ? "Return Date" : "Date",
                systemImage: "calendar",
                tint: .red,
                // Godzina ma swój wiersz, więc tu sam dzień
                value: dueDate.map { dateValue($0, includeTime: false) },
                valueColor: isOverdue ? .red : .accentColor,
                isOn: dateIsOn,
                field: .date
            )

            if let dueDate {
                if expanded == .date {
                    Divider().padding(.leading, 14)
                    DatePicker(
                        isReturn ? "Return Date" : "Date",
                        selection: daySelection(dueDate),
                        in: min(calendar.startOfDay(for: dueDate), today)...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
                }

                Divider().padding(.leading, 14)

                toggleRow(
                    title: "Time",
                    systemImage: "clock.fill",
                    tint: .blue,
                    value: hasTime ? NEIDueDate.timeText(dueDate) : nil,
                    valueColor: .accentColor,
                    isOn: timeIsOn(dueDate),
                    field: .time
                )

                if hasTime && expanded == .time {
                    Divider().padding(.leading, 14)
                    DatePicker("Time", selection: timeSelection(dueDate), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
        }
    }

    // Wiersz jak w Przypomnieniach: tapnięcie w opis rozwija kalendarz (albo włącza przełącznik)
    private func toggleRow(
        title: String,
        systemImage: String,
        tint: Color,
        value: String?,
        valueColor: Color,
        isOn: Binding<Bool>,
        field: Field
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                if isOn.wrappedValue {
                    withAnimation(.snappy) { expanded = expanded == field ? nil : field }
                } else {
                    isOn.wrappedValue = true
                }
            } label: {
                HStack(spacing: 12) {
                    NEISettingsIcon(systemImage: systemImage, tint: tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .foregroundStyle(Color(.label))
                        if let value {
                            Text(value)
                                .font(.subheadline)
                                .foregroundStyle(valueColor)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(value ?? "Off")
            .accessibilityHint(rowHint(isOn: isOn.wrappedValue, field: field))

            Toggle(title, isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func rowHint(isOn: Bool, field: Field) -> String {
        guard isOn else { return "Turns it on" }
        let picker = field == .date ? "calendar" : "time picker"
        return expanded == field ? "Hides the \(picker)" : "Shows the \(picker)"
    }

    // MARK: - Druga strona: podgląd

    private var summary: some View {
        HStack(spacing: 12) {
            NEISettingsIcon(systemImage: "calendar", tint: .red)
            VStack(alignment: .leading, spacing: 1) {
                if let dueDate {
                    Text(isReturn ? "Return by" : "Planned for")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(dateValue(dueDate))
                        .font(.headline)
                        .foregroundStyle(isOverdue ? .red : Color(.label))
                } else {
                    Text(isReturn ? "No return date yet" : "No date yet")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stopka

    @ViewBuilder
    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(explanation)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let dueDate, !NEIDueDate.isPast(dueDate, hasTime: hasTime) {
                notificationHint
            }
        }
    }

    private var explanation: String {
        guard let dueDate else {
            if isOwner {
                return isReturn
                    ? "Set a return date and you'll both get reminders before it's due."
                    : "Pick a date and you'll both get reminders before it."
            }
            return "You'll get reminders once a date is set."
        }
        // Po terminie przypomnienia już nie pomogą — mówimy, co zrobić dalej
        if NEIDueDate.isPast(dueDate, hasTime: hasTime) {
            if isReturn {
                return isOwner
                    ? "Once you have it back, mark it as completed. To give more time, pick a new date."
                    : "Return it, or message the owner to agree on a new date."
            }
            return isOwner
                ? "If it's done, mark it as completed. To plan it again, pick a new date."
                : "If it's done, the owner will mark it as completed."
        }
        let who = isOwner ? "You'll both get" : "You'll get"
        let when = hasTime ? "an hour before" : "on the morning of the day"
        return "\(who) a reminder the evening before and \(when)."
    }

    // Co blokuje przypomnienia na tym telefonie i jak to naprawić jednym tapnięciem
    @ViewBuilder
    private var notificationHint: some View {
        if !remindersOn {
            hint("Reminders are off.", systemImage: "bell.slash.fill", action: "Turn On") {
                remindersOn = true
                Task {
                    if notificationStatus == .notDetermined { _ = await NEIReminderService.requestAuthorization() }
                    await NEIReminderService.resync(userId: userId)
                    await refreshNotificationStatus()
                }
            }
        } else {
            switch notificationStatus {
            case .denied:
                hint("Notifications are off for Neighborly.", systemImage: "bell.slash.fill", action: "Open Settings") {
                    openNotificationSettings()
                }
            case .notDetermined:
                hint("Allow notifications to get these reminders.", systemImage: "bell.badge.fill", action: "Allow") {
                    Task { await requestFullAuthorization() }
                }
            case .provisional:
                hint("Reminders arrive quietly in Notification Center.", systemImage: "bell.fill", action: "Show Alerts") {
                    Task { await requestFullAuthorization() }
                }
            default:
                EmptyView()
            }
        }
    }

    private func hint(_ text: String, systemImage: String, action: String, perform: @escaping () -> Void) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .foregroundStyle(.secondary)
                Button(action, action: perform)
                    .fontWeight(.semibold)
            }
        }
        .font(.footnote)
    }

    // MARK: - Wiązania

    private var dateIsOn: Binding<Bool> {
        Binding(
            get: { dueDate != nil },
            set: { on in
                if on {
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
                    onChange(tomorrow, false)
                    withAnimation(.snappy) { expanded = .date }
                    Task { await askForPermissionIfNeeded() }
                } else {
                    onChange(nil, false)
                    withAnimation(.snappy) { expanded = nil }
                }
            }
        )
    }

    private func timeIsOn(_ dueDate: Date) -> Binding<Bool> {
        Binding(
            get: { hasTime },
            set: { on in
                if on {
                    onChange(defaultTime(on: dueDate), true)
                    withAnimation(.snappy) { expanded = .time }
                } else {
                    onChange(calendar.startOfDay(for: dueDate), false)
                    withAnimation(.snappy) { if expanded == .time { expanded = nil } }
                }
            }
        )
    }

    // Zmiana dnia zachowuje wybraną godzinę
    private func daySelection(_ dueDate: Date) -> Binding<Date> {
        Binding(
            get: { dueDate },
            set: { day in
                let time = calendar.dateComponents([.hour, .minute], from: dueDate)
                let start = calendar.startOfDay(for: day)
                let combined = hasTime
                    ? calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: start) ?? start
                    : start
                onChange(combined, hasTime)
            }
        )
    }

    private func timeSelection(_ dueDate: Date) -> Binding<Date> {
        Binding(
            get: { dueDate },
            set: { time in
                let parts = calendar.dateComponents([.hour, .minute], from: time)
                let combined = calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: dueDate) ?? dueDate
                onChange(combined, true)
            }
        )
    }

    // Dziś: najbliższa pełna godzina; inny dzień: 10:00
    private func defaultTime(on day: Date) -> Date {
        let start = calendar.startOfDay(for: day)
        var hour = 10
        if calendar.isDateInToday(day) {
            hour = min(calendar.component(.hour, from: Date()) + 1, 23)
        }
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start) ?? start
    }

    // "Tomorrow", "Thursday at 15:00", "Yesterday · Overdue"
    private func dateValue(_ date: Date, includeTime: Bool = true) -> String {
        let text = NEIDueDate.dayText(date, hasTime: hasTime && includeTime)
        return isOverdue ? "\(text) · Overdue" : text
    }

    // MARK: - Powiadomienia

    private func refreshNotificationStatus() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // Systemowe pytanie o zgodę pojawia się w chwili ustawienia terminu, gdy widać, po co jest
    private func askForPermissionIfNeeded() async {
        guard remindersOn, notificationStatus == .notDetermined else { return }
        await requestFullAuthorization()
    }

    // Gdy system już nie pyta (np. po cichej zgodzie), zostają ustawienia powiadomień
    private func requestFullAuthorization() async {
        let before = notificationStatus
        _ = await NEIReminderService.requestAuthorization()
        await refreshNotificationStatus()
        if before == .provisional, notificationStatus == .provisional {
            openNotificationSettings()
        }
        await NEIReminderService.resync(userId: userId)
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}
