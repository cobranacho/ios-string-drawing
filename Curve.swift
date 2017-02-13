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

///  Curve is a concrete subclass of Shape that has a special initialzer that creates an bezier whose shape is defined by its end points and two control points.
open class Curve: Shape {

    /// The beginning and end points of the receiver. Animatable.
    open var endPoints = (Point(), Point()) {
        didSet {
            updatePath()
        }
    }

    /// The control points of the receiver. Animatable.
    open var controlPoints = (Point(), Point()) {
        didSet {
            updatePath()
        }
    }

    /// The center of the curve's view.
    open override var center: Point {
        get {
            return Point(view.center)
        }
        set {
            let diff = newValue - center
            batchUpdates() {
                self.endPoints.0 += diff
                self.endPoints.1 += diff
                self.controlPoints.0 += diff
                self.controlPoints.1 += diff
            }
        }
    }

    /// The origin of the curve's view.
    open override var origin: Point {
        get {
            return Point(view.frame.origin)
        }
        set {
            let diff = newValue - origin
            batchUpdates() {
                self.endPoints.0 += diff
                self.endPoints.1 += diff
                self.controlPoints.0 += diff
                self.controlPoints.1 += diff
            }
        }
    }

    /// Creates a bezier curve.
    ///
    /// ````
    /// let crv = Curve(a: Point(), b: Point(0,50), c: Point(100,50), d: Point(100,0))
    /// ````
    ///
    /// - parameter begin:    The beginning point of the curve.
    /// - parameter control0: The first control point used to define the shape of the curve.
    /// - parameter control1: The second control point used to define the shape of the curve.
    /// - parameter end:      The end point of the curve.
    convenience public init(begin: Point, control0: Point, control1: Point, end: Point) {
        self.init()
        endPoints = (begin, end)
        controlPoints = (control0, control1)
        updatePath()
    }

    fileprivate var pauseUpdates = false
    func batchUpdates(_ updates: (Void) -> Void) {
        pauseUpdates = true
        updates()
        pauseUpdates = false
        updatePath()
    }

    override func updatePath() {
        if pauseUpdates {
            return
        }

        let curve = CGMutablePath()
        CGPathMoveToPoint(curve, nil,
            CGFloat(endPoints.0.x), CGFloat(endPoints.0.y))
        CGPathAddCurveToPoint(curve, nil,
            CGFloat(controlPoints.0.x), CGFloat(controlPoints.0.y),
            CGFloat(controlPoints.1.x), CGFloat(controlPoints.1.y),
            CGFloat(endPoints.1.x), CGFloat(endPoints.1.y))

        self.frame = Rect(curve.boundingBox)
        self.path = Path(path: curve)
        adjustToFitPath()
    }
}
