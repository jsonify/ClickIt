//
//  CPSRandomizer.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation

/// Advanced CPS randomization engine with configurable patterns for human-like timing
/// Provides statistical distributions and anti-detection capabilities
final class CPSRandomizer: @unchecked Sendable {
    
    // MARK: - Types
    
    /// Statistical distribution patterns for timing randomization
    enum DistributionPattern: String, CaseIterable, Codable {
        case uniform = "uniform"
        case normal = "normal"
        case exponential = "exponential"
        case triangular = "triangular"
        
        var displayName: String {
            switch self {
            case .uniform:
                return "Uniform"
            case .normal:
                return "Normal (Bell Curve)"
            case .exponential:
                return "Exponential"
            case .triangular:
                return "Triangular"
            }
        }
        
        var description: String {
            switch self {
            case .uniform:
                return "Equal probability across variance range"
            case .normal:
                return "Natural bell curve distribution (most human-like)"
            case .exponential:
                return "Faster clicks with occasional delays"
            case .triangular:
                return "Peak at center with linear falloff"
            }
        }
    }
    
    /// Anti-detection humanness levels
    enum HumannessLevel: String, CaseIterable, Codable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case extreme = "extreme"
        
        var displayName: String {
            switch self {
            case .none:
                return "None (Robotic)"
            case .low:
                return "Low"
            case .medium:
                return "Medium"
            case .high:
                return "High"
            case .extreme:
                return "Extreme (Very Human-like)"
            }
        }
        
        /// Variance multiplier for humanness level
        var varianceMultiplier: Double {
            switch self {
            case .none:
                return 0.0
            case .low:
                return 0.5
            case .medium:
                return 1.0
            case .high:
                return 1.5
            case .extreme:
                return 2.0
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Randomization configuration
    struct Configuration: Codable {
        /// Whether randomization is enabled
        let enabled: Bool
        
        /// Base variance as percentage of base interval (0.0-1.0)
        let variancePercentage: Double
        
        /// Statistical distribution pattern
        let distributionPattern: DistributionPattern
        
        /// Anti-detection humanness level
        let humannessLevel: HumannessLevel
        
        /// Minimum interval clamp (prevents intervals below this value)
        let minimumInterval: TimeInterval
        
        /// Maximum interval clamp (prevents intervals above this value)
        let maximumInterval: TimeInterval
        
        /// Pattern breakup frequency (how often to inject deliberate pattern breaks)
        let patternBreakupFrequency: Double
        
        init(
            enabled: Bool = false,
            variancePercentage: Double = 0.1, // 10% default variance
            distributionPattern: DistributionPattern = .normal,
            humannessLevel: HumannessLevel = .medium,
            minimumInterval: TimeInterval = 0.01, // 10ms minimum
            maximumInterval: TimeInterval = 10.0, // 10s maximum
            patternBreakupFrequency: Double = 0.05 // 5% chance of pattern break
        ) {
            self.enabled = enabled
            self.variancePercentage = max(0.0, min(1.0, variancePercentage))
            self.distributionPattern = distributionPattern
            self.humannessLevel = humannessLevel
            self.minimumInterval = minimumInterval
            self.maximumInterval = maximumInterval
            self.patternBreakupFrequency = max(0.0, min(1.0, patternBreakupFrequency))
        }
    }
    
    // MARK: - Properties
    
    /// Current configuration
    private var configuration: Configuration
    
    /// Random number generator for consistent results
    private var randomGenerator: SystemRandomNumberGenerator
    
    /// Pattern tracking for anti-detection
    private var recentIntervals: [TimeInterval] = []
    private let maxRecentIntervalsHistory = 20
    
    /// Statistics tracking
    private var generatedIntervals: [TimeInterval] = []
    private let maxStatisticsHistory = 1000
    
    // MARK: - Initialization
    
    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.randomGenerator = SystemRandomNumberGenerator()
    }
    
    // MARK: - Public Methods
    
    /// Generate randomized interval based on base interval and configuration
    /// - Parameter baseInterval: Base click interval in seconds
    /// - Returns: Randomized interval in seconds
    func randomizeInterval(_ baseInterval: TimeInterval) -> TimeInterval {
        guard configuration.enabled else {
            return baseInterval
        }
        
        // Calculate effective variance with humanness multiplier
        let effectiveVariance = configuration.variancePercentage * configuration.humannessLevel.varianceMultiplier
        let varianceAmount = baseInterval * effectiveVariance
        
        // Generate random offset based on distribution pattern
        let randomOffset = generateRandomOffset(
            variance: varianceAmount,
            pattern: configuration.distributionPattern
        )
        
        // Apply pattern breakup if needed
        let finalOffset = applyPatternBreakup(
            offset: randomOffset,
            baseInterval: baseInterval,
            variance: varianceAmount
        )
        
        // Calculate final interval
        let randomizedInterval = baseInterval + finalOffset
        
        // Clamp to configured limits
        let clampedInterval = max(
            configuration.minimumInterval,
            min(configuration.maximumInterval, randomizedInterval)
        )
        
        // Track for pattern analysis
        trackInterval(clampedInterval)
        
        return clampedInterval
    }
    
    /// Update randomization configuration
    /// - Parameter newConfiguration: New configuration to apply
    func updateConfiguration(_ newConfiguration: Configuration) {
        self.configuration = newConfiguration
        
        // Reset tracking when configuration changes
        recentIntervals.removeAll()
        generatedIntervals.removeAll()
    }
    
    /// Get current configuration
    /// - Returns: Current randomization configuration
    func getConfiguration() -> Configuration {
        return configuration
    }
    
    /// Get randomization statistics
    /// - Returns: Statistics about generated intervals
    func getStatistics() -> RandomizationStatistics {
        guard !generatedIntervals.isEmpty else {
            return RandomizationStatistics(
                samplesGenerated: 0,
                meanInterval: 0,
                standardDeviation: 0,
                minimumInterval: 0,
                maximumInterval: 0,
                varianceEffectiveness: 0,
                patternUniformity: 0,
                humanlikeScore: 0
            )
        }
        
        let mean = generatedIntervals.reduce(0, +) / Double(generatedIntervals.count)
        let variance = generatedIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(generatedIntervals.count)
        let standardDeviation = sqrt(variance)
        let minimum = generatedIntervals.min() ?? 0
        let maximum = generatedIntervals.max() ?? 0
        
        // Calculate variance effectiveness (how well we're achieving desired variance)
        let varianceEffectiveness = calculateVarianceEffectiveness()
        
        // Calculate pattern uniformity (lower is better for human-like behavior)
        let patternUniformity = calculatePatternUniformity()
        
        // Calculate human-like score (0-100, higher is more human-like)
        let humanlikeScore = calculateHumanlikeScore()
        
        return RandomizationStatistics(
            samplesGenerated: generatedIntervals.count,
            meanInterval: mean,
            standardDeviation: standardDeviation,
            minimumInterval: minimum,
            maximumInterval: maximum,
            varianceEffectiveness: varianceEffectiveness,
            patternUniformity: patternUniformity,
            humanlikeScore: humanlikeScore
        )
    }
    
    /// Reset all statistics and tracking
    func resetStatistics() {
        recentIntervals.removeAll()
        generatedIntervals.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Generate random offset based on distribution pattern
    /// - Parameters:
    ///   - variance: Maximum variance amount
    ///   - pattern: Distribution pattern to use
    /// - Returns: Random offset value
    private func generateRandomOffset(variance: TimeInterval, pattern: DistributionPattern) -> TimeInterval {
        switch pattern {
        case .uniform:
            return generateUniformOffset(variance: variance)
        case .normal:
            return generateNormalOffset(variance: variance)
        case .exponential:
            return generateExponentialOffset(variance: variance)
        case .triangular:
            return generateTriangularOffset(variance: variance)
        }
    }
    
    /// Generate uniform distribution offset
    private func generateUniformOffset(variance: TimeInterval) -> TimeInterval {
        let random = Double.random(in: -1.0...1.0, using: &randomGenerator)
        return random * variance
    }
    
    /// Generate normal distribution offset using Box-Muller transform
    private func generateNormalOffset(variance: TimeInterval) -> TimeInterval {
        // Box-Muller transform for normal distribution
        let u1 = Double.random(in: 0.0...1.0, using: &randomGenerator)
        let u2 = Double.random(in: 0.0...1.0, using: &randomGenerator)
        
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        
        // Scale to variance (using standard deviation = variance/3 for 99.7% within range)
        return z0 * (variance / 3.0)
    }
    
    /// Generate exponential distribution offset
    private func generateExponentialOffset(variance: TimeInterval) -> TimeInterval {
        let u = Double.random(in: 0.0...1.0, using: &randomGenerator)
        let exponential = -log(1.0 - u)
        
        // Scale and center around zero
        let scaled = (exponential / 2.0) - 0.5
        return scaled * variance * 2.0
    }
    
    /// Generate triangular distribution offset
    private func generateTriangularOffset(variance: TimeInterval) -> TimeInterval {
        let u1 = Double.random(in: 0.0...1.0, using: &randomGenerator)
        let u2 = Double.random(in: 0.0...1.0, using: &randomGenerator)
        
        // Sum of two uniform distributions creates triangular distribution
        let triangular = (u1 + u2) / 2.0
        
        // Scale and center around zero
        return (triangular - 0.5) * variance * 2.0
    }
    
    /// Apply pattern breakup for anti-detection
    private func applyPatternBreakup(offset: TimeInterval, baseInterval: TimeInterval, variance: TimeInterval) -> TimeInterval {
        // Check if we should apply pattern breakup
        let breakupRoll = Double.random(in: 0.0...1.0, using: &randomGenerator)
        guard breakupRoll < configuration.patternBreakupFrequency else {
            return offset
        }
        
        // Apply more dramatic variance for pattern breakup
        let breakupVariance = variance * 2.0
        let breakupOffset = generateUniformOffset(variance: breakupVariance)
        
        return breakupOffset
    }
    
    /// Track interval for pattern analysis
    private func trackInterval(_ interval: TimeInterval) {
        // Add to recent intervals for pattern analysis
        recentIntervals.append(interval)
        if recentIntervals.count > maxRecentIntervalsHistory {
            recentIntervals.removeFirst()
        }
        
        // Add to statistics
        generatedIntervals.append(interval)
        if generatedIntervals.count > maxStatisticsHistory {
            generatedIntervals.removeFirst()
        }
    }
    
    /// Calculate variance effectiveness (how well we achieve desired variance)
    private func calculateVarianceEffectiveness() -> Double {
        guard generatedIntervals.count >= 2 else { return 0 }
        
        let mean = generatedIntervals.reduce(0, +) / Double(generatedIntervals.count)
        let variance = generatedIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(generatedIntervals.count)
        let standardDeviation = sqrt(variance)
        
        // Compare to expected variance
        let expectedVariance = mean * configuration.variancePercentage * configuration.humannessLevel.varianceMultiplier
        let effectiveness = min(1.0, standardDeviation / expectedVariance)
        
        return effectiveness
    }
    
    /// Calculate pattern uniformity (lower values indicate less predictable patterns)
    private func calculatePatternUniformity() -> Double {
        guard recentIntervals.count >= 3 else { return 0 }
        
        // Calculate how similar consecutive intervals are
        var similarities: [Double] = []
        for i in 1..<recentIntervals.count {
            let ratio = recentIntervals[i] / recentIntervals[i-1]
            let similarity = abs(1.0 - ratio) // Closer to 1.0 = more similar
            similarities.append(similarity)
        }
        
        let averageSimilarity = similarities.reduce(0, +) / Double(similarities.count)
        return averageSimilarity
    }
    
    /// Calculate human-like score (0-100, higher is more human-like)
    private func calculateHumanlikeScore() -> Double {
        guard configuration.enabled else { return 0 }
        
        let varianceScore = min(100, calculateVarianceEffectiveness() * 100)
        let patternScore = max(0, 100 - (calculatePatternUniformity() * 100))
        let humannessScore = Double(configuration.humannessLevel.varianceMultiplier) * 25
        
        return (varianceScore + patternScore + humannessScore) / 3.0
    }
}

// MARK: - Supporting Types

/// Statistics for randomization analysis
struct RandomizationStatistics {
    /// Number of samples generated
    let samplesGenerated: Int
    
    /// Mean interval value
    let meanInterval: TimeInterval
    
    /// Standard deviation of intervals
    let standardDeviation: TimeInterval
    
    /// Minimum interval generated
    let minimumInterval: TimeInterval
    
    /// Maximum interval generated
    let maximumInterval: TimeInterval
    
    /// How effectively we achieve desired variance (0.0-1.0)
    let varianceEffectiveness: Double
    
    /// Pattern uniformity score (lower is better, 0.0-1.0)
    let patternUniformity: Double
    
    /// Overall human-like score (0-100, higher is more human-like)
    let humanlikeScore: Double
    
    /// Whether randomization is performing well
    var isPerformingWell: Bool {
        return varianceEffectiveness > 0.7 && patternUniformity < 0.3 && humanlikeScore > 60
    }
}

// MARK: - Factory Methods

extension CPSRandomizer {
    
    /// Create randomizer optimized for gaming (medium humanness, normal distribution)
    static func forGaming() -> CPSRandomizer {
        let config = Configuration(
            enabled: true,
            variancePercentage: 0.15,
            distributionPattern: .normal,
            humannessLevel: .medium,
            patternBreakupFrequency: 0.08
        )
        return CPSRandomizer(configuration: config)
    }
    
    /// Create randomizer optimized for accessibility (low variance, gentle patterns)
    static func forAccessibility() -> CPSRandomizer {
        let config = Configuration(
            enabled: true,
            variancePercentage: 0.05,
            distributionPattern: .normal,
            humannessLevel: .low,
            patternBreakupFrequency: 0.02
        )
        return CPSRandomizer(configuration: config)
    }
    
    /// Create randomizer optimized for testing (minimal variance for consistency)
    static func forTesting() -> CPSRandomizer {
        let config = Configuration(
            enabled: true,
            variancePercentage: 0.02,
            distributionPattern: .uniform,
            humannessLevel: .low,
            patternBreakupFrequency: 0.01
        )
        return CPSRandomizer(configuration: config)
    }
    
    /// Create randomizer optimized for stealth (maximum humanness)
    static func forStealth() -> CPSRandomizer {
        let config = Configuration(
            enabled: true,
            variancePercentage: 0.25,
            distributionPattern: .normal,
            humannessLevel: .extreme,
            patternBreakupFrequency: 0.12
        )
        return CPSRandomizer(configuration: config)
    }
}