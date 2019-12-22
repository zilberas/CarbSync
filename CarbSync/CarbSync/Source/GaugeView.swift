//
//  ViewController.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 22/11/2018.
//  Copyright © 2018 GARAZAS. All rights reserved.
//

import Cocoa
import GLKit

final class GaugeView: NSView {
    
    private let needleLayer = NeedleLayer()
    private let arcsLayer = FadingArcsLayer()
    private var currentArcAngle: CGFloat = 0
    private let valueLabel = NSTextField(labelWithString: "0")
    private let titleLabel = NSTextField(labelWithString: "")
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = false
        
        let mainCircle = MainCircleLayer()
        mainCircle.frame = bounds
        mainCircle.setup()
        layer?.addSublayer(mainCircle)
        
        arcsLayer.frame = bounds
        layer?.addSublayer(arcsLayer)
        
        let measurementsLayer = MeasurementsLayer()
        measurementsLayer.frame = bounds
        measurementsLayer.setup()
        layer?.addSublayer(measurementsLayer)
        
        needleLayer.frame = bounds
        needleLayer.setup()
        layer?.addSublayer(needleLayer)
        
        valueLabel.font = .systemFont(ofSize: 30)
        valueLabel.textColor = .white
        valueLabel.alignment = .center
        valueLabel.frame = CGRect(x: 0, y: -40, width: bounds.width, height: 40)
        self.addSubview(valueLabel)
        
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.frame = CGRect(x: 0, y: 25, width: bounds.width, height: 14)
        self.addSubview(titleLabel)
    }
    
    func set(title: String) {
        titleLabel.stringValue = title
    }
    
    func rotateNeedle(_ r: ProcessedReading) {
        // Arc is drawn starting from left side but we want to start at the bottom
        let rotateOffset = CGFloat(Float.pi/2)
        let originalEndAngle = r.originalDegree.toRadians
        arcsLayer.addArc(startAngle: currentArcAngle - rotateOffset, endAngle: originalEndAngle - rotateOffset)
        currentArcAngle = originalEndAngle
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        needleLayer.transform = CATransform3DMakeRotation(r.avgDegree.toRadians, 0.0, 0.0, 1.0)
        CATransaction.commit()
        
        valueLabel.stringValue = "\(Int(r.avgValue))"
    }
    
    func reset() {
        rotateNeedle(.zero)
    }
}

private final class MainCircleLayer: CAShapeLayer {
    func setup() {
        fillColor = NSColor.clear.cgColor
        strokeColor = NSColor.red.cgColor
        lineWidth = 2
        path = CGPath(ellipseIn: frame, transform: nil)
    }
}

private final class MeasurementsLayer: CAShapeLayer {
    private var minDegree = 0
    private var maxDegree = 300
    private var barWidth: CGFloat = 20
    
    func setup() {
        fillColor = NSColor.clear.cgColor
        strokeColor = NSColor.black.cgColor
        lineWidth = 2
        
        let radius = frame.width/2
        let aPath = CGMutablePath()
        for step in stride(from: minDegree, to: maxDegree, by: 1) {
            let degree = degreeOnCircle(for: step)
            let point = pointOnCircle(radius - ((step % 10) == 5 ? barWidth : barWidth/2), degree)
            aPath.move(to: point)
            aPath.addLine(to: pointOnCircle(radius, degree))
        }
        
        path = aPath
    }
    
    private func pointOnCircle(_ radius: CGFloat, _ degree: Float) -> CGPoint{
        let centerX = frame.width/2
        let centerY = frame.height/2
        return CGPoint(
            x: cos(CGFloat(GLKMathDegreesToRadians(degree)))*radius + centerX,
            y: sin(CGFloat(GLKMathDegreesToRadians(degree)))*radius + centerY
        )
    }
    
    private func degreeOnCircle(for value: Int) -> Float {
        guard value < maxDegree else { return Float(maxDegree) }
        guard value > minDegree else { return Float(minDegree) }
        
        let percent = (Float(value) * 100) / Float(maxDegree)
        let offset = Float((360 - maxDegree))
        
        return (percent * Float(maxDegree)) / 100 - 90 + offset/2
    }
}

private final class NeedleLayer: CAShapeLayer {
    func setup() {
        fillColor = NSColor.red.cgColor
        strokeColor = NSColor.black.cgColor
        lineWidth = 1
        
        let radius = frame.width/2
        let center = CGPoint(x: frame.width/2, y: frame.height/2)
        let aPath = CGMutablePath()
        
        aPath.addArc(
            center: center,
            radius: radius/20,
            startAngle: 0,
            endAngle: CGFloat(Float.pi),
            clockwise: false
        )
        aPath.addLine(to: CGPoint(x: radius, y: 0))
        aPath.closeSubpath()
        
        path = aPath
    }
}

private final class ArcLayer: CAShapeLayer {
    
    func draw(startAngle: CGFloat, endAngle: CGFloat) {
        fillColor = NSColor.lightGray.cgColor
        let radius = frame.width/2 - 10
        let center = CGPoint(x: frame.width/2, y: frame.height/2)
        let aPath = CGMutablePath()
        aPath.move(to: center)
        aPath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: startAngle > endAngle)
        aPath.closeSubpath()
        path = aPath
    }
}

private final class FadingArcsLayer: CALayer {
    private let max = 50
    private var fadingArcs: [ArcLayer] = []
    
    func addArc(startAngle: CGFloat, endAngle: CGFloat) {
        if fadingArcs.count > max {
            fadingArcs[0].removeFromSuperlayer()
            fadingArcs = fadingArcs.suffix(max)
        }
        
        let arc = ArcLayer()
        addSublayer(arc)
        arc.frame = bounds
        arc.draw(startAngle: startAngle, endAngle: endAngle)
        arc.opacity = 0.15
        arc.add(CABasicAnimation.fadeOut(from: arc.opacity), forKey: "opacity")
        
        fadingArcs.append(arc)
    }
}

private extension Float {
    var toRadians: CGFloat {
        return -CGFloat(GLKMathDegreesToRadians(self))
    }
}

private extension CABasicAnimation {
    static func fadeOut(from: Float) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.25
        animation.fromValue = from
        animation.toValue = 0
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        
        return animation
    }
}
