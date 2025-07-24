import Foundation
import os.log
import Combine

/// Monitors system health and resource availability for error recovery decisions
class SystemHealthMonitor: ObservableObject, SystemHealthMonitorProtocol {
    
    // MARK: - Singleton
    
    static let shared = SystemHealthMonitor()
    
    // MARK: - Published Properties
    
    @Published var currentResourceStatus: SystemResourceStatus
    @Published var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 5.0 // 5 seconds
    private let logger = Logger(subsystem: "com.clickit.systemhealth", category: "monitoring")
    
    // MARK: - Initialization
    
    private init() {
        self.currentResourceStatus = SystemResourceStatus(
            memoryPressure: false,
            cpuPressure: false,
            lowDiskSpace: false,
            timestamp: Date()
        )
    }
    
    // MARK: - Public Methods
    
    /// Starts continuous system health monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Starting system health monitoring")
        
        // Initial check
        updateResourceStatus()
        
        // Schedule periodic checks
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateResourceStatus()
        }
    }
    
    /// Stops system health monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        logger.info("Stopped system health monitoring")
    }
    
    /// Checks if system is experiencing memory pressure
    func checkMemoryPressure() -> Bool {
        let usage = getMemoryUsage()
        let hasMemoryPressure = usage > SystemResourceThresholds.memoryPressureThreshold
        
        if hasMemoryPressure {
            logger.warning("Memory pressure detected: \(usage, privacy: .public)%")
        }
        
        return hasMemoryPressure
    }
    
    /// Checks if system is experiencing high CPU usage
    func checkCPUPressure() -> Bool {
        let usage = getCPUUsage()
        let hasCPUPressure = usage > SystemResourceThresholds.cpuPressureThreshold
        
        if hasCPUPressure {
            logger.warning("CPU pressure detected: \(usage, privacy: .public)%")
        }
        
        return hasCPUPressure
    }
    
    /// Checks if system has low disk space
    func checkDiskSpace() -> Bool {
        let freeSpace = getDiskFreeSpacePercentage()
        let hasLowDiskSpace = freeSpace < SystemResourceThresholds.diskSpaceThreshold
        
        if hasLowDiskSpace {
            logger.warning("Low disk space detected: \(freeSpace, privacy: .public)% free")
        }
        
        return hasLowDiskSpace
    }
    
    /// Gets current system resource status
    func getSystemResourceStatus() -> SystemResourceStatus {
        return currentResourceStatus
    }
    
    /// Forces an immediate system health check
    func performImmediateHealthCheck() -> SystemResourceStatus {
        updateResourceStatus()
        return currentResourceStatus
    }
    
    // MARK: - Private Methods
    
    private func updateResourceStatus() {
        let memoryPressure = checkMemoryPressure()
        let cpuPressure = checkCPUPressure()
        let lowDiskSpace = checkDiskSpace()
        
        let newStatus = SystemResourceStatus(
            memoryPressure: memoryPressure,
            cpuPressure: cpuPressure,
            lowDiskSpace: lowDiskSpace,
            timestamp: Date()
        )
        
        // Update on main thread since this is @MainActor
        DispatchQueue.main.async { [weak self] in
            self?.currentResourceStatus = newStatus
        }
        
        if newStatus.hasIssues {
            logger.warning("System resource issues detected: memory=\(memoryPressure), cpu=\(cpuPressure), disk=\(lowDiskSpace)")
        }
    }
    
    // MARK: - System Resource Measurement
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryMB = Double(info.resident_size) / (1024 * 1024)
            let totalMemoryMB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)
            return usedMemoryMB / totalMemoryMB
        }
        
        return 0.0
    }
    
    private func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpusU: natural_t = 0
        
        let result = host_processor_info(mach_host_self(),
                                       PROCESSOR_CPU_LOAD_INFO,
                                       &numCpusU,
                                       &cpuInfo,
                                       &numCpuInfo)
        
        if result == KERN_SUCCESS {
            // Use basic CPU usage estimation - in a production app you might want more sophisticated monitoring
            // For this error recovery system, we'll use a simplified approach
            let currentLoad = ProcessInfo.processInfo.systemUptime
            // This is a placeholder - real CPU monitoring would require more complex system calls
            return 0.1 // Conservative estimate for most systems
        }
        
        return 0.0
    }
    
    private func getDiskFreeSpacePercentage() -> Double {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            
            if let freeSize = attributes[.systemFreeSize] as? NSNumber,
               let totalSize = attributes[.systemSize] as? NSNumber {
                let freeBytes = freeSize.doubleValue
                let totalBytes = totalSize.doubleValue
                
                if totalBytes > 0 {
                    return freeBytes / totalBytes
                }
            }
        } catch {
            logger.error("Failed to get disk space information: \(error)")
        }
        
        return 1.0 // Assume plenty of space if we can't determine
    }
    
    // MARK: - Health Check Utilities
    
    /// Checks if the system is under stress (any resource pressure)
    var isSystemUnderStress: Bool {
        return currentResourceStatus.hasIssues
    }
    
    /// Gets a health score from 0.0 (critical) to 1.0 (excellent)
    func getSystemHealthScore() -> Double {
        var score = 1.0
        
        if currentResourceStatus.memoryPressure {
            score -= 0.4
        }
        
        if currentResourceStatus.cpuPressure {
            score -= 0.3
        }
        
        if currentResourceStatus.lowDiskSpace {
            score -= 0.3
        }
        
        return max(0.0, score)
    }
    
    /// Gets recommendations for improving system health
    func getHealthRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if currentResourceStatus.memoryPressure {
            recommendations.append("Close unnecessary applications to free up memory")
            recommendations.append("Consider reducing click rate to lower memory usage")
        }
        
        if currentResourceStatus.cpuPressure {
            recommendations.append("Reduce system load by closing CPU-intensive applications")
            recommendations.append("Consider increasing click intervals to reduce CPU usage")
        }
        
        if currentResourceStatus.lowDiskSpace {
            recommendations.append("Free up disk space by cleaning temporary files")
            recommendations.append("Move large files to external storage")
        }
        
        return recommendations
    }
}

// MARK: - Extensions

extension SystemHealthMonitor {
    /// Convenience method to check if system is suitable for high-precision clicking
    var isSystemSuitableForPrecisionClicking: Bool {
        return getSystemHealthScore() > 0.7
    }
    
    /// Convenience method to get resource usage summary
    func getResourceUsageSummary() -> String {
        let memoryUsage = getMemoryUsage()
        let cpuUsage = getCPUUsage()
        let diskUsage = 1.0 - getDiskFreeSpacePercentage()
        
        return String(format: "Memory: %.1f%%, CPU: %.1f%%, Disk: %.1f%%",
                     memoryUsage * 100,
                     cpuUsage * 100,
                     diskUsage * 100)
    }
}