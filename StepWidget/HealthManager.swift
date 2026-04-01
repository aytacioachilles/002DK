//
//  HealthManager.swift
//  StepWidget
//
//  Created by Aytac Akyildiz on 01/04/2026.
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthManager: ObservableObject {
    private let store = HKHealthStore()
    
    @Published var stepCount: Int = 0
    @Published var needsPermission: Bool = false
    @Published var statusMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date? = nil
    
    func setup() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Health data is not available on this device."
            return
        }
        checkPermissionAndFetch()
    }
    
    func checkPermissionAndFetch() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let status = store.authorizationStatus(for: stepType)
        
        switch status {
        case .notDetermined:
            needsPermission = true
            statusMessage = "This app needs to read your steps from Health."
        case .sharingDenied:
            needsPermission = true
            statusMessage = "Please go to Settings → Health → Data Access to allow step access."
        case .sharingAuthorized:
            needsPermission = false
            statusMessage = nil
            fetchSteps()
        @unknown default:
            break
        }
    }
    
    func requestPermission() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        store.requestAuthorization(toShare: [], read: [stepType]) { [weak self] success, error in
            Task { @MainActor in
                if success {
                    self?.needsPermission = false
                    self?.statusMessage = nil
                    self?.fetchSteps()
                } else {
                    self?.statusMessage = "Could not get permission. Please check Settings → Health."
                }
            }
        }
    }
    
    func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        // Don't fetch if already loading
        guard !isLoading else { return }
        
        isLoading = true
        statusMessage = nil
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error {
                    self?.statusMessage = "Could not load steps. Pull down to try again."
                    return
                }
                
                guard let result, let sum = result.sumQuantity() else {
                    self?.stepCount = 0
                    self?.lastUpdated = Date()
                    return
                }
                
                self?.stepCount = Int(sum.doubleValue(for: .count()))
                self?.lastUpdated = Date()
            }
        }
        
        store.execute(query)
    }
}
