//
//  SpinMeLayer.swift
//  CALayerAnimations
//
//  Created by Dan Lindsay on 2017-01-10.
//  Copyright © 2017 Dan Lindsay. All rights reserved.
//

import UIKit

enum UIColorInputError : Error {
    case missingHashMarkAsPrefix,
    unableToScanHexValue,
    mismatchedHexStringLength
}

extension UIColor {
    
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    convenience init(rgba: String, defaultColor: UIColor = UIColor.clear) {
        guard let color = try? UIColor(rgba_throws: rgba) else {
            self.init(cgColor: defaultColor.cgColor)
            return
        }
        self.init(cgColor: color.cgColor)
    }
    
    convenience init(rgba_throws rgba: String) throws {
        guard rgba.hasPrefix("#") else {
            throw UIColorInputError.missingHashMarkAsPrefix
        }
        
        guard let hexString: String = rgba.substring(from: rgba.characters.index(rgba.startIndex, offsetBy: 1)),
            var   hexValue:  UInt32 = 0, Scanner(string: hexString).scanHexInt32(&hexValue) else {
                throw UIColorInputError.unableToScanHexValue
        }
        
        guard hexString.characters.count  == 3
            || hexString.characters.count == 4
            || hexString.characters.count == 6
            || hexString.characters.count == 8 else {
                throw UIColorInputError.mismatchedHexStringLength
        }
        
        switch (hexString.characters.count) {
        case 6:
            self.init(hex6: hexValue)
        default:
            self.init(hex6: hexValue)
        }
    }
    
    convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func set(hueSaturationOrBrightness hsb: HSBA, percentage: CGFloat) -> UIColor {
        var hueValue : CGFloat = 0.0, saturationValue : CGFloat = 0.0, brightnessValue : CGFloat = 0.0, alphaValue : CGFloat = 0.0
        self.getHue(&hueValue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alphaValue)
        
        switch hsb {
        case .hue:
            print(hueValue)
            return UIColor(hue: hueValue * percentage, saturation: saturationValue, brightness: brightnessValue, alpha: alphaValue)
        case .saturation:
            return UIColor(hue: hueValue, saturation: saturationValue * percentage, brightness: brightnessValue, alpha: alphaValue)
        case .brightness:
            return UIColor(hue: hueValue, saturation: saturationValue, brightness: brightnessValue * percentage, alpha: alphaValue)
        case .alpha:
            return UIColor(hue: hueValue, saturation: saturationValue, brightness: brightnessValue, alpha: alphaValue * percentage)
        }
    }
    
}

enum HSBA {
    case hue
    case saturation
    case brightness
    case alpha
}

class SpinMeLayer: CATransformLayer {
    
    var color: UIColor = UIColor.white {
        didSet {
            guard let sublayers = sublayers, sublayers.count > 0 else { return }
            for (index, layer) in sublayers.enumerated() {
       //         (layer as? CAShapeLayer)?.fillColor = color.set(hueSaturationOrBrightness: .Brightness, percentage: 1.0-(0.1*CGFloat(index))).CGColor
                (layer as? CAShapeLayer)?.fillColor = color.set(hueSaturationOrBrightness: .brightness, percentage: 1.0-(0.1*CGFloat(index))).cgColor
                
            }
        }
    }
    
    /* Adjust the size later on and the stack will redraw.
     *
     * The corner radius is calculated to be the result of the width / 4. Assuming the width === height.
     * Default size is 100x100.
     */
    
    var size: CGSize = CGSize(width: 100, height: 100) {
        didSet {
            sublayers?.forEach({
                ($0 as? CAShapeLayer)?.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: size.width/4).cgPath
                ($0 as? CAShapeLayer)?.frame = ((($0 as? CAShapeLayer)?.path)?.boundingBox)!
                setAnchorPoint(CGPoint(x: 0.5, y: 0.5), forLayer: $0)
            })
        }
    }
    
    convenience init(withNumberOfItems items: Int) {
        self.init()
        masksToBounds = false
        
        for i in 0..<items {
            let layer = generateLayer(withSize: size, withIndex: i)
            insertSublayer(layer, at: 0)
            setZPosition(ofShape: layer, z: CGFloat(i))
        }
        
        sublayers = sublayers?.reversed()
        centerInSuperlayer()
        rotateParentLayer(toDegree: 60)
    }
    
    fileprivate func generateLayer(withSize size: CGSize, withIndex index: Int) -> CAShapeLayer {
        let square = CAShapeLayer()
        square.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: size.width/4).cgPath
        square.frame = ((square.path)?.boundingBox)!
        setAnchorPoint(CGPoint(x: 0.5, y: 0.5), forLayer: square)
        return square
    }
    
    // Because adjusting the anchorPoint itself adjusts the frame, this is needed to avoid it, and keep the layer stationary.
    
    fileprivate func setAnchorPoint(_ anchorPoint: CGPoint, forLayer layer: CALayer) {
        var newPoint = CGPoint(x: layer.bounds.size.width * anchorPoint.x, y: layer.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: layer.bounds.size.width * layer.anchorPoint.x, y: layer.bounds.size.height * layer.anchorPoint.y)
        newPoint = newPoint.applying(layer.affineTransform())
        oldPoint = oldPoint.applying(layer.affineTransform())
        
        var position = layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        layer.position = position
        layer.anchorPoint = anchorPoint
    }
    
    fileprivate func setZPosition(ofShape shape: CAShapeLayer, z: CGFloat) {
        shape.zPosition = z*(-20)
    }
    
    fileprivate func centerInSuperlayer() {
        frame = CGRect(x: getX(), y: getY(), width: size.width, height: size.height)
    }
    
    fileprivate func getX() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        return (screenWidth/2)-(size.width/2)
    }
    
    fileprivate func getY() -> CGFloat {
        let screenHeight = UIScreen.main.bounds.size.height
        return (screenHeight/2)-(2*(size.height/2))
    }
    
    // When the time comes to animate, we'll need this. It converts...well...degrees into radians..
    
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return ((CGFloat(M_PI) * degrees) / 180.0)
    }
    
    
}

extension SpinMeLayer {
    func startAnimating() {
        var offsetTime = 0.0
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -500.0
        transform = CATransform3DRotate(transform, CGFloat(M_PI), 0, 0, 1)
        
        CATransaction.begin()
        sublayers?.forEach({
            let basic = getSpin(forTransform: transform)
            basic.beginTime = $0.convertTime(CACurrentMediaTime(), to: nil) + offsetTime
            $0.add(basic, forKey: nil)
            offsetTime += 0.1
        })
        CATransaction.commit()
    }
    
    func stopAnimating() {
        sublayers?.forEach({ $0.removeAllAnimations() })
    }
    
    fileprivate func getSpin(forTransform transform: CATransform3D) -> CABasicAnimation {
        let basic = CABasicAnimation(keyPath: "transform")
        basic.toValue = NSValue(caTransform3D: transform)
        basic.duration = 1.0
        basic.fillMode = kCAFillModeForwards
        basic.repeatCount = HUGE
        basic.autoreverses = true
        basic.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        basic.isRemovedOnCompletion = false
        return basic
    }
    
    fileprivate func rotateParentLayer(toDegree degree: CGFloat) {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -500.0
        transform = CATransform3DRotate(transform, degreesToRadians(degree), 1, 0, 0)
        self.transform = transform
    }
}


























