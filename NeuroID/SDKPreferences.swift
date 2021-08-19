//
//  APIPreferences.swift
//  NeuroID
//
//  Created by Clayton Selby on 8/19/21.
//

import Foundation

public class SDKPreferences {
    
    static func fetch() -> [[String:String]] {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {return []}

        let url = URL(fileURLWithPath: path)

        let data = try! Data(contentsOf: url)

        guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [[String:String]] else {return []}
        
        print(plist)
        return plist;
    }
}
