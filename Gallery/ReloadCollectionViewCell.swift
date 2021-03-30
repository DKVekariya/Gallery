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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func reloadButton(_ sender: Any) {
//        activityIndicator.isHidden = false
//        activityIndicator.startAnimating()
        buttonTapCallback?(sender)
    }

}

