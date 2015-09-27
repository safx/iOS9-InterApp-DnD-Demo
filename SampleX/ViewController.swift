//
//  ViewController.swift
//  SampleX
//
//  Created by Safx Developer on 2015/09/27.
//
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var bundleLabel: UILabel! {
        didSet { bundleLabel.text = myID.componentsSeparatedByString(".").last }
    }
    @IBOutlet weak var otherLabel: UILabel!

    private var queue: dispatch_queue_t!
    private var timer: dispatch_source_t!

    private var model: [Shape] = []
    private var draggingModelIndex: Int = -1
    private var dragOffset: CGPoint! = CGPointZero
    private var modelOfOtherProcess: Shape?

    private lazy var myPasteboard: UIPasteboard = {
        return UIPasteboard(name: self.myID, create: true)!
    }()

    private var myID: String = NSBundle.mainBundle().bundleIdentifier!

    private lazy var otherID: String = {
        return self.myID == "com.blogspot.safx-dev.SampleX" ? "com.blogspot.safx-dev.SampleY" : "com.blogspot.safx-dev.SampleX"
    }()

    deinit {
        UIPasteboard.removePasteboardWithName(myID)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        (view as! ShapeView).delegate = self

        if myID == "com.blogspot.safx-dev.SampleX" {
            model.append(.Rectangle(pos: CGPointMake(80, 280), size: CGSizeMake(80, 80), color: UIColor.blueColor()))
            model.append(.Ellipse(pos: CGPointMake(20, 220), size: CGSizeMake(50, 50), color: UIColor.redColor()))
        } else {
            model.append(.Rectangle(pos: CGPointMake(80, 320), size: CGSizeMake(50, 50), color: UIColor.greenColor()))
            model.append(.Ellipse(pos: CGPointMake(20, 220), size: CGSizeMake(80, 80), color: UIColor.cyanColor()))
        }

        queue = myID.withCString { dispatch_queue_create($0, nil) }
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        dispatch_source_set_timer(timer, dispatch_time_t(DISPATCH_TIME_NOW), USEC_PER_SEC * 50, 0)
        dispatch_source_set_event_handler(timer) { () -> Void in
            self.updateModelOfOtherProcess()
        }
        dispatch_resume(timer)
    }

    private func updateModelOfOtherProcess() {
        assert(NSThread.mainThread() != NSThread.currentThread())

        if let otherpb = UIPasteboard(name: otherID, create: false), s = otherpb.string where !s.isEmpty {
            otherpb.string = ""

            let ss = s.componentsSeparatedByString(",")
            switch (ss[0], ss.count) {
            case ("B", 7): // touchBegan
                let size = ss[2...3].flatMap{Int($0)}.flatMap{CGFloat($0)}
                let offset = ss[5...6].flatMap{Int($0)}.flatMap{CGFloat($0)}
                if let shape = Shape.createShape(ss[1], size: CGSizeMake(size[0], size[1]), color: ss[4]) {
                    modelOfOtherProcess = shape
                    dragOffset = CGPointMake(offset[0], offset[1])
                }
            case ("M", 3): // touchMoved
                if modelOfOtherProcess == nil { return }
                let ns = ss[1...2].flatMap{Int($0)}.flatMap{CGFloat($0)}
                let x = ns[0]
                let p = CGPointMake(x >= 0 ? x : view.frame.size.width + x, ns[1])
                modelOfOtherProcess!.changePosition(CGPointMake(dragOffset.x + p.x, dragOffset.y + p.y))
            case ("O", 1): // touchMoved but model is still contained in other view
                if modelOfOtherProcess == nil { return }
                let p = CGPointMake(-10000, -10000) // FIXME
                modelOfOtherProcess!.changePosition(p)
            case ("E", 1): // touchEnded
                if modelOfOtherProcess == nil { return }
                model.append(modelOfOtherProcess!)
                modelOfOtherProcess = nil
            case ("C", 1): fallthrough // touchCancelled
            default:
                modelOfOtherProcess = nil
            }

            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.otherLabel.text = s
                self.view.setNeedsDisplay()
            }
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        let p = touches.first!.locationInView(view)
        for (idx, e) in model.enumerate() {
            if e.isClicked(p) {
                draggingModelIndex = idx
                let m = model[draggingModelIndex]

                dragOffset = CGPointMake(m.position.x - p.x, m.position.y - p.y)

                myPasteboard.string = "B,\(m.string),\(Int(dragOffset.x)),\(Int(dragOffset.y))"
                return
            }
        }
        draggingModelIndex = -1
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)

        if 0 > draggingModelIndex || draggingModelIndex >= model.count { return }

        let p = touches.first!.locationInView(view)
        model[draggingModelIndex].changePosition(CGPointMake(dragOffset.x + p.x, dragOffset.y + p.y))

        let f = view.frame
        if p.x < f.minX {
            myPasteboard.string = "M,\(Int(p.x-0.5)),\(Int(p.y))"
        } else if f.maxX <= p.x {
            myPasteboard.string = "M,\(Int(p.x-f.maxX)),\(Int(p.y))"
        } else {
            myPasteboard.string = "O"
        }
        view.setNeedsDisplay()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        myPasteboard.string = "C"
        draggingModelIndex = -1
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if 0 > draggingModelIndex || draggingModelIndex >= model.count { return }

        let p = touches.first!.locationInView(view)
        model[draggingModelIndex].changePosition(CGPointMake(dragOffset.x + p.x, dragOffset.y + p.y))

        if view.frame.contains(p) {
            myPasteboard.string = "C"
        } else {
            myPasteboard.string = "E"
            model.removeAtIndex(draggingModelIndex)
        }
        view.setNeedsDisplay()

        draggingModelIndex = -1
    }

    override func viewDidLayoutSubviews() {
        view.setNeedsDisplay()
    }
}

extension ViewController: ShapeViewDelegate {
    func draw(rect: CGRect) {
        model.forEach { $0.draw() }
        modelOfOtherProcess?.draw()
    }
}
