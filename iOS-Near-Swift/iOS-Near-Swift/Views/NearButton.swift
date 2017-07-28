//
//  NearButton.swift
//  iOS Near Swift
//
//  Created by Francesco Leoni on 28/07/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

import UIKit
import HEXColor

class NearButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        backgroundColor = UIColor("#333333")
        layer.cornerRadius = 18
        contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
    }

}
