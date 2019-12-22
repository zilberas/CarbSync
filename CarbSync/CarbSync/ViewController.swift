//
//  ViewController.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 22/11/2018.
//  Copyright © 2018 GARAZAS. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var gauge1: GaugeView!
    @IBOutlet var gauge2: GaugeView!
    @IBOutlet var gauge3: GaugeView!
    @IBOutlet var gauge4: GaugeView!
    
    @IBOutlet var rpmMeterView: RPMMeterView!
    
    @IBOutlet var sensitivitySlider: NSSlider!
    @IBOutlet var sensitivityValue: NSTextField!
    @IBOutlet var demoSwitch: NSButton!
    @IBOutlet var logSwitch: NSButton!
    @IBOutlet var clockLabel: NSTextField!
    
    private let chipReader = ReaderHX710B()
    private lazy var simulatedReader = SimulatedReader()
    private var reader: SensorReader {
        demoSwitch.state == .on ? simulatedReader : chipReader
    }
    
    private let processor = Processor(countForAverage: 10)
    private let rpmCalculator = RPMCalculator()
    private lazy var logger = Logger()
    private lazy var clock = SessionClock()
    
    private var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sensitivitySlider.integerValue = processor.countForAverage
        gauge1.set(title: "Carb 1")
        gauge2.set(title: "Carb 2")
        gauge3.set(title: "Carb 3")
        gauge4.set(title: "Carb 4")
    }
    
    private func updateUI(sensorsData: SensorsData) {
        guard isRunning else { return }
        
        if logSwitch.state == .on {
            logger.log(data: sensorsData)
        }
        
        let readings = processor.process(data: sensorsData)
        
        gauge1.rotateNeedle(readings[0])
        gauge2.rotateNeedle(readings[1])
        gauge3.rotateNeedle(readings[2])
        gauge4.rotateNeedle(readings[3])
        
        rpmCalculator.calculateRPM(
            data: Int(sensorsData.carb1), //TODO: pick #3?
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        rpmMeterView.update(currentValue: rpmCalculator.rpm, maxValue: rpmCalculator.maxValue)
        
        sensitivityValue.stringValue = "\(processor.countForAverage)"
    }
    
    private func resetGauges() {
        gauge1.reset()
        gauge2.reset()
        gauge3.reset()
        gauge4.reset()
    }
    
    @IBAction private func start(_: Any) {
        isRunning = true
        reader.start { [weak self] d in
            self?.updateUI(sensorsData: d)
        }
        clock.start(clockLabel: clockLabel)
    }
    
    @IBAction private func stop(_: Any) {
        isRunning = false
        reader.stop()
        rpmCalculator.reset()
        rpmMeterView.reset()
        resetGauges()
        clock.stop()
    }
    
    @IBAction func onSensitivitySlide(_ sender: NSSlider) {
        processor.countForAverage = sender.integerValue
    }
    
    @IBAction func onDemoSwitch(_ sender: NSButton) {
        stop(sender)
    }
}
