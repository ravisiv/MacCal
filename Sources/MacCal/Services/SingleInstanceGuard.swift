import AppKit
import Foundation

@MainActor
enum SingleInstanceGuard {
    private static var socketDescriptor: Int32 = -1

    static func acquire() -> Bool {
        guard hasNoMatchingRunningApplication() else { return false }
        guard socketDescriptor == -1 else { return true }

        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor != -1 else { return true }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(38431).bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                bind(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if bindResult == 0, listen(descriptor, 1) == 0 {
            socketDescriptor = descriptor
            return true
        }

        close(descriptor)
        return false
    }

    private static func hasNoMatchingRunningApplication() -> Bool {
        guard let executableURL = Bundle.main.executableURL?.standardizedFileURL else {
            return true
        }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        return !NSWorkspace.shared.runningApplications.contains { app in
            app.processIdentifier != currentPID
                && app.executableURL?.standardizedFileURL == executableURL
                && !app.isTerminated
        }
    }
}
