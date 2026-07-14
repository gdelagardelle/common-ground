import Foundation
import HealthKit
import SwiftData

public struct HealthImportResult: Sendable {
    public let imported: Int
    public let skipped: Int

    public init(imported: Int, skipped: Int) {
        self.imported = imported
        self.skipped = skipped
    }
}

@MainActor
public enum HealthKitService {
    private static let store = HKHealthStore()

    public static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public static var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        return types
    }

    public static func authorizationStatus() -> HKAuthorizationStatus {
        guard let height = HKQuantityType.quantityType(forIdentifier: .height) else {
            return .notDetermined
        }
        return store.authorizationStatus(for: height)
    }

    public static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return authorizationStatus() != .notDetermined
        } catch {
            return false
        }
    }

    public static func importGrowthData(
        context: ModelContext,
        child: Child,
        yearsBack: Int = 5
    ) async throws -> HealthImportResult {
        guard isAvailable else { return HealthImportResult(imported: 0, skipped: 0) }

        let start = Calendar.current.date(byAdding: .year, value: -yearsBack, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        let existingIDs = Set(
            child.growthMeasurements.compactMap(\.healthKitSampleId)
        )

        var imported = 0
        var skipped = 0

        let heightSamples = try await fetchSamples(
            identifier: .height,
            unit: .meterUnit(with: .centi),
            predicate: predicate
        )
        let weightSamples = try await fetchSamples(
            identifier: .bodyMass,
            unit: .gramUnit(with: .kilo),
            predicate: predicate
        )

        let grouped = groupSamplesByDay(height: heightSamples, weight: weightSamples)

        for (day, values) in grouped.sorted(by: { $0.key < $1.key }) {
            let sampleId = values.sampleId
            if let sampleId, existingIDs.contains(sampleId) {
                skipped += 1
                continue
            }

            let measurement = GrowthMeasurement(
                date: day,
                heightCm: values.heightCm,
                weightKg: values.weightKg,
                source: "healthkit",
                healthKitSampleId: sampleId
            )
            measurement.child = child
            child.growthMeasurements.append(measurement)
            context.insert(measurement)
            imported += 1
        }

        if imported > 0 {
            try context.save()
        }

        return HealthImportResult(imported: imported, skipped: skipped)
    }

    private struct DayValues {
        var heightCm: Double?
        var weightKg: Double?
        var sampleId: String?
    }

    private static func groupSamplesByDay(
        height: [(Date, Double, String)],
        weight: [(Date, Double, String)]
    ) -> [Date: DayValues] {
        let calendar = Calendar.current
        var grouped: [Date: DayValues] = [:]

        for (date, value, id) in height {
            let day = calendar.startOfDay(for: date)
            var entry = grouped[day] ?? DayValues()
            entry.heightCm = value
            entry.sampleId = entry.sampleId ?? id
            grouped[day] = entry
        }

        for (date, value, id) in weight {
            let day = calendar.startOfDay(for: date)
            var entry = grouped[day] ?? DayValues()
            entry.weightKg = value
            entry.sampleId = entry.sampleId ?? id
            grouped[day] = entry
        }

        return grouped
    }

    private static func fetchSamples(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> [(Date, Double, String)] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
                    (
                        sample.startDate,
                        sample.quantity.doubleValue(for: unit),
                        sample.uuid.uuidString
                    )
                }
                continuation.resume(returning: mapped)
            }
            store.execute(query)
        }
    }
}
