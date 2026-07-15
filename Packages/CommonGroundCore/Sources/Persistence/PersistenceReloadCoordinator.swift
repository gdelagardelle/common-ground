import Foundation
import Observation

@Observable
@MainActor
public final class PersistenceReloadCoordinator {
    public static let shared = PersistenceReloadCoordinator()

    public private(set) var generation = 0

    private init() {}

    public func requestReload() {
        generation += 1
    }
}
