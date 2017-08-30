//
//  DetailViewController.swift
//  Applaudo
//
//  Created by Aldo on 30/08/17.
//  Copyright © 2017 Aldo. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import YouTubePlayer

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var lblEnglish: UILabel!
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var lblRomanji: UILabel!
    @IBOutlet weak var lblOriginal: UILabel!
    @IBOutlet weak var txtDescription: UITextView!
    @IBOutlet weak var imgPortrait: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblScore: UILabel!
    @IBOutlet weak var lblEpisodes: UILabel!
    @IBOutlet weak var lblStartDate: UILabel!
    @IBOutlet weak var lblEndDate: UILabel!
    @IBOutlet weak var imgBanner: UIImageView!
    
    var id = -1
    var youtubeID = ""
    
    var characters = [SeriesCharacter]()
    
    var bgVideo = UIView()
    var videoLayer: YouTubePlayerView = YouTubePlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Web request
        let urlSeries = "\(Utilities.sharedInstance.URLPrefix)\(Utilities.sharedInstance.type)/\(id)/characters/"
        let parametersSeries: Parameters = [
            "access_token": Utilities.sharedInstance.access_token
        ]
        
        Alamofire.request(urlSeries, method: .get, parameters: parametersSeries).responseJSON { response in
            if let data = response.data {
                let json = JSON(data)
                
                if(json["error"] != JSON.null){
                    let alert = UIAlertController(title: "No results", message: "Try later", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                let title_english = json["title_english"].string ?? ""
                let title_romaji = json["title_romaji"].string ?? ""
                let title_japanese = json["title_japanese"].string ?? ""
                let type = json["type"].string ?? ""
                let image_url_lge = json["image_url_lge"].string ?? ""
                let seriesDescription = json["description"].string ?? ""
                let average_score = json["average_score"].intValue
                let total_episodes = json["total_episodes"].intValue
                let start_date = json["start_date"].string ?? ""
                let end_date = json["end_date"].string ?? ""
                let youtube_id = json["youtube_id"].string ?? ""
                let image_url_banner = json["image_url_banner"].string ?? ""
                
                let charactersList = JSON(json["characters"].arrayValue)
                for index in 0 ..< charactersList.count {
                    
                    let name_first = charactersList[index,"name_first"].string ?? ""
                    let name_last = charactersList[index,"name_last"].string ?? ""
                    let image_url_med = charactersList[index,"image_url_med"].string ?? ""
                    
                    self.characters.append(SeriesCharacter(name: name_first, lastName: name_last, urlImg: image_url_med))
                    
                }
                
                //Set UI
                self.lblEnglish.text = title_english
                self.lblRomanji.text = title_romaji
                self.lblOriginal.text = title_japanese
                self.lblType.text = type
                self.txtDescription.text = seriesDescription
                let urlStringPortrait = image_url_lge
                if (urlStringPortrait == "") {
                    self.imgPortrait.image = UIImage()
                } else {
                    let encoded = urlStringPortrait.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                    let url = URL(string: encoded!)
                    self.imgPortrait.kf.setImage(with: url)
                }
                self.lblScore.text = "Score: \(average_score)"
                self.lblEpisodes.text = "Total Episodes: \(total_episodes)"
                
                var index = start_date.index(start_date.startIndex, offsetBy: 10)
                let start = start_date.substring(to: index)
                self.lblStartDate.text = "Start: \(start)"
                if(end_date.isEmpty){
                    self.lblEndDate.text = "Not finished yet"
                } else {
                    index = end_date.index(end_date.startIndex, offsetBy: 10)
                    let end = end_date.substring(to: index)
                    self.lblEndDate.text = "End: \(end)"
                }
                
                self.youtubeID = youtube_id
                
                let urlStringBanner = image_url_banner
                if (urlStringBanner == "") {
                    self.imgBanner.image = UIImage()
                } else {
                    let encoded = urlStringBanner.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                    let url = URL(string: encoded!)
                    self.imgBanner.kf.setImage(with: url)
                }
                
                self.tableView.reloadData()
                
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 0
        if characters.count > 0
        {
            numOfSections = 1
            tableView.backgroundView = nil
        }
        else
        {
            let noDataLabel: InsetLabel = InsetLabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "Ooops, there are no characters in the database"
            noDataLabel.textColor = UIColor.black
            noDataLabel.numberOfLines = 4
            noDataLabel.adjustsFontSizeToFitWidth = true
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
        }
        return numOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return characters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "character") as! CharacterCell
        cell.lblName.text = "\(characters[indexPath.row].name) \(characters[indexPath.row].lastName)"
        let urlString = characters[indexPath.row].urlImg
        if (urlString == "") {
            cell.imgCharacter.image = UIImage()
        } else {
            let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
            let url = URL(string: encoded!)
            cell.imgCharacter.kf.setImage(with: url)
        }
        return cell
    }
    
    
    @IBAction func playVideo(_ sender: UIButton) {
        
        if(youtubeID.isEmpty){
            let alert = UIAlertController(title: "Sorry", message: "This element has no video", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            //view for video
            bgVideo = UIView(frame: view.frame)
            bgVideo.backgroundColor = UIColor.black
            bgVideo.alpha = 0.9
            videoLayer = YouTubePlayerView(frame: CGRect(x: 0, y: view.frame.height/2 - 150, width: view.frame.width, height: 300))
            videoLayer.loadVideoID(youtubeID)
            //Looks for single or multiple taps.
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeVideo))
            
            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            tap.cancelsTouchesInView = false
            
            bgVideo.addGestureRecognizer(tap)
            view.addSubview(bgVideo)
            view.addSubview(videoLayer)
        }
    }
    
    func closeVideo(){
        videoLayer.removeFromSuperview()
        bgVideo.removeFromSuperview()
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

class SeriesCharacter {
    var name = ""
    var lastName = ""
    var urlImg = ""
    
    init(name: String, lastName: String, urlImg: String){
        self.name = name
        self.lastName = lastName
        self.urlImg = urlImg
    }
    
}

class CharacterCell: UITableViewCell {
    
    @IBOutlet weak var imgCharacter: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    
}

class InsetLabel: UILabel {
    let topInset = CGFloat(0)
    let bottomInset = CGFloat(0)
    let leftInset = CGFloat(8)
    let rightInset = CGFloat(8)
    
    override func drawText(in rect: CGRect) {
        let insets: UIEdgeInsets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override public var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
}
