//
//  TopAlignedLabel.swift
//  BooksList
//
//  Created by Janarthanan Mirunalini on 16/08/24.
//

import Foundation
import UIKit

class TopAlignedLabel: UILabel {

    override func drawText(in rect: CGRect) {
        // Calculate the size needed for the text
        let textRect = super.textRect(forBounds: rect, limitedToNumberOfLines: self.numberOfLines)
        
        // Create a new rect to position the text at the top of the label
        let topAlignedRect = CGRect(x: rect.origin.x,
                                    y: rect.origin.y,
                                    width: rect.size.width,
                                    height: textRect.size.height)
        
        // Call the super method to draw the text in the adjusted rect
        super.drawText(in: topAlignedRect)
    }
}
