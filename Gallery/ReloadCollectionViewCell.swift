//
//  ReloadCollectionViewCell.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 24/03/21.
//

import UIKit

class ReloadCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var reloadButton: UIButton!
    var buttonTapCallback:((Any) -> Void)?
    var inttypr:Int?
    
    @IBAction func reloadButton(_ sender: Any) {
        buttonTapCallback?(sender)
    }

}

