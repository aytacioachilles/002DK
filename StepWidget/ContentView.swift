//
//  ContentView.swift
//  StepWidget
//
//  Created by Aytac Akyildiz on 01/04/2026.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Top label
                Text("TODAY'S STEPS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .kerning(2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)
                
                // Step count or spinner
                ZStack {
                    Circle()
                        .stroke(Color.pink.opacity(0.15), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: min(CGFloat(healthManager.stepCount) / 10000, 1.0))
                        .stroke(Color.pink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: healthManager.stepCount)
                    
                    VStack(spacing: 4) {
                        if healthManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.3)
                        } else {
                            Text("\(healthManager.stepCount)")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                                .animation(.spring(), value: healthManager.stepCount)
                            
                            Text("of 10,000 goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 32)
                
                // Date
                Text(Date.now.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                
                // Last updated
                if let lastUpdated = healthManager.lastUpdated {
                    Text("Updated at \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Status message
                if let message = healthManager.statusMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }
                
                // Permission button
                if healthManager.needsPermission {
                    Button(action: {
                        healthManager.requestPermission()
                    }) {
                        Label("Allow Health Access", systemImage: "heart.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)
                }
                
                // Refresh button
                Button(action: {
                    healthManager.fetchSteps()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .disabled(healthManager.isLoading)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            healthManager.setup()
        }
        .refreshable {
            healthManager.fetchSteps()
        }
    }
}

#Preview {
    ContentView()
}
