//
//  ViewController.swift
//  Applaudo
//
//  Created by Aldo on 29/08/17.
//  Copyright © 2017 Aldo. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import SystemConfiguration

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imgInternet: UIImageView!
    
    //var types = [Type]()
    var types = [String:[Series]]()
    var id = -1
    var reachability: Reachability? = Reachability.networkReachabilityForInternetConnection()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let reachability = Reachability(hostName: "www.apple.com")
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(_:)), name: NSNotification.Name(rawValue: ReachabilityDidChangeNotificationName), object: nil)
        
        _ = reachability?.startNotifier()
        
        
        
        //Web request
        let url = "\(Utilities.sharedInstance.URLPrefix)auth/access_token/"
        let parameters: Parameters = [
            "grant_type": "client_credentials",
            "client_id": "rojovivo27-duvvk",
            "client_secret": "RVz7qtODE3E1YYlHRoUFW"
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON { response in
            if let data = response.data {
                let json = JSON(data)
                
                Utilities.sharedInstance.access_token = json["access_token"].string ?? ""
                
                self.makeRequest(type: "anime")
            }
        }
        
        
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
        reachability?.stopNotifier()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkReachability()
    }
    
    func checkReachability() {
        guard let r = reachability else { return }
        if r.isReachable  {
            imgInternet.image = UIImage()
        } else {
            imgInternet.image = UIImage(named: "nointernet")
        }
    }
    
    func reachabilityDidChange(_ notification: Notification) {
        checkReachability()
    }
    
    
    func makeRequest(type: String){
        
        types = [String:[Series]]()
        
        //Web request
        let page = Int(arc4random_uniform(10) + 1)
        let urlSeries = "\(Utilities.sharedInstance.URLPrefix)browse/\(type)/"
        let parametersSeries: Parameters = [
            "access_token": Utilities.sharedInstance.access_token,
            "page": page
        ]
        
        Alamofire.request(urlSeries, method: .get, parameters: parametersSeries).responseJSON { response in
            if let data = response.data {
                let json = JSON(data)
                
                for index in 0 ..< json.count {
                    
                    let id = json[index,"id"].intValue
                    let title_english = json[index,"title_english"].string ?? ""
                    let type = json[index,"type"].string ?? ""
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
                    if var ser = self.types[type] {
                        ser.append(series)
                        
                        self.types.updateValue(ser, forKey: type)
                    } else {
                        self.types.updateValue([series], forKey: type)
                    }
                }
                
                self.tableView.reloadData()
                
            }
        }
    }
    
    //Switch
    @IBAction func refreshList(_ sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            makeRequest(type: "anime")
            Utilities.sharedInstance.type = "anime"
        } else {
            makeRequest(type: "manga")
            Utilities.sharedInstance.type = "manga"
        }
    }
    
    
    //TableViews
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "type") as! TypeCell
        let keys = Array(types.keys)
        cell.lblType.text = keys[indexPath.row]
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, index: (indexPath as NSIndexPath).row)
        return cell
    }
    
    //CollectionViews
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let keys = Array(types.keys)
        let key = keys[collectionView.tag]
        let total = types[key]?.count
        return total!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "serie", for: indexPath) as! SeriesCell
        
        let keys = Array(types.keys)
        let key = keys[collectionView.tag]
        let arr = types[key]
        
        cell.lblTitle.text = arr?[indexPath.item].title_english
        cell.id = (arr?[indexPath.item].id)!
        cell.lblGenres.text = arr?[indexPath.item].genres
        let urlString = arr?[indexPath.item].image_url_med
        if (urlString == "") {
            cell.imgSeries.image = UIImage()
        } else {
            let encoded = urlString?.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
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
    

}

class TypeCell: UITableViewCell {
    
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate delegate: UICollectionViewDelegate & UICollectionViewDataSource, index: NSInteger) {
        collectionView.dataSource = delegate
        collectionView.delegate = delegate
        collectionView.tag = index
        collectionView.reloadData()
    }
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate delegate: UICollectionViewDelegate & UICollectionViewDataSource, indexPath: IndexPath) {
        collectionView.dataSource = delegate
        collectionView.delegate = delegate
        //collectionView.indexPath = indexPath
        collectionView.tag = indexPath.section
        collectionView.reloadData()
    }
    
}

class SeriesCell: UICollectionViewCell{
    
    @IBOutlet weak var imgSeries: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblGenres: UILabel!
    
    var id = -1
    
}

class Type {
    var type: String = ""
    var series: [Series] = []
    
    init(type: String, series: [Series]){
        self.type = type
        self.series = series
    }
}

class Series {
    var id: Int = 0
    var title_english: String = ""
    var image_url_med: String = ""
    var genres: String = ""
    
    init(id: Int, title_english: String, image_url_med: String, genres: String){
        self.id = id
        self.title_english = title_english
        self.image_url_med = image_url_med
        self.genres = genres
    }
}



//Reachability
let ReachabilityDidChangeNotificationName = "ReachabilityDidChangeNotification"

enum ReachabilityStatus {
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
}

class Reachability: NSObject{
    
    private var networkReachability: SCNetworkReachability?
    
    init?(hostName: String) {
        networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, (hostName as NSString).utf8String!)
        super.init()
        if (networkReachability == nil) {
            return nil
        }
    }
    
    init?(hostAddress: sockaddr_in) {
        var address = hostAddress
        
        guard let defaultRouteReachability = withUnsafePointer(to: &address, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            return nil
        }
        
        networkReachability = defaultRouteReachability
        
        super.init()
        if networkReachability == nil {
            return nil
        }
    }
    
    
    static func networkReachabilityForInternetConnection() -> Reachability? {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        return Reachability(hostAddress: zeroAddress)
    }
    
    static func networkReachabilityForLocalWiFi() -> Reachability? {
        var localWifiAddress = sockaddr_in()
        localWifiAddress.sin_len = UInt8(MemoryLayout.size(ofValue: localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)
        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0 (0xA9FE0000).
        localWifiAddress.sin_addr.s_addr = 0xA9FE0000
        
        return Reachability(hostAddress: localWifiAddress)
    }
    
    private var notifying: Bool = false
    
    func startNotifier() -> Bool {
        
        guard notifying == false else {
            return false
        }
        
        var context = SCNetworkReachabilityContext()
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let reachability = networkReachability, SCNetworkReachabilitySetCallback(reachability, { (target: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            if let currentInfo = info {
                let infoObject = Unmanaged<AnyObject>.fromOpaque(currentInfo).takeUnretainedValue()
                if infoObject is Reachability {
                    let networkReachability = infoObject as! Reachability
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ReachabilityDidChangeNotificationName), object: networkReachability)
                }
            }
        }, &context) == true else { return false }
        
        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) == true else { return false }
        
        notifying = true
        return notifying
    }
    
    func stopNotifier() {
        if let reachability = networkReachability, notifying == true {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            notifying = false
        }
    }
    
    deinit {
        stopNotifier()
    }
 
    private var flags: SCNetworkReachabilityFlags {
        
        var flags = SCNetworkReachabilityFlags(rawValue: 0)
        
        if let reachability = networkReachability, withUnsafeMutablePointer(to: &flags, { SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0)) }) == true {
            return flags
        }
        else {
            return []
        }
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        } 
        else {
            return .notReachable
        }
    }
    
    var isReachable: Bool {
        switch currentReachabilityStatus {
        case .notReachable:
            return false
        case .reachableViaWiFi, .reachableViaWWAN:
            return true
        }
    }
    
}
