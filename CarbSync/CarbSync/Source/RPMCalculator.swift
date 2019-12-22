//
//  RPMCalculator.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-11-27.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Foundation

class RPMCalculator {
    
    let maxValue = 1200
    
    private struct Sample {
        let isPeak: Bool
        let timestamp: TimeInterval
    }
    
    private var windowCount = 40 * 4 // 40 ~ 1 sec
    private var samplesToAverage = 5
    private var rmpValues: [Double] = []
    
    private var samples: [Sample] = []
    private var before: Int = 0
    private var value: Int = 0
    private var after: Int = 0
    
    var rpm: Int {
        let avgValue = rmpValues.reduce(0, +) / Double(samplesToAverage)
        return Int(avgValue)
    }
    
    var peaksCount: Int {
        samples.filter { $0.isPeak }.count
    }
    
    var duration: Double = 0
    
    var hz: Double = 0
    
    func calculateRPM(data: Int, timestamp: TimeInterval) {
        before = value
        value = after
        after = data
        
        samples = samples.suffix(windowCount)
        
        if value > before && value > after {
            samples.append(Sample(isPeak: true, timestamp: timestamp))
        } else {
            samples.append(Sample(isPeak: false, timestamp: timestamp))
        }
        
        takeRPMMeasure()
    }
    
    func reset() {
        before = 0
        value = 0
        after = 0
        
        samples.removeAll()
        rmpValues.removeAll()
    }
    
    private func takeRPMMeasure() {
        rmpValues = rmpValues.suffix(samplesToAverage)
        
        guard
            let start = samples.first?.timestamp,
            let end = samples.last?.timestamp
        else { return }
                
        guard peaksCount > 0 else { return }
        
        duration = end - start
        
        let period = duration / Double(peaksCount)
        
        hz = 1 / period
        rmpValues.append(hz * 60)
    }
}
