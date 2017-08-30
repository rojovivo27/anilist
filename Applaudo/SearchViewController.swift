//
//  SearchViewController.swift
//  Applaudo
//
//  Created by Aldo on 30/08/17.
//  Copyright © 2017 Aldo. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher

class SearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var seriesArr = [Series]()
    var id = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func makeRequest(query: String){
        
        seriesArr = [Series]()
        
        //Web request
        let urlSeries = "\(Utilities.sharedInstance.URLPrefix)\(Utilities.sharedInstance.type)/search/\(query)"
        let parametersSeries: Parameters = [
            "access_token": Utilities.sharedInstance.access_token
        ]
        
        Alamofire.request(urlSeries, method: .get, parameters: parametersSeries).responseJSON { response in
            if let data = response.data {
                let json = JSON(data)
                
                if(json["error"] != JSON.null){
                    let alert = UIAlertController(title: "No results", message: "Try a different search", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                for index in 0 ..< json.count {
                    
                    let id = json[index,"id"].intValue
                    let title_english = json[index,"title_english"].string ?? ""
                    //let type = json[index,"type"].string ?? ""
                    let image_url_med = json[index,"image_url_med"].string ?? ""
                    let genresArr = json[index,"genres"].arrayValue
                    var genres = ""
                    if (genresArr.count > 0) {
                        let genresT = genresArr.reduce("", { x, y in
                            "\(x), \(y)"
                        })
                        let index = genresT.index(genresT.startIndex, offsetBy: 2)
                        genres = genresT.substring(from: index)
                    }
                    
                    let series = Series(id: id, title_english: title_english, image_url_med: image_url_med, genres: genres)
                    self.seriesArr.append(series)
                    
                }
                
                self.collectionView.reloadData()
                
            }
        }
    }
    
    //CollectionViews
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return seriesArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "serie", for: indexPath) as! SeriesCell
        
        
        cell.lblTitle.text = seriesArr[indexPath.item].title_english
        cell.id = seriesArr[indexPath.item].id
        cell.lblGenres.text = seriesArr[indexPath.item].genres
        let urlString = seriesArr[indexPath.item].image_url_med
        if (urlString == "") {
            cell.imgSeries.image = UIImage()
        } else {
            let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
            let url = URL(string: encoded!)
            cell.imgSeries.kf.setImage(with: url)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SeriesCell
        print(cell.id)
        id = cell.id
        performSegue(withIdentifier: "detail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! DetailViewController
        vc.id = id
    }
    
    @IBAction func search(_ sender: UIButton) {
        
        let searchWord = txtSearch.text
        
        if(searchWord?.isEmpty)!{
            let alert = UIAlertController(title: "Error", message: "You must provide a word in order to make a search", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            makeRequest(query: searchWord!)
        }
        
    }
    
    
    //Grid
    
    let margin: CGFloat = 10, cellsPerRow: CGFloat = 2
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let marginsAndInsets = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * (cellsPerRow - 1)
        let itemWidth = (collectionView.bounds.size.width - marginsAndInsets) / cellsPerRow
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass ||
            previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
