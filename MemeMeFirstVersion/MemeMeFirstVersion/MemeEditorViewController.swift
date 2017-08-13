//
//  ViewController.swift
//  MemeMeFirstVersion
//
//  Created by Jean Ro on 8/12/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var toolBar: UIToolbar!

    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    var memedImage: UIImage?
    var characterLimit: Int = textFieldLengthLimit.portrait.rawValue
    
    enum textFieldType:Int {
        case top = 1
        case bottom = 2
    }
    
    enum textFieldInitialText:String {
        case top = "TOP"
        case bottom = "BOTTOM"
    }
    
    enum textFieldLengthLimit:Int {
        case portrait = 12
        case landscape = 20
    }
    
    let memeTextAttributes:[String:Any] = [
        NSStrokeColorAttributeName: UIColor.black,
        NSForegroundColorAttributeName: UIColor.white,
        NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName: -3.0
        
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.isEnabled = false
        style(textField: topText, initialText: textFieldInitialText.top.rawValue, tag: textFieldType.top)
        style(textField: bottomText, initialText: textFieldInitialText.bottom.rawValue, tag: textFieldType.bottom)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        subscribeToKeyboardNotification()
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            characterLimit = textFieldLengthLimit.landscape.rawValue
        } else {
            characterLimit = textFieldLengthLimit.portrait.rawValue
        }
    }

    @IBAction func pickAnImageFromAlbum(_ sender: UIBarButtonItem) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }

    @IBAction func pickAnImageFromCamera(_ sender: UIBarButtonItem) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .camera
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func shareMeme(_ sender: UIBarButtonItem) {
        memedImage = generateMemedImage()
        let activityController = UIActivityViewController(activityItems: [memedImage!], applicationActivities: nil)
        activityController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            if completed {
                self.save()
            }
        }
        present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func cancelEdit(_ sender: UIBarButtonItem) {
        topText.text = textFieldInitialText.top.rawValue
        bottomText.text = textFieldInitialText.bottom.rawValue
        imageView.image = nil
        shareButton.isEnabled = false
    }
    
    func style(textField: UITextField, initialText:String, tag: textFieldType) {
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.text = initialText
        textField.tag = tag.rawValue
        textField.delegate = self
    }
    
    func keyboardWillShow(_ notification:Notification) {
        if bottomText.isFirstResponder {
            self.view.frame.origin.y = 0 - getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide() {
        self.view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    func save() {
        let meme = Meme(topText: topText.text!, bottomText: bottomText.text!, originalImage: imageView.image!, memedImage: memedImage)
    }
    
    func generateMemedImage() -> UIImage {
        toolBar.isHidden = true
        navBar.isHidden = true
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memed: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        toolBar.isHidden = false
        navBar.isHidden = false
        return memed
    }
}

extension MemeEditorViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        switch textFieldType(rawValue: textField.tag)! {
        case textFieldType.top:
            clearIfInitial(text: textFieldInitialText.top.rawValue, withCurrent: textField.text, forField: textField)
        case textFieldType.bottom:
            clearIfInitial(text: textFieldInitialText.bottom.rawValue, withCurrent: textField.text, forField: textField)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldStr = textField.text ?? ""
        let str = oldStr + string
        if str.characters.count <= characterLimit {
            return true
        }
        textField.text = str.substring(to: str.index(str.startIndex, offsetBy: characterLimit)) + "..."
        return false
    }
    
    func clearIfInitial(text:String, withCurrent:String?, forField:UITextField) {
        if let currentText = withCurrent {
            if text == currentText {
                forField.text = ""
            }
        }
    }
}

extension MemeEditorViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = pickedImage
            shareButton.isEnabled = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension MemeEditorViewController: UINavigationControllerDelegate {
    
}

