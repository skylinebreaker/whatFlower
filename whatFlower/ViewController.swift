//
//  ViewController.swift
//  whatFlower
//
//  Created by Bowen Shen on 5/2/18.
//  Copyright © 2018 Bowen Shen. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Constants
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            //imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Couldn't Convert UIImage into CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func getWikiData(flowerName: String) {
        
        let params : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                let dataJSON : JSON = JSON(response.result.value!)
                
                let pageid = dataJSON["query"]["pageids"][0].stringValue

                let flowerDescription = dataJSON["query"]["pages"][pageid]["extract"].stringValue
                
                self.label.text = flowerDescription
                
                let flowerImageURL = dataJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            }
            else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Load CoreML model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
//            guard let results = request.results as? [VNClassificationObservation] else {
//                fatalError("Model fails to process image")
//            }
//
//            if let firstResult = results.first {
//                print(firstResult.identifier)
//            }
            //print(request.results)
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Couldn't classify the image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized

            self.getWikiData(flowerName: classification.identifier)
        
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }

    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

