//
//  JsonConverter.swift
//  Isaacs
//
//  Created by Sebastian Florez on 9/17/16.
//  Copyright © 2016 Inspect. All rights reserved.
//

import Foundation

public class JsonConverter{
    static func dictToJson(dict : [String:String]) -> String{
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            return String(data: jsonData, encoding: NSUTF8StringEncoding)!
        } catch let error as NSError {
            print(error)
        }
        return "{}"
    }
    
    static func jsonToDict(json : String) -> [String:String]?{
        if let data = json.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:String]
            } catch let error as NSError {
                print(error)
            }
        }
        return [:]
    }

}
