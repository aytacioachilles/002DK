//
//  StepWidgetExtension.swift
//  StepWidgetExtension
//
//  Created by Aytac Akyildiz on 01/04/2026.
//

import WidgetKit
import SwiftUI
import HealthKit

// MARK: - HealthKit Step Reader

func fetchStepsForWidget(completion: @escaping (Int) -> Void) {
    guard HKHealthStore.isHealthDataAvailable() else {
        completion(0)
        return
    }
    
    let store = HKHealthStore()
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
        completion(0)
        return
    }
    
    let now = Date()
    let startOfDay = Calendar.current.startOfDay(for: now)
    let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
    
    let query = HKStatisticsQuery(
        quantityType: stepType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
    ) { _, result, _ in
        guard let result, let sum = result.sumQuantity() else {
            completion(0)
            return
        }
        completion(Int(sum.doubleValue(for: .count())))
    }
    
    store.execute(query)
}

// MARK: - Timeline Entry

struct StepEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let authorized: Bool
}

// MARK: - Timeline Provider

struct StepProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepEntry {
        StepEntry(date: .now, steps: 8000, authorized: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StepEntry) -> Void) {
        fetchStepsForWidget { steps in
            completion(StepEntry(date: .now, steps: steps, authorized: true))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepEntry>) -> Void) {
        fetchStepsForWidget { steps in
            let entry = StepEntry(date: .now, steps: steps, authorized: true)
            
            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Widget View

struct StepWidgetEntryView: View {
    var entry: StepEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(entry.steps)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            Text("steps")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct StepWidgetExtension: Widget {
    let kind: String = "StepWidgetExtension"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepProvider()) { entry in
            StepWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Step Count")
        .description("Shows your daily step count on the lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    StepWidgetExtension()
} timeline: {
    StepEntry(date: .now, steps: 4231, authorized: true)
}
