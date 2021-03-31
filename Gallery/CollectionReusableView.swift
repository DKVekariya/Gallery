//
//  CollectionReusableView.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 24/03/21.
//

import UIKit

class CollectionReusableView: UICollectionReusableView {
    
    var buttonTapCallback:((Any) -> Void)?
        
    @IBOutlet weak var sectionHeaderNameLable: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    
    @IBAction func selectAllCell(_ sender: Any) {
        buttonTapCallback?(sender)
    }
}

