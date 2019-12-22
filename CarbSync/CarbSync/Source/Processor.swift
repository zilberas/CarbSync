//
//  Processor.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-15.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Foundation

struct ProcessedReading {
    let maxValue: Float = 2_000_000.0 //2_000_000.0 //9_500_000.0
    let avgValue: Float
    let avgDegree: Float
    let originalValue: Int
    let originalDegree: Float
    
    init(avgValue: Float, originalValue: Int) {
        self.avgValue = avgValue
        self.avgDegree = 360.0 * avgValue/maxValue
        self.originalValue = originalValue
        self.originalDegree = 360.0 * Float(originalValue)/maxValue
    }
    
    static let zero = ProcessedReading(avgValue: 0, originalValue: 0)
}

final class Processor {
    
    var countForAverage: Int {
        didSet {
            countForAverage = max(1, countForAverage)
        }
    }
    
    init(countForAverage: Int) {
        self.countForAverage = countForAverage
    }
    
    private var cache: [[Float]] = [[0],[0],[0],[0]]
    
    private func updateCache(_ values: [Float]) {
        var newCache: [[Float]] = [[0],[0],[0],[0]]
        cache.enumerated().forEach { idx, valuesArray in
            var newValues = valuesArray.suffix(countForAverage)
            newValues.append(values[idx])
            newCache[idx] = Array(newValues)
        }
        cache = newCache
    }
    
    func process(data: SensorsData) -> [ProcessedReading] {
        let datas = [Float(data.carb1), Float(data.carb2), Float(data.carb3), Float(data.carb4)]
        updateCache(datas)
        
        return datas
            .enumerated()
            .map { ProcessedReading(avgValue: cache[$0].avg, originalValue: Int($1)) }
    }
}

extension Array where Element == Float {
    var avg: Float {
        return Float(reduce(0, +)) / Float(count)
    }
}
