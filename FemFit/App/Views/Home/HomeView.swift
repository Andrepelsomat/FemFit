// HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {

    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context

    @Query(sort: \WorkoutProgram.createdAt) private var programs: [WorkoutProgram]

    @State private var showAddProgram = false
    @State private var newProgramName = ""
    @State private var showAddDay     = false
    @State private var newDayName     = ""
    @State private var selectedProgram: WorkoutProgram?

    var activeProgram: WorkoutProgram? { programs.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    VStack(spacing: 20) {
                        statsRow
                        if let program = activeProgram {
                            todaySection(program)
                            quickAccessRow
                        } else {
                            emptyState
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#FDF6F8"))
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddProgram = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Neues Programm", isPresented: $showAddProgram) {
                TextField("Name (z.B. Push Pull Legs)", text: $newProgramName)
                Button("Erstellen") { createProgram() }
                Button("Abbrechen", role: .cancel) { newProgramName = "" }
            }
            .alert("Neuer Trainingstag", isPresented: $showAddDay) {
                TextField("Name (z.B. Push, Pull, Legs)", text: $newDayName)
                Button("Hinzufügen") { addDay() }
                Button("Abbrechen", role: .cancel) { newDayName = "" }
            }
        }
    }

    // MARK: – Header
    var headerSection: some View {
        ZStack {
            Color(hex: "#2D1B2E")
            Circle()
                .fill(Color(hex: "#4A1B4C").opacity(0.4))
                .frame(width: 160)
                .offset(x: 120, y: -60)
            Circle()
                .fill(Color(hex: "#3A1040").opacity(0.3))
                .frame(width: 100)
                .offset(x: -120, y: 60)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                            .font(.system(size: 11))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: "#C9A0D4"))
                        Text("Guten Morgen,")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text(greetingName)
                            .font(.system(size: 26).italic())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { cycleManager.isInPeriod },
                        set: { cycleManager.isInPeriod = $0 }
                    ))
                    .tint(Color(hex: "#E84393"))
                    .labelsHidden()
                    .padding(.top, 4)
                }
                .padding(.top, 60)

                HStack(spacing: 16) {
                    cycleRing.frame(width: 90, height: 90)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aktuell")
                            .font(.system(size: 11))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: "#C9A0D4"))
                        Text(cycleManager.isInPeriod ? "Periode" : cyclePhaseName)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Text(cycleManager.cyclePhaseText)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#E879A0"))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 4) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i == 0 ? Color(hex: "#E879A0") : Color(hex: "#4A1B4C"))
                                    .frame(width: 20, height: 4)
                            }
                        }
                        .padding(.top, 2)
                        Text("Tag \(cycleManager.currentCycleDay) von \(cycleManager.cycleLength)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#C9A0D4"))
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
    }

    var cycleRing: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#4A1B4C"), lineWidth: 7)
            Circle()
                .trim(from: 0, to: cycleProgress)
                .stroke(Color(hex: "#E879A0"),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color(hex: "#3A1040"))
                .padding(12)
            VStack(spacing: 0) {
                Text("Tag")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                Text("\(cycleManager.currentCycleDay)")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#E879A0"))
            }
        }
    }

    var cycleProgress: Double {
        Double(cycleManager.currentCycleDay) / Double(cycleManager.cycleLength)
    }

    var cyclePhaseName: String {
        if cycleManager.daysUntilNextPeriod <= 3 { return "PMS-Phase" }
        if cycleManager.currentCycleDay <= 13    { return "Follikelphase" }
        return "Lutealphase"
    }

    var greetingName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "Nicole"
    }

    // MARK: – Stats
    var statsRow: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(activeProgram?.completedWorkouts ?? 0)",
                     label: "Workouts", sublabel: "gesamt")
            StatCard(value: "\(activeProgram?.days.count ?? 0)",
                     label: "Trainingstage", sublabel: "im Programm")
            StatCard(value: "\(cycleManager.daysUntilNextPeriod)",
                     label: "Bis Periode", sublabel: "Tage")
        }
    }

    // MARK: – Programm
    func todaySection(_ program: WorkoutProgram) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mein Programm")
                    .font(.system(size: 11))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: "#A06080"))
                Spacer()
                Button {
                    selectedProgram = program
                    showAddDay = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundColor(Color(hex: "#E879A0"))
                }
            }
            ForEach(program.sortedDays) { day in
                NavigationLink(destination: WorkoutDayView(day: day)) {
                    WorkoutDayCard(day: day)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Schnellzugriff
    var quickAccessRow: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: ProgressChartView()) {
                QuickAccessCard(icon: "chart.bar.fill", title: "Fortschritt", subtitle: "ansehen")
            }
            .buttonStyle(.plain)
            NavigationLink(destination: CycleTrackerView()) {
                QuickAccessCard(icon: "arrow.clockwise.circle.fill", title: "Zyklus", subtitle: "verwalten")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: – Leerer Zustand
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#C9A0D4"))
            Text("Noch kein Programm")
                .font(.title3)
                .foregroundColor(Color(hex: "#2D1B2E"))
            Text("Erstelle dein erstes Trainingsprogramm und fang an zu tracken.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#A06080"))
                .multilineTextAlignment(.center)
            Button { showAddProgram = true } label: {
                Label("Programm erstellen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(hex: "#E84393"))
                    .cornerRadius(14)
            }
        }
        .padding(.top, 40)
    }

    // MARK: – Aktionen
    func createProgram() {
        guard !newProgramName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        context.insert(WorkoutProgram(name: newProgramName))
        newProgramName = ""
    }

    func addDay() {
        guard let program = selectedProgram,
              !newDayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let day = WorkoutDay(name: newDayName, order: program.days.count)
        day.program = program
        context.insert(day)
        newDayName = ""
        selectedProgram = nil
    }
}

// MARK: – Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let sublabel: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(Color(hex: "#2D1B2E"))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: "#A06080"))
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#C9A0B8"))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#F0D4E0"), lineWidth: 0.5))
    }
}

// MARK: – Quick Access Card
struct QuickAccessCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#FBEAF0"))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#E84393"))
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2D1B2E"))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#A06080"))
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#F0D4E0"), lineWidth: 0.5))
    }
}

// MARK: – WorkoutDayCard
struct WorkoutDayCard: View {
    var cycleManager = CycleManager.shared
    let day: WorkoutDay

    var accentColor: Color {
        cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75")
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: day.completionPercent)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(day.completionPercent * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(day.name)
                    .font(.headline)
                    .foregroundColor(Color(hex: "#2D1B2E"))
                Text("\(day.exercises.count) Übungen · \(day.completedSessions) Sessions")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#A06080"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(hex: "#C9A0B8"))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "#F0D4E0"), lineWidth: 0.5))
    }
}
