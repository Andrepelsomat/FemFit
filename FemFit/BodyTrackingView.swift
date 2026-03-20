// BodyTrackingView.swift
// FemFit – Körpermaße tracken
import SwiftUI
import SwiftData
import Charts

struct BodyTrackingView: View {
    var cycleManager = CycleManager.shared
    @Environment(\.modelContext) private var context
    @Query(sort: \BodyMeasurement.date) private var measurements: [BodyMeasurement]

    @State private var showAdd     = false
    @State private var weightInput = ""
    @State private var fatInput    = ""
    @State private var waistInput  = ""
    @State private var hipsInput   = ""

    var accentColor: Color { cycleManager.isInPeriod ? Color(hex: "#E84393") : Color(hex: "#1D9E75") }
    var latest: BodyMeasurement? { measurements.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Aktuelle Werte
                    if let m = latest {
                        currentValues(m)
                    } else {
                        emptyState
                    }

                    // Gewicht-Chart
                    if measurements.count > 1 {
                        weightChart
                    }

                    // Verlauf
                    if !measurements.isEmpty {
                        historyList
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Körpermaße")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { addSheet }
        }
    }

    // ── Aktuelle Werte ──
    func currentValues(_ m: BodyMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aktuell")
                    .font(.headline)
                Spacer()
                Text(m.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if m.isDuringPeriod {
                    Text("🌸").font(.caption)
                }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let w = m.weight   { metricTile("Gewicht",    value: "\(String(format: "%.1f", w)) kg",  icon: "scalemass.fill",     color: accentColor) }
                if let f = m.bodyFat  { metricTile("Körperfett", value: "\(String(format: "%.1f", f)) %",   icon: "percent",            color: Color(hex: "#F4A623")) }
                if let wa = m.waist   { metricTile("Taille",     value: "\(String(format: "%.0f", wa)) cm", icon: "figure.stand",       color: Color(hex: "#7B68EE")) }
                if let h = m.hips     { metricTile("Hüfte",      value: "\(String(format: "%.0f", h)) cm",  icon: "figure.walk",        color: Color(hex: "#E84393")) }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    func metricTile(_ label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.subheadline).fontWeight(.bold)
                Text(label).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // ── Gewicht Chart ──
    var weightChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gewichtsverlauf")
                .font(.headline)

            let data = measurements.filter { $0.weight != nil }
            Chart {
                ForEach(data) { m in
                    LineMark(x: .value("Datum", m.date), y: .value("kg", m.weight!))
                        .foregroundStyle(m.isDuringPeriod ? Color(hex: "#E84393") : accentColor)
                        .symbol(Circle())
                        .symbolSize(30)
                    AreaMark(x: .value("Datum", m.date), y: .value("kg", m.weight!))
                        .foregroundStyle(accentColor.opacity(0.08))
                }
            }
            .frame(height: 160)
            .chartYScale(domain: .automatic(includesZero: false))

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(accentColor).frame(width: 8, height: 8)
                    Text("Normal").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#E84393")).frame(width: 8, height: 8)
                    Text("Periode").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // ── Verlauf ──
    var historyList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verlauf")
                .font(.headline)
            ForEach(measurements.reversed().prefix(10)) { m in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.date, style: .date)
                            .font(.subheadline).fontWeight(.medium)
                        HStack(spacing: 8) {
                            if let w = m.weight  { Text("\(String(format: "%.1f", w)) kg").font(.caption).foregroundColor(accentColor) }
                            if let f = m.bodyFat { Text("\(String(format: "%.1f", f))% Fett").font(.caption).foregroundColor(.secondary) }
                        }
                    }
                    Spacer()
                    if m.isDuringPeriod { Text("🌸").font(.caption) }
                }
                .padding(10)
                .background(Color(uiColor: UIColor.systemGray6))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // ── Leer ──
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "scalemass").font(.system(size: 50)).foregroundColor(.secondary)
            Text("Noch keine Messungen").font(.headline)
            Text("Trage deine erste Messung ein um deinen Fortschritt zu verfolgen.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding(.top, 30)
    }

    // ── Eingabe Sheet ──
    var addSheet: some View {
        NavigationStack {
            Form {
                Section("Gewicht & Körperfett") {
                    HStack {
                        Text("Gewicht (kg)"); Spacer()
                        TextField("z.B. 65.5", text: $weightInput).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    HStack {
                        Text("Körperfett (%)"); Spacer()
                        TextField("z.B. 22.0", text: $fatInput).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                    }
                }
                Section("Maße (cm)") {
                    HStack {
                        Text("Taille"); Spacer()
                        TextField("z.B. 72", text: $waistInput).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    HStack {
                        Text("Hüfte"); Spacer()
                        TextField("z.B. 96", text: $hipsInput).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 100)
                    }
                }
                Section {
                    if cycleManager.isInPeriod {
                        Label("Perioden-Tag wird markiert", systemImage: "moon.fill")
                            .foregroundColor(Color(hex: "#E84393")).font(.caption)
                    }
                }
            }
            .navigationTitle("Neue Messung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("Abbrechen") { showAdd = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") { save(); showAdd = false }
                        .fontWeight(.semibold)
                        .disabled(weightInput.isEmpty && fatInput.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    func save() {
        let m = BodyMeasurement(
            weight:      Double(weightInput.replacingOccurrences(of: ",", with: ".")),
            bodyFat:     Double(fatInput.replacingOccurrences(of: ",", with: ".")),
            waist:       Double(waistInput.replacingOccurrences(of: ",", with: ".")),
            hips:        Double(hipsInput.replacingOccurrences(of: ",", with: ".")),
            isDuringPeriod: cycleManager.isInPeriod
        )
        context.insert(m)
        weightInput = ""; fatInput = ""; waistInput = ""; hipsInput = ""
    }
}
