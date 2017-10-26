//
//  PhotoGridAddCollectionCell.swift
//  Switch
//
//  Created by 石部　達也 on 2017/10/09.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import UIKit

protocol PhotoGridAddCollectionCellDelegate: class {
    func didSelectAddButton()
}

class PhotoGridAddCollectionCell: UICollectionViewCell {

    static let identifier = "PhotoGridAddCollectionCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 3.0
        self.layer.backgroundColor = UIColor.gray.cgColor
    }
    
    class Delegate: Collectionable {
        /// デリゲート
        weak var controller: PhotoGridAddCollectionCellDelegate?

        init(controller :PhotoGridAddCollectionCellDelegate?) {
            self.controller = controller
        }
        
        func cellForItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
            let collectionCell: PhotoGridAddCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridAddCollectionCell.identifier, for: indexPath) as! PhotoGridAddCollectionCell
            return collectionCell
        }
        
        func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
            controller?.didSelectAddButton()
        }
    }
}
