//
//  CollectionViewCell.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 21/03/21.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.clipsToBounds = true
    }
    
}
