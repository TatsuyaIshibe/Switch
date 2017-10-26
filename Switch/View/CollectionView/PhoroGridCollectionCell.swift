//
//  PhoroGridCollectionCell.swift
//  Switch
//
//  Created by 石部　達也 on 2017/10/09.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import UIKit
import Photos

class PhoroGridCollectionCell: UICollectionViewCell {

    static let identifier = "PhoroGridCollectionCell"
    
    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 3.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    class Delegate: Collectionable {
        
        let asset :PHAsset
        let thumnailSize :CGSize
        
        init(asset :PHAsset, thumnailSize :CGSize) {
            self.asset = asset
            self.thumnailSize = thumnailSize
        }
        
        func cellForItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
            let collectionCell: PhoroGridCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhoroGridCollectionCell.identifier, for: indexPath) as! PhoroGridCollectionCell
            PHImageManager.default().requestImage(for: asset, targetSize: thumnailSize, contentMode: .aspectFill, options: nil) { (image, _) in
                collectionCell.thumbnailImage = image
            }
            return collectionCell
        }
    }
}
