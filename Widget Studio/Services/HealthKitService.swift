import SwiftUI
import Combine
import HealthKit

/// Service interacting with Apple HealthKit framework to supply live health metrics
/// to Liquid Glass widgets: Steps, Active Energy, Heart Rate, Resting Vitals, Blood Oxygen (SpO2),
/// Respiratory Rate, Sleep Analysis, Sleep Score, Water Intake, and Caffeine.
@MainActor
public final class HealthKitService: ObservableObject {
    public static let shared = HealthKitService()

    // 1. Activity & Cardio
    @Published public var todaySteps: Int = 8420
    @Published public var activeCalories: Int = 465
    @Published public var currentHeartRate: Int = 72
    @Published public var restingHeartRate: Int = 62

    // 2. Respiratory & Oxygenation
    @Published public var bloodOxygen: Double = 98.4 // SpO2 in %
    @Published public var respiratoryRate: Double = 15.0 // Breaths/min

    // 3. Sleep & Recovery
    @Published public var sleepHours: Double = 7.8 // Hours
    @Published public var sleepScore: Int = 89 // 0 - 100 Score

    // 4. Hydration & Nutrition
    @Published public var waterIntakeMl: Double = 1850 // mL
    @Published public var caffeineMg: Double = 120 // mg

    @Published public var isLoading: Bool = false

    private let healthStore = HKHealthStore()

    public init() {
        Task {
            await fetchAllMetrics()
        }
    }

    /// Fetches all health metrics asynchronously from HKHealthStore
    public func fetchAllMetrics() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isLoading = true
        defer { isLoading = false }

        await fetchTodaySteps()
        await fetchTodayActiveEnergy()
        await fetchLatestHeartRate()
        await fetchRestingHeartRate()
        await fetchBloodOxygen()
        await fetchRespiratoryRate()
        await fetchSleepAnalysis()
        await fetchWaterIntake()
        await fetchCaffeineIntake()
    }

    // MARK: - 1. Activity & Cardio Queries

    /// Queries step count for current calendar day using HKStatisticsQuery
    public func fetchTodaySteps() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                Task { @MainActor in
                    if steps > 0 {
                        self.todaySteps = Int(steps)
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    /// Queries active calories burned for current calendar day
    public func fetchTodayActiveEnergy() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                Task { @MainActor in
                    if calories > 0 {
                        self.activeCalories = Int(calories)
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    /// Queries the most recent heart rate sample
    public func fetchLatestHeartRate() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let bpm = sample.quantity.doubleValue(for: heartRateUnit)
                    Task { @MainActor in
                        if bpm > 0 {
                            self.currentHeartRate = Int(bpm)
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    /// Queries the latest resting heart rate sample
    public func fetchRestingHeartRate() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: restingType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let bpm = sample.quantity.doubleValue(for: heartRateUnit)
                    Task { @MainActor in
                        if bpm > 0 {
                            self.restingHeartRate = Int(bpm)
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 2. Respiratory & Oxygenation Queries

    /// Queries latest Blood Oxygen (SpO2) saturation percentage
    public func fetchBloodOxygen() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let o2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: o2Type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let percent = sample.quantity.doubleValue(for: HKUnit.percent()) * 100.0
                    Task { @MainActor in
                        if percent > 0 {
                            self.bloodOxygen = (percent * 10).rounded() / 10.0
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    /// Queries latest Respiratory Rate (breaths per minute)
    public func fetchRespiratoryRate() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let respType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: respType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    let breaths = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    Task { @MainActor in
                        if breaths > 0 {
                            self.respiratoryRate = (breaths * 10).rounded() / 10.0
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 3. Sleep & Recovery Queries

    /// Queries Sleep Analysis from the past 24 hours and calculates Sleep Score
    public func fetchSleepAnalysis() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now.addingTimeInterval(-86400)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                if let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty {
                    var totalDurationSeconds: TimeInterval = 0
                    for sample in sleepSamples {
                        if sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                            totalDurationSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                        }
                    }
                    let hours = totalDurationSeconds / 3600.0
                    Task { @MainActor in
                        if hours > 0 {
                            self.sleepHours = (hours * 10).rounded() / 10.0
                            let targetHours: Double = 8.0
                            let ratio = min(self.sleepHours / targetHours, 1.15)
                            let score = Int(min(max(ratio * 90.0, 45.0), 98.0))
                            self.sleepScore = score
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - 4. Hydration & Nutrition Queries

    /// Queries today's water intake in milliliters
    public func fetchWaterIntake() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: waterType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let ml = result?.sumQuantity()?.doubleValue(for: HKUnit.literUnit(with: .milli)) ?? 0
                Task { @MainActor in
                    if ml > 0 {
                        self.waterIntakeMl = ml
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    /// Queries today's caffeine intake in milligrams
    public func fetchCaffeineIntake() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: caffeineType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let mg = result?.sumQuantity()?.doubleValue(for: HKUnit.gramUnit(with: .milli)) ?? 0
                Task { @MainActor in
                    if mg > 0 {
                        self.caffeineMg = mg
                    }
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Interactive Logging Helpers

    /// Adds water intake directly to current state and persists to HealthKit
    public func logWaterIntake(amountMl: Double = 250) {
        waterIntakeMl += amountMl
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }

        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountMl)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: Date(), end: Date())
        healthStore.save(sample) { _, _ in }
    }

    /// Adds caffeine intake directly to current state and persists to HealthKit
    public func logCaffeine(amountMg: Double = 60) {
        caffeineMg += amountMg
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let caffeineType = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) else { return }

        let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: amountMg)
        let sample = HKQuantitySample(type: caffeineType, quantity: quantity, start: Date(), end: Date())
        healthStore.save(sample) { _, _ in }
    }
}
