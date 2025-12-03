import Foundation
import Network
import SystemConfiguration

/// Network monitoring using NWPathMonitor for iOS
class NetworkMonitor {
    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.ipcamera.networkmonitor")
    private var onNetworkChanged: ((String, String) -> Void)?
    
    /// Start monitoring network changes
    func startMonitoring(onChanged: @escaping (String, String) -> Void) {
        self.onNetworkChanged = onChanged
        
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let networkType = self.getNetworkType(from: path)
            let ipAddress = self.getCurrentIPAddress()
            
            DispatchQueue.main.async {
                self.onNetworkChanged?(networkType, ipAddress)
            }
        }
        
        pathMonitor?.start(queue: monitorQueue)
    }
    
    /// Stop monitoring network changes
    func stopMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }
    
    /// Get current network information
    func getCurrentNetwork() -> (networkType: String, ipAddress: String) {
        let networkType: String
        
        if let monitor = pathMonitor {
            networkType = getNetworkType(from: monitor.currentPath)
        } else {
            // Create temporary monitor to get current state
            let tempMonitor = NWPathMonitor()
            networkType = getNetworkType(from: tempMonitor.currentPath)
        }
        
        let ipAddress = getCurrentIPAddress()
        return (networkType, ipAddress)
    }
    
    /// Determine network type from NWPath
    private func getNetworkType(from path: NWPath) -> String {
        if path.status == .unsatisfied {
            return "none"
        }
        
        if path.usesInterfaceType(.wifi) {
            return "wifi"
        } else if path.usesInterfaceType(.cellular) {
            return "cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "ethernet"
        } else {
            return "unknown"
        }
    }
    
    /// Get current IP address
    private func getCurrentIPAddress() -> String {
        var address = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "pdp_ip0" {
                    // Convert interface address to a human readable string
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                               socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname,
                               socklen_t(hostname.count),
                               nil,
                               socklen_t(0),
                               NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
}
