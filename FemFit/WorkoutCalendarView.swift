// WorkoutCalendarView.swift
// FemFit – Workout Kalender mit Streak
import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Query private var allSets: [WorkoutSet]
    var cycleManager = CycleManager.shared

    @State private var displayedMonth = Date()

    var trainedDays: Set<String> {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return Set(allSets.map { fmt.string(from: $0.date) })
    }

    var periodDays: Set<String> {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return Set(allSets.filter { $0.isDuringPeriod }.map { fmt.string(from: $0.date) })
    }

    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: .now)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        while trainedDays.contains(fmt.string(from: date)) {
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }
        return streak
    }

    var longestStreak: Int {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let sorted = trainedDays.sorted()
        var longest = 0; var current = 0; var prevDate: Date? = nil
        for dateStr in sorted {
            guard let date = fmt.date(from: dateStr) else { continue }
            if let prev = prevDate, Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: prev)!) {
                current += 1
            } else { current = 1 }
            longest = max(longest, current)
            prevDate = date
        }
        return longest
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakBanner
                    calendarCard
                    statsRow
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Kalender")
        }
    }

    // ── Streak Banner ──
    var streakBanner: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.system(size: 44))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak) Tage Streak")
                    .font(.title2).fontWeight(.bold)
                Text(currentStreak == 0 ? "Trainiere heute um deinen Streak zu starten!" : "Weiter so! Du bist auf dem richtigen Weg 💪")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#F4A623").opacity(0.12))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F4A623").opacity(0.3), lineWidth: 1))
    }

    // ── Kalender ──
    var calendarCard: some View {
        VStack(spacing: 12) {
            // Monats-Navigation
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left").foregroundColor(.primary) }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right").foregroundColor(.primary) }
            }

            // Wochentage
            HStack {
                ForEach(["Mo","Di","Mi","Do","Fr","Sa","So"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }

            // Tage Grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                }
            }

            // Legende
            HStack(spacing: 16) {
                legendItem(color: Color(hex: "#1D9E75"), label: "Training")
                legendItem(color: Color(hex: "#E84393"), label: "Periode-Training")
                legendItem(color: Color(uiColor: UIColor.systemGray5), label: "kein Training")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func dayCell(_ day: Date?) -> some View {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let isToday   = day.map { Calendar.current.isDateInToday($0) } ?? false
        let trained   = day.map { trainedDays.contains(fmt.string(from: $0)) } ?? false
        let inPeriod  = day.map { periodDays.contains(fmt.string(from: $0)) } ?? false
        let dayNum    = day.map { Calendar.current.component(.day, from: $0) }

        return ZStack {
            if trained {
                Circle().fill(inPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75"))
            } else if isToday {
                Circle().stroke(Color.primary, lineWidth: 1.5)
            }
            if let n = dayNum {
                Text("\(n)")
                    .font(.system(size: 13, weight: isToday || trained ? .semibold : .regular))
                    .foregroundColor(trained ? .white : .primary)
            }
        }
        .frame(height: 34)
        .opacity(day == nil ? 0 : 1)
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    // ── Stats ──
    var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(currentStreak)🔥", label: "Aktuell")
            statTile(value: "\(longestStreak)⭐", label: "Rekord")
            statTile(value: "\(trainedDays.count)", label: "Gesamt")
        }
    }

    func statTile(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(14)
        .background(Color(hex: "#F4A623").opacity(0.1)).cornerRadius(14)
    }

    // ── Hilfsfunktionen ──
    var monthTitle: String {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"; fmt.locale = Locale(identifier: "de_DE")
        return fmt.string(from: displayedMonth)
    }

    func changeMonth(_ delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }

        let weekday = (cal.component(.weekday, from: first) + 5) % 7  // Mo=0
        var result: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            result.append(cal.date(byAdding: .day, value: day - 1, to: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }
}
