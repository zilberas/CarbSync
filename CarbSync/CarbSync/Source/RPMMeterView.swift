//
//  RPMMeterView.swift
//  CarbSync
//
//  Created by Zilvinas Sebeika on 2019-12-08.
//  Copyright © 2019 GARAZAS. All rights reserved.
//

import Cocoa

class RPMMeterView: NSView {
    
    @IBOutlet weak var rpmValueLabel: NSTextField!
    
    private let blockWidth: Int = 4
    private let backgroundBlocksLayer = CAShapeLayer()
    private let valuesBlocksLayer = CAShapeLayer()
    private var blocks: [CGFloat] = []
    
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
        
        blocks = Array(stride(from: 0, to: frame.size.width, by: CGFloat(blockWidth)))
        
        backgroundBlocksLayer.frame = bounds
        backgroundBlocksLayer.strokeColor = NSColor.darkGray.cgColor
        backgroundBlocksLayer.fillColor = NSColor.clear.cgColor
        backgroundBlocksLayer.lineWidth = 1
        backgroundBlocksLayer.path = path(with: blocks, blockWidth: CGFloat(blockWidth), height: bounds.size.height)
        layer?.addSublayer(backgroundBlocksLayer)
        
        valuesBlocksLayer.frame = bounds
        valuesBlocksLayer.strokeColor = NSColor.clear.cgColor
        valuesBlocksLayer.fillColor = NSColor.lightGray.cgColor
        valuesBlocksLayer.path = .none
        layer?.addSublayer(valuesBlocksLayer)
    }
    
    func update(currentValue: Int, maxValue: Int) {
        let filledRatio = Float(blocks.count) * (Float(currentValue) / Float(maxValue))
        let filledBlocks = Array(blocks.prefix(Int(filledRatio)))
        valuesBlocksLayer.path = path(with: filledBlocks, blockWidth: CGFloat(blockWidth), height: frame.size.height)
        
        guard let lastBlock = filledBlocks.last else { return }
        
        rpmValueLabel.isHidden = false
        rpmValueLabel.stringValue = "\(currentValue)"
        var labelFrame = rpmValueLabel.frame
        labelFrame.origin.x = lastBlock
        rpmValueLabel.frame = labelFrame
    }
    
    func reset() {
        rpmValueLabel.stringValue = "0"
        rpmValueLabel.isHidden = true
        valuesBlocksLayer.path = .none
    }
    
    private func path(with blocks: [CGFloat], blockWidth: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for step in blocks {
            guard (Int(step) / Int(blockWidth)) % 2 == 0 else { continue }
            let r = CGRect(x: step + 1, y: 0, width: blockWidth, height: height)
            path.addRoundedRect(in: r, cornerWidth: 2, cornerHeight: 2)
        }
        
        return path
    }
}
