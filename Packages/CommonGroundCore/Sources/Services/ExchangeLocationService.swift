import Foundation
import CoreLocation
import SwiftData

public enum ExchangeLocationError: LocalizedError {
    case unavailable
    case denied
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            "Location services are unavailable on this device."
        case .denied:
            "Location access was denied. Enable it in Settings → Common Ground → Location."
        case .timedOut:
            "Couldn't determine your location. Try again outdoors or near a window."
        }
    }
}

@MainActor
public final class ExchangeLocationManager: NSObject, CLLocationManagerDelegate {
    public static let shared = ExchangeLocationManager()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    public private(set) var authorizationStatus: CLAuthorizationStatus

    private override init() {
        authorizationStatus = CLLocationManager.authorizationStatus()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestAuthorizationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    public func requestCurrentLocation() async throws -> CLLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw ExchangeLocationError.unavailable
        }

        requestAuthorizationIfNeeded()
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .denied, .restricted:
            throw ExchangeLocationError.denied
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    public static func shareLocation(
        for event: CalendarEvent,
        memberName: String,
        context: ModelContext
    ) async throws {
        let location = try await shared.requestCurrentLocation()
        event.latitude = location.coordinate.latitude
        event.longitude = location.coordinate.longitude
        event.sharedLocationAt = Date()
        event.sharedLocationMemberName = memberName
        event.updatedAt = Date()
        try context.save()
    }

    public static func reverseGeocode(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        return placemark.name ?? placemark.locality
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            continuation?.resume(returning: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            continuation = nil
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: ExchangeLocationError.timedOut)
            continuation = nil
        }
    }
}

public enum ExchangeLocationPreferences {
    private static let autoShareKey = "exchange.location.autoShare"

    public static var autoShareEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoShareKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoShareKey) }
    }
}

@MainActor
public enum ExchangeLocationService {
    public static func upcomingExchange(from events: [CalendarEvent], childId: UUID? = nil) -> CalendarEvent? {
        events
            .filter { event in
                event.category == .exchange
                && event.startDate >= Date()
                && (childId == nil || event.child?.id == childId)
            }
            .sorted(by: { $0.startDate < $1.startDate })
            .first
    }

    public static func isWithinShareWindow(_ event: CalendarEvent, hours: Int = 4) -> Bool {
        let hoursUntil = Calendar.current.dateComponents([.hour], from: Date(), to: event.startDate).hour ?? 99
        return hoursUntil <= hours && hoursUntil >= -1
    }
}
