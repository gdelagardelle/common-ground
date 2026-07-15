import Foundation
import Observation

@Observable
@MainActor
public final class DeepLinkCoordinator {
    public var pendingInviteCode: String?
    public var shouldPresentJoinFamily = false

    public init() {}

    public func handle(_ url: URL) {
        guard let code = InviteService.inviteCode(from: url) else { return }
        pendingInviteCode = code
        shouldPresentJoinFamily = true
    }

    public func consumeInviteCode() -> String? {
        defer { pendingInviteCode = nil }
        return pendingInviteCode
    }
}
