import Foundation

#if !os(macOS)
import UIKit
#endif

/// Wraps `UIApplication.beginBackgroundTask` so a long-running export can
/// survive the user switching apps. On macOS it's a no-op — Mac apps keep
/// running in the background freely.
///
/// iOS gives ~30 seconds of background time for the explicit task before it
/// invokes the expiration handler. If the work finishes before then, we call
/// `end()` to release the assertion immediately. If it doesn't, the
/// expiration handler ends the assertion (after which the OS may suspend the
/// process), and the caller learns via the `onExpire` callback that the work
/// won't complete and should surface a user-facing error.
///
/// Usage:
///   let guardian = BackgroundTaskGuard(name: "Export PNG") { /* expired */ }
///   defer { guardian.end() }
///   // … long work …
@MainActor
final class BackgroundTaskGuard {
    private let onExpire: () -> Void
    #if !os(macOS)
    private var taskID: UIBackgroundTaskIdentifier = .invalid
    #endif

    init(name: String, onExpire: @escaping () -> Void = {}) {
        self.onExpire = onExpire
        begin(name: name)
    }

    private func begin(name: String) {
        #if !os(macOS)
        taskID = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            // The OS is about to suspend us — release the assertion before it
            // does, and tell the caller the work didn't get to finish.
            self?.onExpire()
            self?.end()
        }
        #endif
    }

    func end() {
        #if !os(macOS)
        guard taskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskID)
        taskID = .invalid
        #endif
    }

    deinit {
        // Last-resort cleanup — caller should normally call end() explicitly
        // but the deinit guarantees we don't leak the assertion.
        #if !os(macOS)
        if taskID != .invalid {
            let id = taskID
            Task { @MainActor in
                UIApplication.shared.endBackgroundTask(id)
            }
        }
        #endif
    }
}
