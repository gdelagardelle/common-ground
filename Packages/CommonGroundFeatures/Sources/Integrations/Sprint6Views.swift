import SwiftUI
import Charts
import SwiftData
import CommonGroundCore
import CommonGroundDesign

public struct GrowthChartView: View {
    let child: Child
    @State private var selectedMetric: GrowthMetric = .height

    public init(child: Child) {
        self.child = child
    }

    private var measurements: [GrowthMeasurement] {
        child.growthMeasurements.sorted { $0.date < $1.date }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CGSpacing.md) {
            Picker("Metric", selection: $selectedMetric) {
                ForEach(GrowthMetric.allCases, id: \.self) { metric in
                    Text(metric.title).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            if chartPoints.isEmpty {
                ContentUnavailableView(
                    "No Growth Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Import from Apple Health or add measurements manually.")
                )
                .frame(height: 220)
            } else {
                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.title, point.value)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.title, point.value)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartYAxisLabel(selectedMetric.axisLabel)
                .frame(height: 220)

                if let latest = measurements.last {
                    latestSummary(latest)
                }
            }
        }
        .padding(.vertical, CGSpacing.xs)
    }

    private var chartPoints: [GrowthChartPoint] {
        measurements.compactMap { measurement in
            switch selectedMetric {
            case .height:
                guard let heightCm = measurement.heightCm else { return nil }
                return GrowthChartPoint(date: measurement.date, value: heightCm)
            case .weight:
                guard let weightKg = measurement.weightKg else { return nil }
                return GrowthChartPoint(date: measurement.date, value: weightKg)
            }
        }
    }

    @ViewBuilder
    private func latestSummary(_ measurement: GrowthMeasurement) -> some View {
        HStack(spacing: CGSpacing.lg) {
            if let height = measurement.heightDisplay {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Height")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(height)
                        .font(.subheadline.weight(.medium))
                }
            }
            if let weight = measurement.weightDisplay {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(weight)
                        .font(.subheadline.weight(.medium))
                }
            }
            Spacer()
            Text(measurement.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct GrowthChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

private enum GrowthMetric: CaseIterable {
    case height
    case weight

    var title: String {
        switch self {
        case .height: "Height"
        case .weight: "Weight"
        }
    }

    var axisLabel: String {
        switch self {
        case .height: "cm"
        case .weight: "kg"
        }
    }
}

public struct HealthImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Child.firstName) private var children: [Child]

    @State private var selectedChildId: UUID?
    @State private var yearsBack = 5
    @State private var isImporting = false
    @State private var result: HealthImportResult?
    @State private var accessDenied = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Import height and weight measurements from Apple Health to track growth over time. Data stays on your device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !HealthKitService.isAvailable {
                    Section {
                        Label("Apple Health is not available on this device.", systemImage: "heart.slash")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Import Settings") {
                        if !children.isEmpty {
                            Picker("Child", selection: $selectedChildId) {
                                ForEach(children, id: \.id) { child in
                                    Text(child.firstName).tag(Optional(child.id))
                                }
                            }
                            .onAppear {
                                if selectedChildId == nil {
                                    selectedChildId = children.first?.id
                                }
                            }
                        }
                        Stepper("Past \(yearsBack) years", value: $yearsBack, in: 1...10)
                    }

                    Section {
                        Button {
                            importHealthData()
                        } label: {
                            HStack {
                                Spacer()
                                if isImporting {
                                    ProgressView()
                                } else {
                                    Label("Import from Health", systemImage: "heart.text.square")
                                }
                                Spacer()
                            }
                        }
                        .disabled(isImporting || children.isEmpty)
                    }

                    if let result {
                        Section("Results") {
                            LabeledContent("Imported", value: "\(result.imported)")
                            LabeledContent("Skipped", value: "\(result.skipped)")
                        }
                    }
                }

                if accessDenied {
                    Section {
                        Text("Health access was denied. Enable it in Settings → Health → Data Access → Common Ground.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func importHealthData() {
        guard let child = children.first(where: { $0.id == selectedChildId }) ?? children.first else { return }

        isImporting = true
        errorMessage = nil
        result = nil
        accessDenied = false

        Task {
            let granted = await HealthKitService.requestAccess()
            guard granted, HealthKitService.authorizationStatus() != .notDetermined else {
                accessDenied = true
                isImporting = false
                return
            }

            do {
                result = try await HealthKitService.importGrowthData(
                    context: modelContext,
                    child: child,
                    yearsBack: yearsBack
                )
            } catch {
                errorMessage = "Import failed. Please try again."
            }
            isImporting = false
        }
    }
}

public struct JoinFamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var memberName = ""
    @State private var familyCode = ""
    @State private var email = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Enter the family code your co-parent shared with you to join their Common Ground family.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Your Info") {
                    TextField("Your name", text: $memberName)
                        .textContentType(.name)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }

                Section("Family Code") {
                    TextField("8-character code", text: $familyCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .monospaced()
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        joinFamily()
                    } label: {
                        HStack {
                            Spacer()
                            if isJoining {
                                ProgressView()
                            } else {
                                Text("Join Family")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canJoin || isJoining)
                }
            }
            .navigationTitle("Join Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var canJoin: Bool {
        !memberName.trimmingCharacters(in: .whitespaces).isEmpty
        && FamilyJoinService.normalizedCode(familyCode).count >= 6
    }

    private func joinFamily() {
        isJoining = true
        errorMessage = nil

        do {
            let (family, member) = try FamilyJoinService.joinFamily(
                context: modelContext,
                code: familyCode,
                memberName: memberName,
                email: email
            )
            appState.currentMemberId = member.id
            appState.currentMemberName = member.displayName
            appState.selectedChildId = family.children.first?.id
            appState.isOnboardingComplete = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isJoining = false
        }
    }
}
