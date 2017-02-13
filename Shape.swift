// Copyright © 2014 C4
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

import QuartzCore
import UIKit

/// Shape is a concrete subclass of View that draws a bezier path in its coordinate space.
open class Shape: View {
    internal class ShapeView: UIView {
        var shapeLayer: ShapeLayer {
            return self.layer as! ShapeLayer // swiftlint:disable:this force_cast
        }

        override class var layerClass : AnyClass {
            return ShapeLayer.self
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if CGPathContainsPoint(shapeLayer.path, nil, point, shapeLayer.fillRule == kCAFillRuleNonZero ? false : true) {
                return self
            }
            return nil
        }
    }

    /// C4Shape's contents are drawn on a ShapeLayer.
    open var shapeLayer: ShapeLayer {
        get {
            return self.shapeView.shapeLayer
        }
    }

    internal var shapeView: ShapeView {
        return self.view as! ShapeView // swiftlint:disable:this force_cast
    }

    ///  Initializes an empty Shape.
    public override init() {
        super.init()
        self.view = ShapeView(frame: CGRect(frame))
        strokeColor = C4Purple
        fillColor = C4Blue
        lineWidth = 1
        lineCap = .round
        lineJoin = .round

        let image = UIImage.createWithColor(UIColor.clear, size: CGSize(width: 1, height: 1)).cgImage
        shapeLayer.contents = image
    }

    /// Initializes a new Shape from a specified Path.
    /// - parameter path: A Path around which the new shape is created with the frame of the new shape fitting the path on
    /// screen.
    public convenience init(_ path: Path) {
        self.init()

        self.path = path
        shapeLayer.path = path.CGPath

        updatePath()
        adjustToFitPath()
    }

    public override init(frame: Rect) {
        super.init()
        self.view = ShapeView(frame: CGRect(frame))
        strokeColor = C4Purple
        fillColor = C4Blue
        lineWidth = 1
        lineCap = .round
        lineJoin = .round

        let image = UIImage.createWithColor(UIColor.clear, size: CGSize(width: 1, height: 1)).cgImage
        shapeLayer.contents = image
    }

    /// Initializes a new Shape from the properties of another Shape. Essentially, this copies the provided shape.
    /// - parameter shape: A Shape around which the new shape is created.
    public convenience init(copy original: Shape) {
        //If there is a scale transform we need to undo that
        let t = original.view.transform.inverted()
        let x = sqrt(t.a * t.a + t.c * t.c)
        let y = sqrt(t.b * t.b + t.d * t.d)
        let s = CGAffineTransform(scaleX: x, y: y)
        self.init(frame: Rect(original.view.frame.applying(s)))

        let disable = ShapeLayer.disableActions
        ShapeLayer.disableActions = true
        self.path = original.path
        shapeLayer.path = path?.CGPath
        self.lineWidth = original.lineWidth
        self.lineDashPhase = original.lineDashPhase
        self.lineCap = original.lineCap
        self.lineJoin = original.lineJoin
        self.lineDashPattern = original.lineDashPattern
        self.fillColor = original.fillColor
        self.strokeColor = original.strokeColor
        self.strokeStart = original.strokeStart
        self.strokeEnd = original.strokeEnd
        self.miterLimit = original.miterLimit
        updatePath()
        adjustToFitPath()
        copyViewStyle(original)
        ShapeLayer.disableActions = disable
    }

    ///An optional variable representing a gradient. If this is non-nil, then the shape will appear to be filled with a gradient.
    open var gradientFill: Gradient? {
        didSet {
            guard gradientFill != nil else {
                fillColor = clear
                return
            }
            let gim = gradientFill?.render()?.cgimage

            //inverts coordinate for graphics context rendering
            var b = bounds
            b.origin.y = self.height - b.origin.y

            UIGraphicsBeginImageContextWithOptions(CGSize(b.size), false, UIScreen.main.scale)
            let context = UIGraphicsGetCurrentContext()

            CGContextDrawTiledImage(context, CGRect(b), gim)
            let uiimage = UIGraphicsGetImageFromCurrentImageContext()
            let uicolor = UIColor(patternImage: uiimage!)
            fillColor = Color(uicolor)
            UIGraphicsEndImageContext()
        }
    }

    /// The path defining the shape to be rendered. If the path extends outside the layer bounds it will not automatically
    /// be clipped to the layer. Defaults to nil. Animatable.
    open var path: Path? {
        didSet {
            shapeLayer.path = path?.CGPath
        }
    }

    internal func updatePath() {}

    /// Adjusts the shape's frame to the bounding bounding box of its specified path.
    open func adjustToFitPath() {
        if shapeLayer.path == nil {
            return
        }
        view.bounds = (shapeLayer.path?.boundingBoxOfPath)!
        view.frame = view.bounds
    }


    /// Returns the receiver's frame. Animatable.
    open override var frame: Rect {
        get {
            return Rect(view.frame)
        }
        set {
            view.frame = CGRect(newValue)
            updatePath()
        }
    }

    /// The line width used when stroking the path. Defaults to 1.0. Animatable.
    @IBInspectable
    open var lineWidth: Double {
        get { return Double(shapeLayer.lineWidth) }
        set(width) { shapeLayer.lineWidth = CGFloat(width) }
    }

    /// The color to stroke the path, or nil for no fill. Defaults to opaque black. Animatable.
    open var strokeColor: Color? {
        get {
            if let color = shapeLayer.strokeColor {
                return Color(color)
            } else {
                return nil
            }
        }
        set(color) {
            shapeLayer.strokeColor = color?.CGColor
        }
    }

    /// The color to fill the path, or nil for no fill. Defaults to opaque black. Animatable.
    open var fillColor: Color? {
        get {
            if let color = shapeLayer.fillColor {
                return Color(color)
            } else {
                return nil
            }
        }
        set(color) {
            shapeLayer.fillColor = color?.CGColor
        }
    }

    /// The fill rule used when filling the path. Defaults to `NonZero`.
    open var fillRule: FillRule {
        get {
            switch shapeLayer.fillRule {
            case kCAFillRuleNonZero:
                return .nonZero
            case kCAFillRuleEvenOdd:
                return .evenOdd
            default:
                return .nonZero
            }
        }
        set(fillRule) {
            switch fillRule {
            case .nonZero:
                shapeLayer.fillRule = kCAFillRuleNonZero
            case .evenOdd:
                shapeLayer.fillRule = kCAFillRuleEvenOdd
            }
        }
    }

    /// The current rotation value of the view. Animatable.
    /// - returns: A Double value representing the cumulative rotation of the view, measured in Radians.
    open override var rotation: Double {
        get {
            if let number = shapeLayer.value(forKeyPath: Layer.rotationKey) as? NSNumber {
                return number.doubleValue
            }
            return  0.0
        }
        set {
            shapeLayer.setValue(newValue, forKeyPath: Layer.rotationKey)
        }
    }

    /// This value defines the start of the path used to draw the stroked outline. The value must be in the range [0,1]
    /// with zero representing the start of the path and one the end. Values in between zero and one are interpolated
    /// linearly along the path length. Defaults to zero. Animatable.
    open var strokeStart: Double {
        get { return Double(shapeLayer.strokeStart) }
        set(start) { shapeLayer.strokeStart = CGFloat(start) }
    }

    /// This value defines the end of the path used to draw the stroked outline. The value must be in the range [0,1]
    /// with zero representing the start of the path and one the end. Values in between zero and one are interpolated
    /// linearly along the path length. Defaults to 1.0. Animatable.
    open var strokeEnd: Double {
        get { return Double(shapeLayer.strokeEnd) }
        set(end) { shapeLayer.strokeEnd = CGFloat(end) }
    }

    /// The miter limit used when stroking the path. Defaults to ten. Animatable.
    @IBInspectable
    open var miterLimit: Double {
        get { return Double(shapeLayer.miterLimit) }
        set(miterLimit) { shapeLayer.miterLimit = CGFloat(miterLimit) }
    }

    /// The cap style used when stroking the path. Defaults to `Butt`.
    open var lineCap: LineCap {
        get {
            switch shapeLayer.lineCap {
            case kCALineCapButt:
                return .butt
            case kCALineCapRound:
                return .round
            case kCALineCapSquare:
                return .square
            default:
                return .butt
            }
        }
        set(lineCap) {
            switch lineCap {
            case .butt:
                shapeLayer.lineCap = kCALineCapButt
            case .round:
                shapeLayer.lineCap = kCALineCapRound
            case .square:
                shapeLayer.lineCap = kCALineCapSquare
            }
        }
    }

    /// The join style used when stroking the path. Defaults to `Miter`.
    open var lineJoin: LineJoin {
        get {
            switch shapeLayer.lineJoin {
            case kCALineJoinMiter:
                return .miter
            case kCALineJoinRound:
                return .round
            case kCALineJoinBevel:
                return .bevel
            default:
                return .miter
            }
        }
        set(lineJoin) {
            switch lineJoin {
            case .miter:
                shapeLayer.lineJoin = kCALineJoinMiter
            case .round:
                shapeLayer.lineJoin = kCALineJoinRound
            case .bevel:
                shapeLayer.lineJoin = kCALineJoinBevel
            }
        }
    }

    /// The phase of the dashing pattern applied when creating the stroke. Defaults to zero. Animatable.
    open var lineDashPhase: Double {
        get { return Double(shapeLayer.lineDashPhase) }
        set(phase) { shapeLayer.lineDashPhase = CGFloat(phase) }
    }


    /// The dash pattern applied when creating the stroked version of the path. Defaults to nil.
    open var lineDashPattern: [NSNumber]? {
        get { return shapeLayer.lineDashPattern as [NSNumber]? }
        set(pattern) { shapeLayer.lineDashPattern = pattern }
    }

    /// The size of the receiver including the width of its stroke.
    /// - returns: The bounding box that surrounds the shape and its line.
    open func intrinsicContentSize() -> CGSize {
        if let path = path {
            let boundingBox = path.boundingBox()
            return CGSize(width: boundingBox.max.x + lineWidth/2, height: boundingBox.max.y + lineWidth/2)
        } else {
            return CGSize()
        }
    }

    /// Returns true if there is no path.
    open func isEmpty() -> Bool {
        return path == nil || path!.isEmpty()
    }


    /// The join style for joints on the shape's path.
    public enum LineJoin {
        /// Specifies a miter line shape of the joints between connected segments of a stroked path.
        case miter

        /// Specifies a round line shape of the joints between connected segments of a stroked path.
        case round

        /// Specifies a bevel line shape of the joints between connected segments of a stroked path.
        case bevel
    }


    /// The cap style for the ends of the shape's path.
    public enum LineCap {
        /// Specifies a butt line cap style for endpoints for an open path when stroked.
        case butt

        /// Specifies a round line cap style for endpoints for an open path when stroked.
        case round

        /// Specifies a square line cap style for endpoints for an open path when stroked.
        case square
    }

    open override func hitTest(_ point: Point) -> Bool {
        if let p = path {
            return p.containsPoint(point)
        }
        return false
    }
}
