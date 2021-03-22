//
//  User.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 20/03/21.
//

import Foundation


struct User: Decodable {
    let login:String
    let id:Int
    let avatar_url:String
}
