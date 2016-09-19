//
//  ContentListViewController.swift
//  Isaacs
//
//  Created by Sebastian Florez on 9/4/16.
//  Copyright © 2016 Inspect. All rights reserved.
//

import UIKit

class ContentListViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    enum factors: CGFloat{
        case Full = 1
        case Half = 0.49
        case Double = 2
    }
    
    let types : [Int : String] = [0 : Content.types.Audio.rawValue, 1 : Content.types.Contact.rawValue, 2 : Content.types.Picture.rawValue, 3 : Content.types.Text.rawValue]
    
    var sizes = [String: (CGFloat, CGFloat)]()
    let persistence:ContentPersistence = ContentPersistence()
    var contents : [Content] = []
    var filtered : Bool = false
    
    private var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        contents = persistence.getAll(nil)
        sizes[Content.types.Audio.rawValue] = (factors.Full.rawValue, factors.Half.rawValue)
        sizes[Content.types.Contact.rawValue] = (factors.Half.rawValue, factors.Double.rawValue)
        sizes[Content.types.Picture.rawValue] = (factors.Half.rawValue, factors.Double.rawValue)
        sizes[Content.types.Text.rawValue] = (factors.Full.rawValue, factors.Double.rawValue)
        
        self.collectionView!.registerNib(UINib(nibName: "PictureCardView", bundle: nil), forCellWithReuseIdentifier: "picture_card")
        self.collectionView!.registerNib(UINib(nibName: "TextCardView", bundle: nil), forCellWithReuseIdentifier: "text_card")
        self.collectionView!.registerNib(UINib(nibName: "AudioCardView", bundle: nil), forCellWithReuseIdentifier: "audio_card")
        self.collectionView!.registerNib(UINib(nibName: "ContactCardView", bundle: nil), forCellWithReuseIdentifier: "contact_card")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Espacio entre filas de coleccion
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(5)
    }
    
    
    
    //Espacio entre celdas de coleccion
    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat{
        return CGFloat(2.5)
    }
    
    //Numero de secciones en Coleccion
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if(filtered){
            return types.count
        }
        return 1
    }
    
    //Numero de celdas en coleccion
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(filtered){
            return persistence.getAll(types[section]).count
        }
        return contents.count
    }
    
    //Render de celdas
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        var cell : UICollectionViewCell;
        let type : String = (finalContents[indexPath.row].type)!
        switch type {
            case Content.types.Picture.rawValue: cell = createPhotoCell(indexPath)
            case Content.types.Audio.rawValue: cell = createAudioCell(indexPath)
            case Content.types.Contact.rawValue: cell = createContactCell(indexPath)
            default: cell = createTextCell(indexPath)
        }
        return cell
    }
    
    //Item seleccionado
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let vc = UIStoryboard(name:"Main", bundle:nil).instantiateViewControllerWithIdentifier("story_list") as! StorySelectViewController
        vc.content = finalContents[indexPath.row]
        self.navigationController?.pushViewController(vc, animated:true)
    }
    
    //Header
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if(kind == UICollectionElementKindSectionHeader){
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "type_header", forIndexPath: indexPath) as! HeaderReusableView
            header.title.text = types[indexPath.section]!
            return header
        }
        else{
            return UICollectionReusableView()
        }
    }
    
    // Create a text cell 
    func createTextCell(indexPath: NSIndexPath) -> TextCardCollectionViewCell {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let textCell:TextCardCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("text_card", forIndexPath: indexPath) as! TextCardCollectionViewCell
        let content : Content = finalContents[indexPath.row]
        let index : Int = contents.indexOf(content)!
        textCell.delete.tag = index
        textCell.delete.addTarget(self, action: #selector(deleteCard), forControlEvents: .TouchUpInside)
        
        let jsonData = contents[indexPath.row].data ?? "No data"
        textCell.textView.text = JsonConverter.jsonToDict(jsonData)!["body"]
        
        return textCell
    }
    
    // Create Photo cell
    func createPhotoCell(indexPath: NSIndexPath) -> PictureCardCollectionViewCell {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let photoCell = collectionView.dequeueReusableCellWithReuseIdentifier("picture_card", forIndexPath: indexPath) as! PictureCardCollectionViewCell
        let content : Content = finalContents[indexPath.row]
        photoCell.delete.tag = contents.indexOf(content)!
        photoCell.delete.addTarget(self, action: #selector(deleteCard), forControlEvents: .TouchUpInside)
        
        let jsonData = finalContents[indexPath.row].data ?? "No data"
        let imageName = JsonConverter.jsonToDict(jsonData)!["image_file_name"]!
        let image = Utils.getImage(imageName)
        photoCell.image.image = image
        
        return photoCell
    }
    
    // Create Contact Cell
    func createContactCell(indexPath: NSIndexPath) -> ContactCardCollectionViewCell {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let contactCell = collectionView.dequeueReusableCellWithReuseIdentifier("contact_card", forIndexPath: indexPath) as! ContactCardCollectionViewCell
        let content : Content = finalContents[indexPath.row]
        contactCell.delete.tag = contents.indexOf(content)!
        contactCell.delete.addTarget(self, action: #selector(deleteCard), forControlEvents: .TouchUpInside)
        
        let jsonData = finalContents[indexPath.row].data ?? "No data"
        let dict = JsonConverter.jsonToDict(jsonData)!
        
        contactCell.nameLabel.text = dict["name"]
        contactCell.profilePicture.image = Utils.getImage(dict["profile_picture"]!)
        
        return contactCell
    }
    
    // Create Audio Cell
    func createAudioCell(indexPath: NSIndexPath) -> AudioCardCollectionViewCell {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let audioCell = collectionView.dequeueReusableCellWithReuseIdentifier("audio_card", forIndexPath: indexPath) as! AudioCardCollectionViewCell
        let content : Content = finalContents[indexPath.row]
        audioCell.delete.tag = contents.indexOf(content)!
        audioCell.delete.addTarget(self, action: #selector(deleteCard), forControlEvents: .TouchUpInside)
        
        let jsonData = finalContents[indexPath.row].data ?? "No data"
        let dict = JsonConverter.jsonToDict(jsonData)!
        
        audioCell.titleLabel.text = dict["title"]
        audioCell.file_name = dict["audio_file_name"]
        
        
        return audioCell
    }
    
    //Tamaño de celdas
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let finalContents : [Content]
        switch filtered{
            case true : finalContents = persistence.getAll(types[indexPath.section])
            default: finalContents = contents
        }
        let type : String = (finalContents[indexPath.row].type)!
        return CGSizeMake(collectionView.bounds.width * self.sizes[type]!.0, 100 * self.sizes[type]!.1)
    }
    
    //Tamaño de seccion
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        var size : CGSize = CGSizeMake(0,0)
        if(filtered){
            let count : Int = persistence.getAll(types[section]).count
            if(count > 0){
                size = CGSizeMake(0,40)
            }
        }
        return size
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func filter(sender: UIBarButtonItem) {
        filtered = !filtered
        switch filtered{
            case true: sender.title = "Ver todos"
            default: sender.title = "Filtrar por tipo"
        }
        collectionView.reloadData()
    }
    
    func deleteCard(sender: UIButton!){
        persistence.deleteEntity(contents[sender.tag])
        persistence.save()
        contents = persistence.getAll(nil)
        collectionView?.reloadData()
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
