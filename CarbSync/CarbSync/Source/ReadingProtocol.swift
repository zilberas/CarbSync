//
//  ReadingProtocol.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-15.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Foundation

struct SensorsData {
    let carb1: Int
    let carb2: Int
    let carb3: Int
    let carb4: Int
}

protocol SensorReader {
    func start(callback: @escaping (SensorsData) -> Void)
    func stop()
}

final class Logger {
    
    private lazy var logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    var timestamp: String {
        return logFormatter.string(from: Date())
    }
    
    func log(data d: SensorsData) {
        print("\(timestamp); \(d.carb1); \(d.carb2); \(d.carb3); \(d.carb4);")
    }
}
