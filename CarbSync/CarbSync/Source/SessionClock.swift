//
//  SessionClock.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-16.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Cocoa

final class SessionClock {
    private var lable: NSTextField?
    private var timer: Timer?
    private var startDate = Date()
    
    func start(clockLabel: NSTextField) {
        lable = clockLabel
        lable?.isHidden = false
        startDate = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self]  _ in
            guard let self = self else { return }
            let passed = Date().timeIntervalSince(self.startDate)
            let clockTime = Date(timeIntervalSinceReferenceDate: passed)
            self.lable?.stringValue = "\(DateFormatter.clockFormatter.string(from: clockTime))"
        })
        
        timer?.fire()
    }
    
    func stop() {
        lable?.isHidden = true
        timer?.invalidate()
    }
}

extension DateFormatter {
    static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(abbreviation: "GMT")
        return f
    }()
}
