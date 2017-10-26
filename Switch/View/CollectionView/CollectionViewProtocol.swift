//
//  CollectionViewProtocol.swift
//  Switch
//
//  Created by 石部　達也 on 2017/10/09.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import Foundation
import UIKit

protocol Collectionable {
    func cellForItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) -> Void
    func sizeForItemAtIndexPath(collectionView: UICollectionView,  indexPath: IndexPath) -> CGSize
}

extension Collectionable  {
    func cellForItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func sizeForItemAtIndexPath(collectionView: UICollectionView,  indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        return CGSize.init(width: width, height: height)
    }
}

