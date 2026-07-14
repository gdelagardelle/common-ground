import Foundation
import SwiftData

@Model
public final class GrowthMeasurement {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var heightCm: Double?
    public var weightKg: Double?
    public var source: String
    public var healthKitSampleId: String?
    public var createdAt: Date

    public var child: Child?

    public init(
        date: Date,
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        source: String = "manual",
        healthKitSampleId: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.source = source
        self.healthKitSampleId = healthKitSampleId
        self.createdAt = Date()
    }

    public var heightDisplay: String? {
        guard let heightCm else { return nil }
        let inches = heightCm / 2.54
        let feet = Int(inches / 12)
        let remainder = Int(inches.truncatingRemainder(dividingBy: 12))
        return "\(feet)′\(remainder)″ (\(String(format: "%.1f", heightCm)) cm)"
    }

    public var weightDisplay: String? {
        guard let weightKg else { return nil }
        let pounds = weightKg * 2.20462
        return "\(String(format: "%.1f", pounds)) lb (\(String(format: "%.1f", weightKg)) kg)"
    }
}
