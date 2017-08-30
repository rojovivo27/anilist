//
//  Utilities.swift
//  Applaudo
//
//  Created by Aldo on 29/08/17.
//  Copyright © 2017 Aldo. All rights reserved.
//

import Foundation

class Utilities  {
    static let sharedInstance = Utilities()
    
    let URLPrefix = "https://anilist.co/api/"
    var access_token = ""
    var type = "anime"
    
    init(){
    }
}
