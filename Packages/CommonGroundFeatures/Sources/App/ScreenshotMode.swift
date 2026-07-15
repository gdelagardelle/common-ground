import Foundation

enum ScreenshotMode {
    private static let defaultsKey = "debug.screenshotMode"

    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-ScreenshotTab=") }
            || UserDefaults.standard.bool(forKey: defaultsKey)
        #else
        false
        #endif
    }

    #if DEBUG
    static func enable() {
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }
    #endif
}
