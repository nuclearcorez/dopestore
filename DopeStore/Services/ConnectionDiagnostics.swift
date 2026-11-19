import Foundation
import Combine
import Network
import Darwin

@MainActor
final class ConnectivityMonitor: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var interfaceDescription = "Checking network…"
    @Published private(set) var utunInterfaces: [String] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.dopestore.network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let description: String
            if path.usesInterfaceType(.wifi) {
                description = "Wi-Fi"
            } else if path.usesInterfaceType(.cellular) {
                description = "Cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                description = "Ethernet"
            } else {
                description = path.status == .satisfied ? "Other network" : "No network route"
            }
            let connected = path.status == .satisfied
            let interfaces = Self.activeTunnelInterfaces()
            DispatchQueue.main.async {
                self?.isConnected = connected
                self?.interfaceDescription = description
                self?.utunInterfaces = interfaces
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }

    nonisolated private static func activeTunnelInterfaces() -> [String] {
        var first: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&first) == 0, let start = first else { return [] }
        defer { freeifaddrs(start) }
        var result = Set<String>()
        var cursor: UnsafeMutablePointer<ifaddrs>? = start
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            if name.hasPrefix("utun") { result.insert(name) }
            cursor = current.pointee.ifa_next
        }
        return result.sorted()
    }
}

final class TCPReachabilityProbe {
    static func check(host: String, port: UInt16, timeout: TimeInterval = 3.0) async -> Bool {
        await withCheckedContinuation { continuation in
            let context = ProbeContext(continuation: continuation)
            let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
            context.connection = connection
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    context.finish(true)
                case .failed, .cancelled:
                    context.finish(false)
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                context.finish(false)
            }
        }
    }
}

private final class ProbeContext: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Bool, Never>?
    var connection: NWConnection?

    init(continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func finish(_ result: Bool) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        guard let pending else { return }
        connection?.cancel()
        pending.resume(returning: result)
    }
}
