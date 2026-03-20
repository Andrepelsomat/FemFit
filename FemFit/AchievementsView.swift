// AchievementsView.swift
// FemFit – Gamification & Achievements
import SwiftUI
import SwiftData

struct AchievementDef: Identifiable {
    let id: String
    let title: String
    let desc: String
    let icon: String
    let color: Color
    let check: ([WorkoutSet], [BodyMeasurement], Int) -> Bool
}

struct AchievementsView: View {
    @Query private var allSets: [WorkoutSet]
    @Query private var measurements: [BodyMeasurement]
    @Query private var unlocked: [Achievement]

    var streak: Int  // wird von außen übergeben

    let achievements: [AchievementDef] = [
        .init(id: "first_set",    title: "Erster Satz!",       desc: "Du hast deinen ersten Satz geloggt",      icon: "figure.strengthtraining.traditional", color: Color(hex: "#1D9E75"),
              check: { sets, _, _ in !sets.isEmpty }),
        .init(id: "10_workouts",  title: "10 Workouts",         desc: "10 Trainingseinheiten absolviert",        icon: "dumbbell.fill",   color: Color(hex: "#F4A623"),
              check: { sets, _, _ in Set(sets.map { Calendar.current.startOfDay(for: $0.date) }).count >= 10 }),
        .init(id: "30_workouts",  title: "30 Workouts",         desc: "30 Trainingseinheiten – du bist dabei!",  icon: "trophy.fill",     color: Color(hex: "#F4A623"),
              check: { sets, _, _ in Set(sets.map { Calendar.current.startOfDay(for: $0.date) }).count >= 30 }),
        .init(id: "streak_7",     title: "7 Tage Streak",       desc: "7 Tage in Folge trainiert",               icon: "flame.fill",      color: Color(hex: "#E84393"),
              check: { _, _, streak in streak >= 7 }),
        .init(id: "streak_30",    title: "30 Tage Streak",      desc: "30 Tage in Folge – unglaublich!",         icon: "flame.fill",      color: Color(hex: "#E84393"),
              check: { _, _, streak in streak >= 30 }),
        .init(id: "period_train", title: "Periode-Kriegerin",   desc: "Während der Periode trainiert",           icon: "moon.fill",       color: Color(hex: "#7B68EE"),
              check: { sets, _, _ in sets.contains { $0.isDuringPeriod } }),
        .init(id: "first_measure",title: "Selbstvermessung",    desc: "Erste Körpermessung eingetragen",         icon: "scalemass.fill",  color: Color(hex: "#4A90D9"),
              check: { _, meas, _ in !meas.isEmpty }),
        .init(id: "100_sets",     title: "100 Sätze",           desc: "100 Sätze absolviert – Respect!",         icon: "star.fill",       color: Color(hex: "#F4A623"),
              check: { sets, _, _ in sets.count >= 100 }),
        .init(id: "night_owl",    title: "Nachteule",           desc: "Nach 21 Uhr trainiert",                   icon: "moon.stars.fill", color: Color(hex: "#7B68EE"),
              check: { sets, _, _ in sets.contains { Calendar.current.component(.hour, from: $0.date) >= 21 } }),
        .init(id: "early_bird",   title: "Frühaufsteher",       desc: "Vor 7 Uhr trainiert",                     icon: "sunrise.fill",    color: Color(hex: "#F4A623"),
              check: { sets, _, _ in sets.contains { Calendar.current.component(.hour, from: $0.date) < 7 } }),
    ]

    var unlockedIDs: Set<String> { Set(unlocked.map { $0.id }) }

    var unlockedAchievements: [AchievementDef] { achievements.filter { unlockedIDs.contains($0.id) } }
    var lockedAchievements:   [AchievementDef] { achievements.filter { !unlockedIDs.contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Progress Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(unlockedAchievements.count) / \(achievements.count) freigeschaltet")
                                .font(.headline)
                            ProgressView(value: Double(unlockedAchievements.count), total: Double(achievements.count))
                                .tint(Color(hex: "#F4A623"))
                        }
                        Spacer()
                        Text("🏆")
                            .font(.system(size: 40))
                    }
                    .padding(16)
                    .background(Color(hex: "#F4A623").opacity(0.1))
                    .cornerRadius(16)

                    // Freigeschaltet
                    if !unlockedAchievements.isEmpty {
                        sectionHeader("✅ Freigeschaltet")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(unlockedAchievements) { a in
                                achievementCard(a, unlocked: true)
                            }
                        }
                    }

                    // Gesperrt
                    sectionHeader("🔒 Noch zu erreichen")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(lockedAchievements) { a in
                            achievementCard(a, unlocked: false)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
        .onAppear { checkAndUnlock() }
    }

    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func achievementCard(_ a: AchievementDef, unlocked: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? a.color.opacity(0.2) : Color(uiColor: UIColor.systemGray5))
                    .frame(width: 56, height: 56)
                Image(systemName: a.icon)
                    .font(.system(size: 24))
                    .foregroundColor(unlocked ? a.color : .secondary)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .offset(x: 18, y: 18)
                }
            }
            Text(a.title)
                .font(.caption).fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(unlocked ? .primary : .secondary)
            Text(a.desc)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(unlocked ? a.color.opacity(0.06) : Color(uiColor: UIColor.systemGray6))
        .cornerRadius(14)
    }

    @Environment(\.modelContext) private var context
    func checkAndUnlock() {
        for a in achievements {
            if !unlockedIDs.contains(a.id) && a.check(allSets, measurements, streak) {
                context.insert(Achievement(id: a.id))
            }
        }
    }
}
