//
//  AlbumGridViewController.swift
//  Switch
//
//  Created by 石部　達也 on 2017/10/09.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import UIKit
import Photos
import OpalImagePicker
import AVFoundation
import ImageIO
import MobileCoreServices

class AlbumGridViewController: UIViewController {

    internal struct CameraViewSize {
        let width: CGFloat
        let height: CGFloat
        let topBlackHeight: CGFloat
        let bottomBlackHeight: CGFloat
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    var fetchResult: PHFetchResult<PHAsset>!
    var assetCollection: PHAssetCollection!
    let thumnailSize = CGSize(width: (UIScreen.main.bounds.size.width / 2) - 10, height: (UIScreen.main.bounds.size.width / 2) - 10)
    let boundsSize = UIScreen.main.bounds.size
    let instaSize = CGSize(width:1080.0, height:1080.0)
    
    var baseImage :UIImage?
    
    var cells = [Collectionable]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.shared().register(self)
        
        collectionView.register(UINib.init(nibName: PhoroGridCollectionCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhoroGridCollectionCell.identifier)
        collectionView.register(UINib.init(nibName: PhotoGridAddCollectionCell.identifier, bundle: nil), forCellWithReuseIdentifier: PhotoGridAddCollectionCell.identifier)
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.showActionBoard))
        self.navigationItem.rightBarButtonItem = addButton
        
        
        // If we get here without a segue, it's because we're visible at app launch,
        // so match the behavior of segue from the default "All Photos" view.
        if fetchResult == nil {
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        }
        
        createCells()
    }
    
    private func createCells() {
        cells = [Collectionable]()
        
        for i in 0 ..< fetchResult.count { 
            let asset = fetchResult.object(at: i)
            cells.append(PhoroGridCollectionCell.Delegate(asset: asset, thumnailSize: thumnailSize))
        }
        
        cells.append(PhotoGridAddCollectionCell.Delegate(controller: self))
        
        collectionView.reloadData()
    }
    
    @objc
    func showActionBoard() {
        let imagePicker = OpalImagePickerController()
        imagePicker.imagePickerDelegate = self
        present(imagePicker, animated: true, completion: nil)
    }
}

extension AlbumGridViewController: PhotoGridAddCollectionCellDelegate {
    func didSelectAddButton() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "カメラを起動する", style: .default, handler: { (action) in
            self.showCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "写真を選択する", style: .default, handler: { (action) in
            self.showImagePicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func showCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        if let asset = fetchResult.lastObject {
            let size = self.calculateCameraFrame()
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize.init(width: size.width, height: size.height), contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
                let imageView = UIImageView(frame: CGRect(x: 0, y: size.bottomBlackHeight +  44, width: size.width, height: size.height))
                imageView.image = image
                imageView.alpha = 0.5
                self.baseImage = image
                picker.cameraOverlayView = imageView
            })
        }
        picker.allowsEditing = true
        picker.cameraViewTransform = CGAffineTransform.init(translationX: 0, y: 44)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func showImagePicker() {
//        let imagePicker = OpalImagePickerController()
//        imagePicker.imagePickerDelegate = self
//        present(imagePicker, animated: true, completion: nil)
    }
    
    private func calculateCameraFrame() -> CameraViewSize {
        let screenWidth = UIScreen.main.bounds.size.width
        let previewHeight = screenWidth + (screenWidth / 3)
        let totalBlack = UIScreen.main.bounds.size.height - previewHeight
        let heightBlackTopAndBottom = totalBlack / 4 + 1
        return CameraViewSize(width: screenWidth, height: previewHeight, topBlackHeight: heightBlackTopAndBottom, bottomBlackHeight: heightBlackTopAndBottom)
    }
}

extension AlbumGridViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cells[indexPath.item].didSelect(collectionView: collectionView, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       return cells[indexPath.item].cellForItem(collectionView:collectionView, indexPath:indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return thumnailSize
    }
}

extension AlbumGridViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image = info[UIImagePickerControllerOriginalImage] as! UIImage
        // 撮影した画像をカメラロールに保存
//        let imgRef = image.cgImage?.cropping(to: CGRect(x: 540, y: 540, width: 1080, height: 1080))
//        let resizeImg = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)

//        if let notNilImage = baseImage {
//            image = synthesizeImage(images: [image, notNilImage.createTransparentImage()], size: image.size)
//        }
        
        saveImageToSwitchAlbum(image: image)

        dismiss(animated: true, completion: nil)
    }
    
    func synthesizeImage(images: Array<UIImage>, size: CGSize) -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        images.forEach{
            $0.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage!
    }
    
    private func saveImageToSwitchAlbum(image :UIImage) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            
            if self.assetCollection.estimatedAssetCount == 0 {
                albumChangeRequest!.addAssets(enumeration)
            }else {
                albumChangeRequest!.insertAssets(enumeration, at: [0])
            }
        }, completionHandler: { status , errror in
            print("error")
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print(#function)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension AlbumGridViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: fetchResult) {
                fetchResult = changeDetails.fetchResultAfterChanges
                self.createCells()
            }
        }
    }
}

extension AlbumGridViewController: OpalImagePickerControllerDelegate {
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        makeGifImage(images: images)
        dismiss(animated: true, completion: nil)
    }
    
    private func makeGifImage(images: [UIImage]) {
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.1]]
        
        let documentsDirectory = NSHomeDirectory() + "/Documents"
        let fileName = String(Int(Date().timeIntervalSince1970)) + ".gif"
        let url = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(fileName)
        
        if let url = url {
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, images.count, nil) else {
                return
            }
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            images.forEach{ CGImageDestinationAddImage(destination, $0.cgImage!, frameProperties as CFDictionary)}
            
            if CGImageDestinationFinalize(destination) {
                print("success")
                saveToGifSwitchAlbum(url: url)
            } else {
                print("failed")
            }
        } else  {
            print("failed")
        }
    }
    
    private func saveToGifSwitchAlbum(url :URL) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Switch")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let assetCollection: PHAssetCollection = collection.firstObject else {
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            guard let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url) else {
                return
            }
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            
            if assetCollection.estimatedAssetCount == 0 {
                albumChangeRequest!.addAssets(enumeration)
            }else {
                albumChangeRequest!.insertAssets(enumeration, at: [0])
            }
        }) { (bool, error) in
            print(error)
        }
    }
    
//    private func showGif(url :URL) {
//        //urlをNSDataに変換
//        do {
//            let gifData = try Data(contentsOf: url)
//            //gifをloadする
//            webView.load(gifData, mimeType: "image/gif", textEncodingName: "utf-8", baseURL: url)
//        } catch {
//            return
//        }
//    }
}

extension UIImage {
    
    func createTransparentImage() -> UIImage {
        let rect = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(self.size,false,0);
        self.draw(in: rect, blendMode: .copy, alpha: 0.5)
        let blendedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return blendedImage!
    }
}
