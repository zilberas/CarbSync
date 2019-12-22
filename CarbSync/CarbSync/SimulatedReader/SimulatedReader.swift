//
//  MockReader.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-05.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Foundation

private struct DataLine {
    let date: Date
    let sensorsData: SensorsData

    init?(components: [String], dateFormatter: DateFormatter) {
        guard components.count >= 5 else {
            print("Skipped mock data line: \(components)")
            return nil
        }
        self.date = dateFormatter.date(from: components[0])!
        self.sensorsData = SensorsData(
            carb1: Int(components[1])!,
            carb2: Int(components[2])!,
            carb3: Int(components[3])!,
            carb4: Int(components[4])!
        )
    }
}

class SimulatedReader: SensorReader {
    
    private let timestampPresition = 0.001
    private let data: [DataLine]
    private var lastFire = Date()
    private var lastTimestamp: Date?
    private var currentIdx: Int = 0
    private var timer: Timer?
    
    init() {
        print("Reading MOCK data...")
        self.data = Bundle.main.mockData
        print("Done reading")
    }
    
    func start(callback: @escaping (SensorsData) -> Void) {
        timer?.invalidate()
        lastTimestamp = data[0].date
        lastFire = Date()
        currentIdx = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: timestampPresition, repeats: true) { [weak self] _ in
            self?.checkFiring(callback: callback)
        }
        
        timer?.fire()
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    private func checkFiring(callback: @escaping (SensorsData) -> Void) {
        guard currentIdx < data.count - 1 else {
            timer?.invalidate()
            return
        }
        
        let measurement = data[currentIdx + 1]
        let wait = measurement.date.timeIntervalSince(lastTimestamp!)
        let now = Date()
        let timeSinceLastFire = now.timeIntervalSince(lastFire)
        if timeSinceLastFire > wait {
            callback(measurement.sensorsData)
            lastTimestamp = measurement.date
            lastFire = now
            currentIdx += 1
        }
    }
}

private extension Bundle {
    var mockData: [DataLine] {
        return path(forResource: "MockData", ofType: "txt")?.readMockData() ?? []
    }
}

private extension String {
    private static let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    var noSpaces: String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    var components: [String] {
        return self.components(separatedBy: ";").map { $0.noSpaces }
    }
    
    func readMockData() -> [DataLine] {
        do {
            let data = try String(contentsOfFile: self, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)
            return lines.compactMap { DataLine(components: $0.components, dateFormatter: String.df) }
        } catch {
            print(error)
        }
        
        return []
    }
}
