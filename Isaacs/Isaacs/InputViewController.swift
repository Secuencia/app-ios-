//
//  InputViewController.swift
//  Isaacs
//
//  Created by Nicolas Chaves on 9/13/16.
//  Copyright © 2016 Inspect. All rights reserved.
//

import UIKit

class InputViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {

    
    // MARK: Properties - Interface
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var picker: UIImagePickerController!
    
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    var toolbarBottomConstraintInitialValue: CGFloat?
    
    var availableModules = ["Text", "Camera", "Gallery", "Record", "Contact", "Completed"]
    
    // MARK: Properties - State vars
    
    
    var globalImageStatus: String?
    
    var contactIndexPath: NSIndexPath?
    
    var entryModule: Int?
    
    var isInEditingMode = false
    
    var editedContentIndex: Int?
    
    var lastlyEditedContent: Int?
    
    let persistenceContext = ContentPersistence()
    
    
    // MARK: Properties - Logic
    
    enum SelectedBarButtonTag: Int {
        case Text
        case Camera
        case Gallery
        case Audio
        case Contact
        case Completed
    }
    
    enum Modules: Int {
        case Text
        case Photo
        case Audio
        case Contact
    }
    
    var modulesTypes = [Int]()
    
    var contents = [Content]()
    
    var images = [UIImage]()
    
    var imagesTuples = [(Int, UIImage, String)]()
    
    var audioTuples = [(Int, String, String)]()
    
    var historias = ["Pepita", "Sutana", "Menguana"]
    
    
    // MARK: Program entry point
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.whiteColor()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        navigationBar.topItem?.title = "Entry Session"
        navigationBar.barStyle = UIBarStyle.Black
        navigationBar.tintColor = UIColor.whiteColor()
        
        tableView.registerNib(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "photo_cell")
        tableView.registerNib(UINib(nibName: "TextTableViewCell", bundle: nil), forCellReuseIdentifier: "text_cell")
        tableView.registerNib(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contact_cell")
        tableView.registerNib(UINib(nibName: "AudioTableViewCell", bundle: nil), forCellReuseIdentifier: "audio_cell")
        
        self.toolbarBottomConstraintInitialValue = toolbarBottomConstraint.constant
        enableKeyboardHideOnTap()
        
        if let entryAction = entryModule{
            print("LLEGA HASTA ACA")
            manageAction(entryAction)
        }
        
        
    }
    
    
    // MARK: Table View Actions
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch modulesTypes[indexPath.section] {
        case Modules.Text.rawValue: return createTextCell(indexPath)
        case Modules.Photo.rawValue: return createPhotoCell(indexPath)
        case Modules.Audio.rawValue: return createAudioCell(indexPath)
        case Modules.Contact.rawValue: return createContactCell(indexPath)
        default: return createTextCell(indexPath)
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return modulesTypes.count
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch modulesTypes[indexPath.section] {
        case Modules.Text.rawValue: return 120.0
        case Modules.Photo.rawValue: return 160.0
        case Modules.Audio.rawValue: return 80.0
        case Modules.Contact.rawValue: return 160.0
        default: return 80.0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch modulesTypes[indexPath.section] {
        case Modules.Text.rawValue: return 120.0
        case Modules.Photo.rawValue: return 160.0
        case Modules.Audio.rawValue: return 80.0
        case Modules.Contact.rawValue: return 160.0
        default: return 80.0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Cell selected: ")
        print(indexPath.section)
    }
    
    
    
    // MARK: Cell creation
    
    func createTextCell(indexPath: NSIndexPath) -> TextTableViewCell {
        
        let textCell = tableView.dequeueReusableCellWithIdentifier("text_cell", forIndexPath: indexPath) as! TextTableViewCell
    
        
        if indexPath.section == editedContentIndex && editing {
            textCell.myText.becomeFirstResponder()
        }else if lastlyEditedContent == indexPath.section{
            textCell.beingEdited = false
            textCell.userInteractionEnabled = false
            if textCell.myText.isFirstResponder() {textCell.myText.resignFirstResponder()}
        }
        
        return textCell
    }
    
    
    func createPhotoCell(indexPath: NSIndexPath) -> PhotoTableViewCell {
        
        let photoCell = tableView.dequeueReusableCellWithIdentifier("photo_cell", forIndexPath: indexPath) as! PhotoTableViewCell
        
        for (_, value) in imagesTuples.enumerate() {
            
            if value.0 == indexPath.section {
                let tuple = value
                photoCell.photoView.image = tuple.1
                photoCell.titleLabel.text = tuple.2
                break
            }
        
        }
        
        if indexPath.section == editedContentIndex && editing {
            photoCell.notesTextView.becomeFirstResponder()
        }else{
            photoCell.beingEdited = false
            photoCell.userInteractionEnabled = false
            if photoCell.notesTextView.isFirstResponder() {photoCell.notesTextView.resignFirstResponder()}
        }
        
        return photoCell
        
    }
    
    
    func createContactCell(indexPath: NSIndexPath) -> ContactTableViewCell {
        
        let contactCell = tableView.dequeueReusableCellWithIdentifier("contact_cell", forIndexPath: indexPath) as! ContactTableViewCell
        
        contactCell.pictureButton.tag = indexPath.section
        contactCell.pictureButton.addTarget(self, action: #selector(addContactImage), forControlEvents: .TouchUpInside)
        
        if indexPath.section == editedContentIndex && editing {
            contactCell.nameTextField.becomeFirstResponder()
        }else if lastlyEditedContent == indexPath.section {
            contactCell.beingEdited = false
            contactCell.userInteractionEnabled = false
            if contactCell.nameTextField.isFirstResponder() {contactCell.nameTextField.resignFirstResponder()}
        }
        
        return contactCell
        
    }
    
    func createAudioCell(indexPath: NSIndexPath) -> AudioTableViewCell {
        let audioCell = tableView.dequeueReusableCellWithIdentifier("audio_cell", forIndexPath: indexPath) as! AudioTableViewCell
        
        for (_, value) in audioTuples.enumerate() {
            
            if value.0 == indexPath.section {
                let tuple = value
                audioCell.file_name = tuple.1
                audioCell.titleLabel.text = tuple.1
                break
            }
            
        }
        

        return audioCell
    }
    
    func addContactImage(sender: UIButton!) {
        globalImageStatus = "contact"
        contactIndexPath = NSIndexPath(forRow: 0, inSection: sender.tag)
        print("Entre a foto de contacto")
        
        picker = UIImagePickerController()
        picker.delegate = self
        
        picker.sourceType = .PhotoLibrary
    
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    
    
    // MARK: Collection View Action
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionItem = collectionView.dequeueReusableCellWithReuseIdentifier("item", forIndexPath: indexPath) as! ModuleCollectionViewCell
        
        collectionItem.moduleName.tag = indexPath.row
        collectionItem.moduleName.backgroundColor = UIColor.clearColor()
        collectionItem.moduleName.setImage(UIImage(named: availableModules[indexPath.row]), forState: .Normal)
        collectionItem.moduleName.addTarget(self, action: #selector(buttonSelected), forControlEvents: .TouchUpInside)
        collectionItem.moduleName.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        collectionItem.moduleName.tintColor = UIColor.darkGrayColor()
        
        
        return collectionItem
    }
    
    
    func buttonSelected(sender: UIButton!){
        
        manageAction(sender.tag)
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableModules.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    
    
    // MARK: Logic
    
    func manageAction(action: Int) {
        
        saveCurrentlyEditingContent()
        
        switch action {
        case SelectedBarButtonTag.Text.rawValue: insertText()
        case SelectedBarButtonTag.Camera.rawValue: insertPicture("camera")
        case SelectedBarButtonTag.Gallery.rawValue: insertPicture("gallery")
        case SelectedBarButtonTag.Audio.rawValue: insertAudio()
        case SelectedBarButtonTag.Contact.rawValue: insertContact()
        default: saveCurrentlyEditingContent()
        }
        
    }
    
    func insertText() {
        
        let newContent = ContentPersistence().createEntity(); newContent.type = Content.types.Text.rawValue
        contents.append(newContent)
        editing = true
        editedContentIndex = contents.count - 1
        print("New content index: ", editedContentIndex)
        
        modulesTypes.append(Modules.Text.rawValue)
        tableView.reloadData()
    }
    
    func insertPicture(media: String) {
        
        let newContent = ContentPersistence().createEntity(); newContent.type = Content.types.Picture.rawValue
        
        contents.append(newContent)
        editing = true
        editedContentIndex = contents.count - 1
        modulesTypes.append(Modules.Photo.rawValue)

        
        picker = UIImagePickerController()
        picker.delegate = self
        
        if media == "camera" {
            picker.sourceType = .Camera
        } else {
            picker.sourceType = .PhotoLibrary
        }
        
        globalImageStatus = "photo"
        
        
        presentViewController(picker, animated: true, completion: nil)
    }
    


    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        print(info)
        
        if globalImageStatus == "photo" {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                print("NUMBER OF SECTIONS", tableView.numberOfSections)
                print("New content index: ", editedContentIndex)
            
                
                print("GENERATING ROUTE")
                
                let name = NSDate().iso8601 + ".png"
                
                let imageName = saveImageToDirectory(image, imageName: name)
                print(imageName)
                let loadedImage = getImage(imageName)!
                print(loadedImage)
                
                print("END OF PERSISTENCE")
                
                imagesTuples.append((editedContentIndex!, loadedImage, name))

                
                //images.append(loadedImage)
                
                globalImageStatus = nil
                

            }else{
                print("Something went wrong")
            }
            globalImageStatus = nil
        } else {
            
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                //let name = NSDate().iso8601 + "-contact.png"
                
                //let imageName = saveImageToDirectory(image, imageName: name)
                //let loadedImage = getImage(imageName)!
                
                
                //imagesTuples.append((editedContentIndex!, loadedImage, name))
                
                let cell = tableView.cellForRowAtIndexPath(contactIndexPath!) as! ContactTableViewCell
                
                cell.profilePicture.image = image
                
                globalImageStatus = nil
                
                contactIndexPath = nil
                
            }else{
                print("Something went wrong")
            }

            
            globalImageStatus = nil
            contactIndexPath = nil
        }
        
        tableView.reloadData()
        
        picker.dismissViewControllerAnimated(true, completion: nil)
        
    }
 
    
    func insertAudio() {
        let newContent = ContentPersistence().createEntity(); newContent.type = Content.types.Audio.rawValue
        contents.append(newContent)
        editing = true
        editedContentIndex = contents.count - 1
        print("New content index: ", editedContentIndex)
        

        audioTuples.append((editedContentIndex!, NSDate().iso8601, "hola"))
        
        modulesTypes.append(Modules.Audio.rawValue)
        tableView.reloadData()
    }
    
    func insertContact() {
        
        let newContent = ContentPersistence().createEntity(); newContent.type = Content.types.Contact.rawValue
        contents.append(newContent)
        editing = true
        editedContentIndex = contents.count - 1
        print("New content index: ", editedContentIndex)
        
        modulesTypes.append(Modules.Contact.rawValue)
        tableView.reloadData()
        
    }
    
    
    
    // MARK: Content
    
    func saveCurrentlyEditingContent() {
        
        if let index = editedContentIndex {
            var json: String?
            switch contents[index].type! {
                case Content.types.Text.rawValue: json = createDictForText()
                case Content.types.Picture.rawValue: json = createDictForPhoto()
                case Content.types.Audio.rawValue: json = createDictForAudio()
                case Content.types.Contact.rawValue: json = createDictForContact()
                default: json = nil
            }
            print("ESTE ES EL JSON: ",json)
            contents[index].data = json
            persistenceContext.save()
            
            editing = false
            lastlyEditedContent = editedContentIndex
            editedContentIndex = nil
        }
        
    }
    
    func createDictForText() -> String {
        let bodyText = ((tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: editedContentIndex!)) as? TextTableViewCell)?.myText.text)!
        let dict: [String: String] = ["title":"titulo por defecto", "body":bodyText,"otra propiedad":"nueva propiedad"]
        let json: String = JsonConverter.dictToJson(dict)
        return json
    }
    
    func createDictForPhoto() -> String {
        let cell = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: editedContentIndex!)) as? PhotoTableViewCell)!
        let dict: [String: String] = ["title":"Default", "notes":cell.notesTextView.text,"image_file_name":cell.titleLabel.text!]
        let json: String = JsonConverter.dictToJson(dict)
        return json
    }
    
    func createDictForAudio() -> String {
        //let cell = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: editedContentIndex!)) as? AudioTableViewCell)!
        let dict: [String: String] = ["title":getContentNameFromIndex(editedContentIndex!, type: "audio"), "audio_file_name":getAudioFileName(editedContentIndex!)]
        let json: String = JsonConverter.dictToJson(dict)
        return json
    }
    
    func createDictForContact() -> String {
        let cell = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: editedContentIndex!)) as? ContactTableViewCell)!
        let name = NSDate().iso8601+"-contact.png"
        saveImageToDirectory(cell.profilePicture.image!, imageName: name)
        let dict: [String: String] = ["name":cell.nameTextField.text!, "aditional_info":cell.additionalInfoText.text, "profile_picture": name]
        let json: String = JsonConverter.dictToJson(dict)
        return json
    }
    
    
    // MARK: End of session actions
    
    
    @IBAction func saveSession(sender: UIBarButtonItem) {
        saveCurrentlyEditingContent()
        
        print("This is the data of the session")
        print(modulesTypes)
        print(contents)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelSession(sender: UIBarButtonItem) {
        
        for (_, value) in contents.enumerate() {
            persistenceContext.deleteEntity(value)
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Actions to keep toolbar sticked to keyboard
    
    private func enableKeyboardHideOnTap(){
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InputViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil) // See
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InputViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil) //See 4.2
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(InputViewController.hideKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        UIView.animateWithDuration(duration) { () -> Void in
            self.toolbarBottomConstraint.constant = keyboardFrame.size.height + 5
            self.view.layoutIfNeeded()
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        UIView.animateWithDuration(duration) { () -> Void in
            self.toolbarBottomConstraint.constant = self.toolbarBottomConstraintInitialValue!
            self.view.layoutIfNeeded()
            
        }
        
    }
    
    // MARK: Utility actions
    
    
    func saveImageToDirectory(image:UIImage, imageName: String) -> String {
        let fileManager = NSFileManager.defaultManager()
        let imageData = NSData(data:UIImagePNGRepresentation(image)!)
        let paths = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString).stringByAppendingPathComponent(imageName)
        fileManager.createFileAtPath(paths as String, contents: imageData, attributes: nil)
        return imageName
    }
    
    func getImage(imageName: String) -> UIImage?{
        let fileManager = NSFileManager.defaultManager()
        let imagePath = (self.getDirectoryPath() as NSString).stringByAppendingPathComponent(imageName)
        if fileManager.fileExistsAtPath(imagePath) {
            return UIImage(contentsOfFile: imagePath)
        }else{
            return nil
        }
    }
    
    func getDirectoryPath() -> String{
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDir = paths[0]
        return documentsDir
    }
    
    func getContentNameFromIndex(index: Int, type: String) -> String {
        if type == "image" {
            for (_, value) in imagesTuples.enumerate() {
                if value.0 == index {
                    return "Imagen - " + (imagesTuples[index].2).componentsSeparatedByString(".")[0]
                }
            }
        } else {
            for (_, value) in audioTuples.enumerate() {
                if value.0 == index {
                    return "Audio - " + (value.1).componentsSeparatedByString(".")[0]
                }
            }
        }
        return ""
    }
    
    func getAudioFileName(index: Int) -> String {
        for (_, value) in audioTuples.enumerate() {
            if value.0 == index {
                return value.1
            }
        }
        return ""
    }
    
    
}

extension NSDate {
    struct Formatter {
        static let iso8601: NSDateFormatter = {
            let formatter = NSDateFormatter()
            formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
            formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
            return formatter
        }()
    }
    var iso8601: String { return Formatter.iso8601.stringFromDate(self) }
}

extension String {
    var dateFromISO8601: NSDate? {
        return NSDate.Formatter.iso8601.dateFromString(self)
    }
}
