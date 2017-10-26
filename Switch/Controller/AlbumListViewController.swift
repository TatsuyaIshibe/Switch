//
//  AlbumListViewController.swift
//  Switch
//
//  Created by 石部　達也 on 2017/10/09.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import UIKit
import Photos

class AlbumListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var userCollections: PHFetchResult<PHCollection>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Switch"
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAlbum))
        self.navigationItem.rightBarButtonItem = addButton
        
        // Create a PHFetchResult object for each section in the table view.
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)

        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    @objc
    func addAlbum(_ sender: AnyObject) {
        
        let alertController = UIAlertController(title: NSLocalizedString("New Album", comment: ""), message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("Album Name", comment: "")
        }
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { action in
            let textField = alertController.textFields!.first!
            if let title = textField.text, !title.isEmpty {
                if self.checkAlbumExists(albumTitle: title) { return }
               
                // Create a new album with the title entered.
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                }, completionHandler: { success, error in
                    if !success && error != nil { print(error!) }
                })
            }
        })
        self.present(alertController, animated: true, completion: nil)
    }

    
    /**
     * 端末に指定した名称のアルバムが存在するかを戻す
     * @params albumTitle アルバム名
     * @return 存在する場合True
     */
    private func checkAlbumExists(albumTitle: String) -> Bool {
        let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype:
            PHAssetCollectionSubtype.albumRegular, options: nil)
        for i in 0 ..< albums.count {
            let album = albums.object(at: i)
            if album.localizedTitle != nil && album.localizedTitle == albumTitle {
                return true
            }
        }
        
        return false
    }

}

extension AlbumListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let collection = userCollections.object(at: indexPath.row)
        guard let assetCollection = collection as? PHAssetCollection
            else { fatalError("expected asset collection") }
        
        let destination = AlbumGridViewController()
        destination.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        destination.assetCollection = assetCollection
        
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let collection = userCollections.object(at: indexPath.row)
        cell.textLabel!.text = collection.localizedTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCollections.count
    }
    
}

// MARK: PHPhotoLibraryChangeObserver
extension AlbumListViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
                tableView.reloadData()
            }
        }
    }
}
