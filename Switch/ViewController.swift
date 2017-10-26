//
//  ViewController.swift
//  Switch
//
//  Created by 石部　達也 on 2017/09/24.
//  Copyright © 2017年 石部　達也. All rights reserved.
//

import UIKit
import OpalImagePicker
import ImageIO
import MobileCoreServices
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createNewAlbum(albumTitle: "Switch") { (isSuccess) in
            if isSuccess { print("成功") }
            else { print("失敗") }
        }
    }
    
    @IBAction func didSelectCameraButton(_ sender: Any) {
        
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
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    private func showImagePicker() {
        let imagePicker = OpalImagePickerController()
        imagePicker.imagePickerDelegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    /**
     * 端末に指定した名称のアルバムを作成する
     * ただし既に同名のアルバムが存在する場合は作成しない
     * @params albumTitle アルバム名
     * @params callback   アルバム生成後に呼び出されるコールバック
     */
    private func createNewAlbum(albumTitle: String, callback: @escaping (Bool) -> Void) {
        if self.checkAlbumExists(albumTitle: albumTitle) {
            callback(true)
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
            }) { (isSuccess, error) in
                callback(isSuccess)
            }
        }
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


extension ViewController:  UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        // 撮影した画像をカメラロールに保存
        saveImageToSwitchAlbum(image: image)
        dismiss(animated: true, completion: nil)
    }
    
    private func saveImageToSwitchAlbum(image :UIImage) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Switch")
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        guard let assetCollection: PHAssetCollection = collection.firstObject else {
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            
            if assetCollection.estimatedAssetCount == 0 {
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

extension ViewController: OpalImagePickerControllerDelegate {
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        makeGifImage(images: images)
        dismiss(animated: true, completion: nil)
    }
    
    private func makeGifImage(images: [UIImage]) {
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0.1]]
        
        let documentsDirectory = NSHomeDirectory() + "/Documents"
        let url = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent("animated.gif")
        
        if let url = url {
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, images.count, nil) else {
                return
            }
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            images.forEach{ CGImageDestinationAddImage(destination, $0.cgImage!, frameProperties as CFDictionary)}
            
            if CGImageDestinationFinalize(destination) {
                print("success")
                showGif(url: url)
                saveToGitSwitchAlbum(url: url)
            } else {
                print("failed")
            }
        } else  {
            print("failed")
        }
    }
    
    private func saveToGitSwitchAlbum(url :URL) {
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
        }, completionHandler: nil)
    }
    
    private func showGif(url :URL) {
        //urlをNSDataに変換
        do {
            let gifData = try Data(contentsOf: url)
            //gifをloadする
            webView.load(gifData, mimeType: "image/gif", textEncodingName: "utf-8", baseURL: url)
        } catch {
            return
        }
    }
}
