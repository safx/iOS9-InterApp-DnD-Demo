//
//  ShapeView.swift
//  ios9-dnd-demo
//
//  Created by Safx Developer on 2015/09/27.
//
//

import UIKit

protocol ShapeViewDelegate {
    func draw(rect: CGRect)
}

class ShapeView: UIView {

    var delegate: ShapeViewDelegate?

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        guard let d = delegate else { return }
        d.draw(rect)
    }
    
}

