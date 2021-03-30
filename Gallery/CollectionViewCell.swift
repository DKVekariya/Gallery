//
//  CollectionViewCell.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 21/03/21.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectionIndecatorImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.clipsToBounds = true
    }
    
}
