//
//  ReaderHX710B.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-15.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Foundation
import HX710BDriver

extension Notification.Name {
    static let driverCallback = Notification.Name("driverCallback")
}

class ReaderHX710B: SensorReader {
    
    private var stopFlag: Int32 = 0
    private var calibrationSampleIdx = 10
    private var calibrationSample = SensorsData(carb1: 0, carb2: 0, carb3: 0, carb4: 0)
    private var onData: ((SensorsData) -> Void)?
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidReceivedNotification(_:)),
            name: .driverCallback,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //https://forums.developer.apple.com/thread/27059
    //Need to convert self to UnsafeRawPointer pointer, pass it as a function param and dereference self in callback
    //OR use NotificationCenter
    func start(callback: @escaping (SensorsData) -> Void) {
        onData = callback
        stopFlag = 0
        DispatchQueue.global().async {
            startReading(&self.stopFlag) { data in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name.driverCallback,
                        object: nil,
                        userInfo: ["data": data]
                    )
                }
            }
        }
    }
    
    func stop() {
        stopFlag = 1
    }
    
    @objc private func onDidReceivedNotification(_ notification: Notification) {
        let readings = notification.userInfo?["data"] as! Readings
        onDidReceiveData(readings)
    }
    
    private func cacheCalibrationSample(_ data: SensorsData) {
        guard calibrationSampleIdx > 0 else { return }
        
        calibrationSample = data
        calibrationSampleIdx -= 1
    }
    
    private func onDidReceiveData(_ data: Readings) {
        let sensorData = data.toIntSensorData
        cacheCalibrationSample(sensorData)
        onData?(sensorData.calibrateWith(calibrationSample))
    }
}

private extension Readings {
    var toIntSensorData: SensorsData {
        return SensorsData(
            carb1: Int(sensor1),
            carb2: Int(sensor2),
            carb3: Int(sensor3),
            carb4: Int(sensor4)
        )
    }
}

private extension SensorsData {
    func calibrateWith(_ calibrationSample: SensorsData) -> SensorsData {
        return SensorsData(
            carb1: calibrationSample.carb1 - self.carb1,
            carb2: calibrationSample.carb2 - self.carb2,
            carb3: calibrationSample.carb3 - self.carb3,
            carb4: calibrationSample.carb4 - self.carb4
        )
    }
}
